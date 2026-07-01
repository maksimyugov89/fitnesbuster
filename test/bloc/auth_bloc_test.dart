import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
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

  setUp(() {
    repo = MockIAuthRepository();
    when(repo.userChanges).thenAnswer((_) => const Stream.empty());
    when(repo.currentUser).thenReturn(null);
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
        return AuthBloc(authRepository: repo);
      },
      act: (b) => b.add(const AuthCheckRequested()),
      expect: () => [AuthStateAuthenticated(user: tUser)],
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
          ),
        ).thenAnswer((_) async => tUser);
      },
      act: (b) => b.add(
        const AuthRegisterRequested(
          name: 'Test',
          email: 'test@example.com',
          password: '123456',
        ),
      ),
      expect: () => [
        const AuthStateLoading(),
        AuthStateAuthenticated(user: tUser),
      ],
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
