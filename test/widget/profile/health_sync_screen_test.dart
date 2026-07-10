import 'package:fitnesbuster/bloc/health/health_sync_bloc.dart';
import 'package:fitnesbuster/domain/entities/synced_health_data.dart';
import 'package:fitnesbuster/presentation/screens/profile/health_sync_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'health_sync_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<HealthSyncBloc>()])
void main() {
  late MockHealthSyncBloc mockBloc;

  setUpAll(() {
    provideDummy<HealthSyncState>(const HealthSyncStateInitial());
  });

  setUp(() {
    mockBloc = MockHealthSyncBloc();
    when(
      mockBloc.stream,
    ).thenAnswer((_) => const Stream<HealthSyncState>.empty());
  });

  Future<void> pumpScreen(WidgetTester tester, HealthSyncState state) async {
    when(mockBloc.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(home: HealthSyncScreen(bloc: mockBloc)),
    );
    await tester.pump();
  }

  testWidgets('shows loading indicator during sync', (tester) async {
    await pumpScreen(tester, const HealthSyncStateLoading());
    expect(find.byType(CircularProgressIndicator), findsOne);
  });

  testWidgets('renders synchronized health metrics', (tester) async {
    await pumpScreen(
      tester,
      HealthSyncStateLoaded(
        data: SyncedHealthData(
          steps: 6543,
          caloriesBurned: 420,
          heartRateAvg: 68,
          sleepMinutes: 450,
          weight: 78.5,
          waterIntakeMl: 1800,
          distanceKm: 5.2,
        ),
        lastSyncAt: DateTime.now(),
      ),
    );

    expect(find.text('6543'), findsOne);
    expect(find.text('420'), findsOne);
    expect(find.text('68'), findsOne);
    expect(find.text('78.5'), findsOne);
    expect(find.text('7ч 30м'), findsOne);
    expect(find.text('5.2'), findsOne);
  });

  testWidgets('renders install action when Health Connect is unavailable', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const HealthSyncStateError(message: 'Health Connect не установлен'),
    );

    expect(find.text('Health Connect не установлен'), findsOne);
    expect(find.text('Установить Health Connect'), findsOne);
  });

  testWidgets('does not close an injected bloc when screen is disposed', (
    tester,
  ) async {
    await pumpScreen(tester, const HealthSyncStateInitial());
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    verifyNever(mockBloc.close());
  });
}
