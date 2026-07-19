import 'dart:async';

import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/services/i_social_service.dart';
import 'package:fitnesbuster/core/services/social_models.dart';
import 'package:fitnesbuster/presentation/screens/social/friends_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'friends_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ISocialService>()])
void main() {
  late MockISocialService mockSocial;

  setUpAll(() {
    initializeDateFormatting('ru');
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

  testWidgets('shows empty state when friend list is empty', (tester) async {
    when(mockSocial.friendsStream()).thenAnswer((_) => Stream.value(const []));
    when(
      mockSocial.incomingRequestsStream(),
    ).thenAnswer((_) => Stream.value(const []));

    await tester.pumpWidget(const MaterialApp(home: FriendsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Друзья'), findsOne);
  });

  testWidgets('renders friends in the list', (tester) async {
    final friends = [
      FriendUser(uid: 'u2', name: 'Alice', addedAt: DateTime(2025, 7, 1)),
      FriendUser(uid: 'u3', name: 'Bob', addedAt: DateTime(2025, 6, 15)),
    ];
    when(mockSocial.friendsStream()).thenAnswer((_) => Stream.value(friends));
    when(
      mockSocial.incomingRequestsStream(),
    ).thenAnswer((_) => Stream.value(const []));

    await tester.pumpWidget(const MaterialApp(home: FriendsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOne);
    expect(find.text('Bob'), findsOne);
  });

  testWidgets('renders incoming friend requests', (tester) async {
    final requests = [
      FriendRequest(
        id: 'r1',
        fromUid: 'u2',
        fromName: 'Carl',
        toUid: 'u1',
        status: 'pending',
        createdAt: DateTime(2025, 7, 1),
      ),
    ];
    when(mockSocial.friendsStream()).thenAnswer((_) => Stream.value(const []));
    when(
      mockSocial.incomingRequestsStream(),
    ).thenAnswer((_) => Stream.value(requests));

    await tester.pumpWidget(const MaterialApp(home: FriendsScreen()));
    await tester.pumpAndSettle();

    // Requests tab
    await tester.tap(find.text('Запросы'));
    await tester.pumpAndSettle();

    expect(find.text('Carl'), findsOne);
  });
}
