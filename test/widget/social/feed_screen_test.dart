import 'dart:async';

import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/services/i_social_service.dart';
import 'package:fitnesbuster/core/services/social_models.dart';
import 'package:fitnesbuster/presentation/screens/social/feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'feed_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ISocialService>()])
void main() {
  late MockISocialService mockSocial;

  setUpAll(() async {
    await initializeDateFormatting('ru_RU');
  });

  setUp(() {
    mockSocial = MockISocialService();
    if (sl.isRegistered<ISocialService>()) {
      sl.unregister<ISocialService>();
    }
    sl.registerSingleton<ISocialService>(mockSocial);
  });

  tearDown(() {
    if (sl.isRegistered<ISocialService>()) {
      sl.unregister<ISocialService>();
    }
  });

  testWidgets('shows empty state when feed is empty', (tester) async {
    when(mockSocial.feedStream()).thenAnswer((_) => Stream.value(const []));

    await tester.pumpWidget(const MaterialApp(home: FeedScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Лента пуста'), findsOne);
  });

  testWidgets('renders feed events as cards', (tester) async {
    final controller = StreamController<List<FeedEvent>>();
    when(mockSocial.feedStream()).thenAnswer((_) => controller.stream);

    await tester.pumpWidget(const MaterialApp(home: FeedScreen()));
    await tester.pump();

    controller.add([
      FeedEvent(
        id: 'e1',
        type: 'workout_done',
        fromUid: 'u1',
        fromName: 'Alice',
        data: {'durationMinutes': 30},
        timestamp: DateTime(2025, 7, 1, 10, 30),
      ),
    ]);
    await tester.pumpAndSettle();

    // When FeedEvent cards render, we should see a ListView
    // (not the empty-state layout)
    expect(find.byType(ListView), findsOne);

    await controller.close();
  });
}
