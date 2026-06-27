import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/bloc/health/health_bloc.dart';
import 'package:fitnesbuster/domain/services/i_health_analytics_service.dart';

import 'health_bloc_test.mocks.dart';

@GenerateMocks([Health, IHealthAnalyticsService])
void main() {
  late MockHealth mockHealth;
  late MockIHealthAnalyticsService mockAnalytics;
  late HealthBloc bloc;

  setUp(() {
    mockHealth = MockHealth();
    mockAnalytics = MockIHealthAnalyticsService();
    bloc = HealthBloc(health: mockHealth, analytics: mockAnalytics);
  });

  tearDown(() => bloc.close());

  test('initial state is HealthStateInitial', () {
    expect(bloc.state, const HealthStateInitial());
  });

  group('HealthFetchRequested', () {
    blocTest<HealthBloc, HealthState>(
      'emits error when health access denied',
      build: () {
        when(mockHealth.requestAuthorization(any))
            .thenAnswer((_) async => false);
        return HealthBloc(health: mockHealth, analytics: mockAnalytics);
      },
      act: (b) => b.add(const HealthFetchRequested()),
      expect: () => [
        const HealthStateLoading(),
        isA<HealthStateError>(),
      ],
    );

    blocTest<HealthBloc, HealthState>(
      'emits loaded when health data fetched successfully',
      build: () {
        when(mockHealth.requestAuthorization(any))
            .thenAnswer((_) async => true);
        when(mockHealth.getHealthDataFromTypes(
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          types: anyNamed('types'),
        )).thenAnswer((_) async => []);
        when(mockAnalytics.sumValue(any, HealthDataType.STEPS))
            .thenReturn(5000.0);
        when(mockAnalytics.sumValue(any, HealthDataType.ACTIVE_ENERGY_BURNED))
            .thenReturn(300.0);
        when(mockAnalytics.avgValue(any, HealthDataType.HEART_RATE))
            .thenReturn(70.0);
        when(mockAnalytics.lastValue(any, HealthDataType.WEIGHT))
            .thenReturn(75.0);
        when(mockAnalytics.sumSleepMinutes(any)).thenReturn(420);
        when(mockAnalytics.sumValue(any, HealthDataType.WATER))
            .thenReturn(2.0);
        when(mockAnalytics.sumValue(any, HealthDataType.DISTANCE_DELTA))
            .thenReturn(3.5);
        return HealthBloc(health: mockHealth, analytics: mockAnalytics);
      },
      act: (b) => b.add(const HealthFetchRequested()),
      expect: () => [
        const HealthStateLoading(),
        isA<HealthStateLoaded>()
            .having((s) => s.steps, 'steps', 5000)
            .having((s) => s.caloriesBurned, 'calories', 300.0)
            .having((s) => s.heartRate, 'heartRate', 70)
            .having((s) => s.weight, 'weight', 75.0)
            .having((s) => s.sleepMinutes, 'sleepMinutes', 420)
            .having((s) => s.waterIntakeMl, 'waterIntakeMl', 2000.0)
            .having((s) => s.distanceKm, 'distanceKm', 3.5),
      ],
    );

    blocTest<HealthBloc, HealthState>(
      'emits loaded with null heartRate when analytics returns null',
      build: () {
        when(mockHealth.requestAuthorization(any))
            .thenAnswer((_) async => true);
        when(mockHealth.getHealthDataFromTypes(
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          types: anyNamed('types'),
        )).thenAnswer((_) async => []);
        when(mockAnalytics.sumValue(any, HealthDataType.STEPS))
            .thenReturn(null);
        when(mockAnalytics.sumValue(any, HealthDataType.ACTIVE_ENERGY_BURNED))
            .thenReturn(null);
        when(mockAnalytics.avgValue(any, HealthDataType.HEART_RATE))
            .thenReturn(null);
        when(mockAnalytics.lastValue(any, HealthDataType.WEIGHT))
            .thenReturn(null);
        when(mockAnalytics.sumSleepMinutes(any)).thenReturn(0);
        when(mockAnalytics.sumValue(any, HealthDataType.WATER))
            .thenReturn(null);
        when(mockAnalytics.sumValue(any, HealthDataType.DISTANCE_DELTA))
            .thenReturn(null);
        return HealthBloc(health: mockHealth, analytics: mockAnalytics);
      },
      act: (b) => b.add(const HealthFetchRequested()),
      expect: () => [
        const HealthStateLoading(),
        isA<HealthStateLoaded>()
            .having((s) => s.steps, 'steps', 0)
            .having((s) => s.heartRate, 'heartRate', isNull),
      ],
    );

    blocTest<HealthBloc, HealthState>(
      'emits error when health throws exception',
      build: () {
        when(mockHealth.requestAuthorization(any))
            .thenAnswer((_) async => true);
        when(mockHealth.getHealthDataFromTypes(
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          types: anyNamed('types'),
        )).thenThrow(Exception('Health API error'));
        return HealthBloc(health: mockHealth, analytics: mockAnalytics);
      },
      act: (b) => b.add(const HealthFetchRequested()),
      expect: () => [
        const HealthStateLoading(),
        isA<HealthStateError>(),
      ],
    );
  });

  group('HealthWatchRequested', () {
    blocTest<HealthBloc, HealthState>(
      'emits error when watch permissions denied',
      build: () {
        when(mockHealth.requestAuthorization(any))
            .thenAnswer((_) async => false);
        return HealthBloc(health: mockHealth, analytics: mockAnalytics);
      },
      act: (b) => b.add(const HealthWatchRequested()),
      expect: () => [
        isA<HealthStateError>(),
      ],
    );

    blocTest<HealthBloc, HealthState>(
      'emits error when watch throws exception',
      build: () {
        when(mockHealth.requestAuthorization(any))
            .thenAnswer((_) async => true);
        when(mockHealth.getHealthDataFromTypes(
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          types: anyNamed('types'),
        )).thenThrow(Exception('Watch error'));
        return HealthBloc(health: mockHealth, analytics: mockAnalytics);
      },
      act: (b) => b.add(const HealthWatchRequested()),
      expect: () => [
        isA<HealthStateError>(),
      ],
    );

    blocTest<HealthBloc, HealthState>(
      'does not trigger fetch when watch returns no step data',
      build: () {
        when(mockHealth.requestAuthorization(any))
            .thenAnswer((_) async => true);
        when(mockHealth.getHealthDataFromTypes(
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          types: anyNamed('types'),
        )).thenAnswer((_) async => []);
        return HealthBloc(health: mockHealth, analytics: mockAnalytics);
      },
      act: (b) => b.add(const HealthWatchRequested()),
      expect: () => [],
    );
  });
}
