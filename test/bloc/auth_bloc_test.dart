import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/core/legal/legal_consent.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/exceptions/auth_exception.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';

import 'auth_bloc_test.mocks.dart';

@GenerateMocks([IAuthRepository])
void main() {
  late MockIAuthRepository repo;
  late AuthBloc bloc;

  final tUser = UserEntity(
    id: 'uid-1',
    name: 'Test User',
    email: 'test@example.com',
    createdAt: DateTime(2024),
  );
  const tConsent = LegalConsentAcceptance(
    source: LegalConsentSource.emailRegistration,
    localeCode: 'ru',
  );

  setUp(() {
    repo = MockIAuthRepository();
    when(repo.userChanges).thenAnswer((_) => const Stream.empty());
    when(repo.currentUser).thenReturn(null);
    when(repo.isEmailVerified).thenReturn(true);
    when(repo.hasCurrentLegalConsent()).thenAnswer((_) async => true);
    when(repo.getCurrentUserWithProfile()).thenAnswer((_) async => null);
    when(repo.reloadUser()).thenAnswer((_) async {});
    when(repo.signOut()).thenAnswer((_) async {});
    when(
      repo.acceptCurrentLegalConsent(consent: anyNamed('consent')),
    ).thenAnswer((_) async => tUser);
    bloc = AuthBloc(authRepository: repo);
  });

  tearDown(() => bloc.close());

  test('initial state is AuthStateInitial', () {
    expect(bloc.state, const AuthStateInitial());
  });

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits Authenticated when user exists',
      build: () {
        when(repo.currentUser).thenReturn(tUser);
        when(repo.userChanges).thenAnswer((_) => const Stream.empty());
        when(repo.hasCurrentLegalConsent()).thenAnswer((_) async => true);
        when(repo.getCurrentUserWithProfile()).thenAnswer((_) async => tUser);
        return AuthBloc(authRepository: repo);
      },
      act: (b) => b.add(const AuthCheckRequested()),
      expect: () => [AuthStateAuthenticated(user: tUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits LegalConsentRequired when cached user lacks current consent',
      build: () {
        when(repo.currentUser).thenReturn(tUser);
        when(repo.userChanges).thenAnswer((_) => const Stream.empty());
        when(repo.hasCurrentLegalConsent()).thenAnswer((_) async => false);
        return AuthBloc(authRepository: repo);
      },
      act: (b) => b.add(const AuthCheckRequested()),
      expect: () => [const AuthStateLegalConsentRequired()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits Unauthenticated when no user',
      build: () {
        when(repo.currentUser).thenReturn(null);
        when(repo.userChanges).thenAnswer((_) => const Stream.empty());
        return AuthBloc(authRepository: repo);
      },
      act: (b) => b.add(const AuthCheckRequested()),
      expect: () => [const AuthStateUnauthenticated()],
    );
  });

  group('AuthLoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits Loading then Authenticated on success',
      build: () => AuthBloc(authRepository: repo),
      setUp: () {
        when(
          repo.login(email: 'test@example.com', password: '123456'),
        ).thenAnswer((_) async => tUser);
      },
      act: (b) => b.add(
        const AuthLoginRequested(email: 'test@example.com', password: '123456'),
      ),
      expect: () => [
        const AuthStateLoading(),
        AuthStateAuthenticated(user: tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits Loading then Error on wrong-password',
      build: () => AuthBloc(authRepository: repo),
      setUp: () {
        when(
          repo.login(email: anyNamed('email'), password: anyNamed('password')),
        ).thenThrow(const WrongPasswordException());
      },
      act: (b) =>
          b.add(const AuthLoginRequested(email: 'a@b.com', password: 'wrong')),
      expect: () => [
        const AuthStateLoading(),
        const AuthStateError(message: 'Неверный пароль'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits Loading then Error on generic exception',
      build: () => AuthBloc(authRepository: repo),
      setUp: () {
        when(
          repo.login(email: anyNamed('email'), password: anyNamed('password')),
        ).thenThrow(Exception('network'));
      },
      act: (b) =>
          b.add(const AuthLoginRequested(email: 'a@b.com', password: 'pass')),
      expect: () => [
        const AuthStateLoading(),
        const AuthStateError(message: 'Произошла ошибка. Попробуйте снова.'),
      ],
    );
  });

  group('AuthRegisterRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits Loading then Authenticated on success',
      build: () => AuthBloc(authRepository: repo),
      setUp: () {
        when(
          repo.register(
            name: anyNamed('name'),
            email: anyNamed('email'),
            password: anyNamed('password'),
            consent: anyNamed('consent'),
          ),
        ).thenAnswer((_) async => tUser);
      },
      act: (b) => b.add(
        const AuthRegisterRequested(
          name: 'Test',
          email: 'test@example.com',
          password: '123456',
          consent: tConsent,
        ),
      ),
      expect: () => [
        const AuthStateLoading(),
        AuthStateAuthenticated(user: tUser),
      ],
    );
  });

  group('AuthGoogleLoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits LegalConsentRequired for existing Google user without current consent',
      build: () => AuthBloc(authRepository: repo),
      setUp: () {
        when(repo.currentUser).thenReturn(tUser);
        when(
          repo.signInWithGoogle(newAccountConsent: null),
        ).thenThrow(const UnknownAuthException('terms-required'));
      },
      act: (b) => b.add(const AuthGoogleLoginRequested()),
      expect: () => [
        const AuthStateLoading(),
        const AuthStateLegalConsentRequired(
          source: LegalConsentSource.googleLogin,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits LegalConsentRequired for existing email user without current consent',
      build: () => AuthBloc(authRepository: repo),
      setUp: () {
        when(repo.currentUser).thenReturn(tUser);
        when(
          repo.login(email: anyNamed('email'), password: anyNamed('password')),
        ).thenThrow(const UnknownAuthException('terms-required'));
      },
      act: (b) =>
          b.add(const AuthLoginRequested(email: 'a@b.com', password: 'pass')),
      expect: () => [
        const AuthStateLoading(),
        const AuthStateLegalConsentRequired(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'records accepted legacy Google consent and authenticates',
      build: () => AuthBloc(authRepository: repo),
      setUp: () {
        when(
          repo.acceptCurrentLegalConsent(consent: anyNamed('consent')),
        ).thenAnswer((_) async => tUser);
      },
      act: (b) => b.add(
        const AuthLegalConsentAccepted(
          consent: LegalConsentAcceptance(
            source: LegalConsentSource.googleLogin,
            localeCode: 'ru',
          ),
        ),
      ),
      expect: () => [
        const AuthStateLoading(),
        AuthStateAuthenticated(user: tUser),
      ],
      verify: (_) {
        final captured =
            verify(
                  repo.acceptCurrentLegalConsent(
                    consent: captureAnyNamed('consent'),
                  ),
                ).captured.single
                as LegalConsentAcceptance;
        expect(captured.source, LegalConsentSource.googleLogin);
        expect(captured.localeCode, 'ru');
      },
    );
  });

  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits Unauthenticated after logout',
      build: () => AuthBloc(authRepository: repo),
      setUp: () {
        when(repo.logout()).thenAnswer((_) async {});
      },
      act: (b) => b.add(const AuthLogoutRequested()),
      expect: () => [const AuthStateUnauthenticated()],
    );
  });
}
