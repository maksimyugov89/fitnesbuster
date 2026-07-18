import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitnesbuster/core/constants/firestore_collections.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';
import 'package:fitnesbuster/domain/entities/test_week_progress.dart';
import 'package:fitnesbuster/domain/repositories/i_test_week_progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class TestWeekProgressRemoteStore {
  Future<TestWeekProgress?> load(String userId);
  Future<void> save(String userId, TestWeekProgress progress);
}

class FirestoreTestWeekProgressRemoteStore
    implements TestWeekProgressRemoteStore {
  static const progressField = 'testWeekProgress';
  static const updatedAtField = 'testWeekProgressUpdatedAt';

  final FirebaseFirestore _firestore;

  FirestoreTestWeekProgressRemoteStore({required FirebaseFirestore firestore})
    : _firestore = firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _firestore.collection(FirestoreCollections.users).doc(userId);

  @override
  Future<TestWeekProgress?> load(String userId) async {
    final snapshot = await _userDoc(userId).get();
    final data = snapshot.data();
    final raw = data?[progressField];
    if (raw is! Map) return null;
    final progress = TestWeekProgress.fromJson(Map<String, dynamic>.from(raw));
    final serverUpdatedAt = data?[updatedAtField];
    return serverUpdatedAt is Timestamp
        ? progress.copyWith(updatedAt: serverUpdatedAt.toDate().toUtc())
        : progress;
  }

  @override
  Future<void> save(String userId, TestWeekProgress progress) =>
      _userDoc(userId).set({
        progressField: progress.toJson(),
        updatedAtField: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}

/// Local-first repository. Firestore is the cross-device source while
/// SharedPreferences keeps the assessment usable without a network.
class TestWeekProgressRepository implements ITestWeekProgressRepository {
  final TestWeekProgressRemoteStore _remote;
  final DateTime Function() _now;

  TestWeekProgressRepository({
    required TestWeekProgressRemoteStore remote,
    DateTime Function()? now,
  }) : _remote = remote,
       _now = now ?? DateTime.now;

  static String _key(String userId) => 'test_week_progress_v1_$userId';

  @override
  Future<TestWeekProgress?> load(String userId) async {
    final local = await _loadLocal(userId);
    if (userId == 'local') return local;

    TestWeekProgress? remote;
    try {
      remote = await _remote.load(userId);
    } catch (e, st) {
      appLogger.w(
        '[TestWeekProgress] server load failed, using local cache',
        error: e,
        stackTrace: st,
      );
      return local;
    }

    final winner = selectMostAdvancedTestWeekProgress(local, remote);
    if (winner == null) return null;
    await _saveLocal(userId, winner);

    // A device that made more progress offline repairs the server copy as soon
    // as it reconnects and opens the assessment again.
    if (local != null && identical(winner, local) && !_same(local, remote)) {
      try {
        await _remote.save(userId, local);
      } catch (e, st) {
        appLogger.w(
          '[TestWeekProgress] server reconciliation failed',
          error: e,
          stackTrace: st,
        );
      }
    }
    return winner;
  }

  @override
  Future<void> save(String userId, TestWeekProgress progress) async {
    final stamped = progress.copyWith(updatedAt: _now().toUtc());
    await _saveLocal(userId, stamped);
    if (userId == 'local') return;
    try {
      await _remote.save(userId, stamped);
    } catch (e, st) {
      // Local data remains authoritative until the next successful load/save.
      appLogger.w(
        '[TestWeekProgress] server save deferred',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> clear(String userId) async {
    await (await SharedPreferences.getInstance()).remove(_key(userId));
    // Keep the server copy as the completed cross-device assessment archive.
  }

  Future<TestWeekProgress?> _loadLocal(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return null;
    try {
      return TestWeekProgress.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      await prefs.remove(_key(userId));
      return null;
    }
  }

  Future<void> _saveLocal(String userId, TestWeekProgress progress) async {
    await (await SharedPreferences.getInstance()).setString(
      _key(userId),
      jsonEncode(progress.toJson()),
    );
  }

  bool _same(TestWeekProgress? a, TestWeekProgress? b) =>
      a != null &&
      b != null &&
      jsonEncode(a.toJson()) == jsonEncode(b.toJson());
}

/// Conflict policy for sequential use on several devices. Completed days are
/// monotonic; drafts then activity time break ties.
TestWeekProgress? selectMostAdvancedTestWeekProgress(
  TestWeekProgress? local,
  TestWeekProgress? remote,
) {
  if (local == null) return remote;
  if (remote == null) return local;

  final localRank = (
    local.completedDays.length,
    local.allCompletedExercises.length,
    local.draftExercises.length,
  );
  final remoteRank = (
    remote.completedDays.length,
    remote.allCompletedExercises.length,
    remote.draftExercises.length,
  );

  if (localRank.$1 != remoteRank.$1) {
    return localRank.$1 > remoteRank.$1 ? local : remote;
  }
  if (localRank.$2 != remoteRank.$2) {
    return localRank.$2 > remoteRank.$2 ? local : remote;
  }
  if (localRank.$3 != remoteRank.$3) {
    return localRank.$3 > remoteRank.$3 ? local : remote;
  }

  final localTime = local.updatedAt ?? local.startedAt;
  final remoteTime = remote.updatedAt ?? remote.startedAt;
  return localTime.isAfter(remoteTime) ? local : remote;
}
