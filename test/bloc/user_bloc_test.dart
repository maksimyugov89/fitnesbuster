import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/bloc/user/user_bloc.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';

import 'user_bloc_test.mocks.dart';

@GenerateMocks([IUserRepository])
void main() {
  late MockIUserRepository repo;
  late UserBloc bloc;

  final tUser = UserEntity(
    id: 'uid-1',
    name: 'Test User',
    email: 'test@example.com',
    createdAt: DateTime(2024),
  );

  setUp(() {
    repo = MockIUserRepository();
    bloc = UserBloc(userRepository: repo);
  });

  tearDown(() => bloc.close());

  test('initial state is UserStateUnknown', () {
    expect(bloc.state, const UserStateUnknown());
  });

  group('UserLoadRequested', () {
    blocTest<UserBloc, UserState>(
      'emits Loading then Loaded on success',
      build: () => UserBloc(userRepository: repo),
      setUp: () {
        when(repo.getUser('uid-1')).thenAnswer((_) async => tUser);
      },
      act: (b) => b.add(const UserLoadRequested(userId: 'uid-1')),
      expect: () => [
        const UserStateLoading(),
        UserStateLoaded(user: tUser),
      ],
    );

    blocTest<UserBloc, UserState>(
      'emits Loading then Error on failure',
      build: () => UserBloc(userRepository: repo),
      setUp: () {
        when(repo.getUser(any)).thenThrow(Exception('network error'));
      },
      act: (b) => b.add(const UserLoadRequested(userId: 'uid-1')),
      expect: () => [
        const UserStateLoading(),
        const UserStateError(
          message: 'Не удалось загрузить профиль. Попробуйте снова.',
        ),
      ],
    );
  });

  group('UserUpdateProfile', () {
    blocTest<UserBloc, UserState>(
      'emits updated Loaded when in Loaded state',
      build: () => UserBloc(userRepository: repo),
      seed: () => UserStateLoaded(user: tUser),
      setUp: () {
        final updated = tUser.copyWith(name: 'New Name');
        when(repo.updateProfile(any)).thenAnswer((_) async => updated);
      },
      act: (b) => b.add(
        const UserUpdateProfile(name: 'New Name', email: 'test@example.com'),
      ),
      expect: () => [
        isA<UserStateLoaded>()
            .having((s) => s.user.name, 'name', 'New Name'),
      ],
    );

    blocTest<UserBloc, UserState>(
      'does nothing when not in Loaded state',
      build: () => UserBloc(userRepository: repo),
      act: (b) => b.add(
        const UserUpdateProfile(name: 'Name', email: 'e@e.com'),
      ),
      expect: () => [],
    );

    blocTest<UserBloc, UserState>(
      'emits Error when update fails',
      build: () => UserBloc(userRepository: repo),
      seed: () => UserStateLoaded(user: tUser),
      setUp: () {
        when(repo.updateProfile(any)).thenThrow(Exception('fail'));
      },
      act: (b) => b.add(
        const UserUpdateProfile(name: 'Name', email: 'e@e.com'),
      ),
      expect: () => [
        const UserStateError(
          message: 'Не удалось сохранить профиль. Попробуйте снова.',
        ),
      ],
    );
  });
}
