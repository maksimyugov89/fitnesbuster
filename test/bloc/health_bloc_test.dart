import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/bloc/health/health_bloc.dart';
import 'package:fitnesbuster/domain/services/i_health_service.dart';
import 'package:fitnesbuster/domain/services/i_health_analytics_service.dart';

import 'health_bloc_test.mocks.dart';

@GenerateMocks([IHealthService, IHealthAnalyticsService])
void main() {
  late MockIHealthService mockHealthService;
  late MockIHealthAnalyticsService mockAnalytics;
  late HealthBloc bloc;

  setUp(() {
    mockHealthService = MockIHealthService();
    mockAnalytics = MockIHealthAnalyticsService();
    bloc = HealthBloc(healthService: mockHealthService, analytics: mockAnalytics);
  });

  tearDown(() => bloc.close());

  test('initial state is HealthStateInitial', () {
    expect(bloc.state, const HealthStateInitial());
  });

  group('HealthFetchRequested', () {
    blocTest<HealthBloc, HealthState>(
      'emits error when permissions denied',
      build: () => HealthBloc(healthService: mockHealthService, analytics: mockAnalytics),
      act: (b) {
        when(mockHealthService.requestAuthorization(any))
            .thenAnswer((_) async => false);
        b.add(const HealthFetchRequested());
      },
      expect: () => [const HealthStateLoading(), isA<HealthStateError>()],
    );

    blocTest<HealthBloc, HealthState>(
      'emits loaded when fetch succeeds',
      build: () => HealthBloc(healthService: mockHealthService, analytics: mockAnalytics),
      act: (b) {
        when(mockHealthService.requestAuthorization(any))
            .thenAnswer((_) async => true);
        when(mockHealthService.getHealthDataFromTypes(
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          types: anyNamed('types'),
        )).thenAnswer((_) async => []);
        when(mockAnalytics.sumValue(any, any)).thenReturn(1000);
        when(mockAnalytics.avgValue(any, any)).thenReturn(72);
        when(mockAnalytics.lastValue(any, any)).thenReturn(80.5);
        when(mockAnalytics.sumSleepMinutes(any)).thenReturn(420);
        b.add(const HealthFetchRequested());
      },
      expect: () => [const HealthStateLoading(), isA<HealthStateLoaded>()],
    );
  });
}
