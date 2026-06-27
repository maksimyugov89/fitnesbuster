import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/bloc/health/health_sync_bloc.dart';
import 'package:fitnesbuster/core/health/health_connect_service.dart';

import 'health_sync_bloc_test.mocks.dart';

@GenerateMocks([HealthConnectService])
void main() {
  late MockHealthConnectService mockHc;
  late HealthSyncBloc bloc;

  setUp(() {
    mockHc = MockHealthConnectService();
    bloc = HealthSyncBloc(hcService: mockHc);
  });

  tearDown(() => bloc.close());

  test('initial state is HealthSyncStateInitial', () {
    expect(bloc.state, const HealthSyncStateInitial());
  });

  group('HealthSyncInitializeRequested', () {
    blocTest<HealthSyncBloc, HealthSyncState>(
      'emits Loading then Loaded when initialized successfully',
      build: () {
        when(mockHc.initialize()).thenAnswer((_) async => true);
        when(mockHc.readAllToday()).thenAnswer(
          (_) async => SyncedHealthData(),
        );
        return HealthSyncBloc(hcService: mockHc);
      },
      act: (b) => b.add(const HealthSyncInitializeRequested()),
      expect: () => [
        const HealthSyncStateLoading(),
        isA<HealthSyncStateLoaded>(),
      ],
    );

    blocTest<HealthSyncBloc, HealthSyncState>(
      'emits error when Health Connect not installed',
      build: () {
        when(mockHc.initialize()).thenAnswer((_) async => false);
        when(mockHc.isHealthConnectAvailable()).thenAnswer((_) async => false);
        return HealthSyncBloc(hcService: mockHc);
      },
      act: (b) => b.add(const HealthSyncInitializeRequested()),
      expect: () => [
        const HealthSyncStateLoading(),
        isA<HealthSyncStateError>(),
      ],
    );

    blocTest<HealthSyncBloc, HealthSyncState>(
      'emits error when access denied',
      build: () {
        when(mockHc.initialize()).thenAnswer((_) async => false);
        when(mockHc.isHealthConnectAvailable()).thenAnswer((_) async => true);
        return HealthSyncBloc(hcService: mockHc);
      },
      act: (b) => b.add(const HealthSyncInitializeRequested()),
      expect: () => [
        const HealthSyncStateLoading(),
        isA<HealthSyncStateError>(),
      ],
    );

    blocTest<HealthSyncBloc, HealthSyncState>(
      'emits error when initialization throws',
      build: () {
        when(mockHc.initialize()).thenThrow(Exception('Init error'));
        return HealthSyncBloc(hcService: mockHc);
      },
      act: (b) => b.add(const HealthSyncInitializeRequested()),
      expect: () => [
        const HealthSyncStateLoading(),
        isA<HealthSyncStateError>(),
      ],
    );
  });

  group('HealthSyncReadToday', () {
    blocTest<HealthSyncBloc, HealthSyncState>(
      'emits Loading then Loaded with health data',
      build: () {
        when(mockHc.readAllToday()).thenAnswer(
          (_) async => SyncedHealthData(
            steps: 8000,
            caloriesBurned: 400,
            heartRateAvg: 72,
            sleepMinutes: 420,
          ),
        );
        return HealthSyncBloc(hcService: mockHc);
      },
      act: (b) => b.add(const HealthSyncReadToday()),
      expect: () => [
        const HealthSyncStateLoading(),
        isA<HealthSyncStateLoaded>()
            .having((s) => s.data.steps, 'steps', 8000)
            .having((s) => s.data.caloriesBurned, 'calories', 400.0)
            .having((s) => s.data.heartRateAvg, 'heartRateAvg', 72),
      ],
    );

    blocTest<HealthSyncBloc, HealthSyncState>(
      'emits error when read throws',
      build: () {
        when(mockHc.readAllToday()).thenThrow(Exception('Read error'));
        return HealthSyncBloc(hcService: mockHc);
      },
      act: (b) => b.add(const HealthSyncReadToday()),
      expect: () => [
        const HealthSyncStateLoading(),
        isA<HealthSyncStateError>(),
      ],
    );
  });

  group('HealthSyncReadDateRange', () {
    blocTest<HealthSyncBloc, HealthSyncState>(
      'emits Loading then Loaded for date range',
      build: () {
        when(mockHc.readDateRange(
          start: anyNamed('start'),
          end: anyNamed('end'),
        )).thenAnswer((_) async => SyncedHealthData(steps: 10000));
        return HealthSyncBloc(hcService: mockHc);
      },
      act: (b) => b.add(HealthSyncReadDateRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 7),
      )),
      expect: () => [
        const HealthSyncStateLoading(),
        isA<HealthSyncStateLoaded>()
            .having((s) => s.data.steps, 'steps', 10000),
      ],
    );

    blocTest<HealthSyncBloc, HealthSyncState>(
      'emits error when date range read throws',
      build: () {
        when(mockHc.readDateRange(
          start: anyNamed('start'),
          end: anyNamed('end'),
        )).thenThrow(Exception('Range error'));
        return HealthSyncBloc(hcService: mockHc);
      },
      act: (b) => b.add(HealthSyncReadDateRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 7),
      )),
      expect: () => [
        const HealthSyncStateLoading(),
        isA<HealthSyncStateError>(),
      ],
    );
  });
}
