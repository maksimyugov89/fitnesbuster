# Test Coverage Priorities

Verified baseline: 2026-07-11, Flutter 3.38.5 / Dart 3.10.4.

- 48 Dart `_test.dart` files.
- Full Windows run: 474 passed, 13 skipped, 2 known golden pixel diffs; 489 registered results total.
- Expected Linux result if the tracked golden baselines remain valid: 476 passed, 13 skipped. A real GitHub Actions run is still required to confirm this.
- Non-generated line coverage: 4406 / 21391, or 20.60%.
- Generated `*.g.dart`, `*.freezed.dart`, and `*.mocks.dart` files are excluded.
- Cloud Functions are counted separately: 38 unit/spec + 6 callable emulator tests.

Coverage is a navigation aid, not a release target. Security, persistence, authorization, and state-transition boundaries remain more important than the aggregate percentage.

## Completed or substantially advanced

| File / boundary | Verified coverage | What is covered |
|---|---:|---|
| `core/services/social_service.dart` | 78 / 130 (60.00%) | callable payloads/errors and all six Firestore streams |
| `core/cache/hive_cache.dart` | 46 / 61 (75.41%) | AI plans, freshness, user isolation, malformed chat data, sync flags |
| `data/repositories/auth_repository.dart` | repository tests present | Firestore profile hydration/fallback and auth operations |
| `data/repositories/user_repository.dart` | repository tests present | profile/onboarding/settings/measurement payloads and fallback behavior |
| `core/router/app_router.dart` redirect helper | decision matrix covered | auth/public/social/onboarding/verify-email redirect combinations |
| `screens/social/feed_screen.dart` | 74 / 128 (57.81%) | empty and event-list states |
| `screens/social/friends_screen.dart` | 157 / 302 (51.99%) | empty, friends, incoming requests and tab transition |
| `screens/social/challenges_screen.dart` | 209 / 627 (33.33%) | my/public empty states and challenge rendering |
| `screens/profile/health_sync_screen.dart` | 179 / 201 (89.05%) | loading, loaded metrics, not-installed UI and injected BLoC ownership |
| `widgets/profile/profile_edit_sheets.dart` | 127 / 401 (31.67%) | profile/body inputs plus permission-related UI paths |
| `data/models/workout_day.dart` | 57 / 87 (65.52%) | parsing, timed reps, totals and plan selection |
| `core/services/workout_session.dart` | 51 / 81 (62.96%) | session state, timers, exercise/progress/calorie helpers and end behavior |

## Quality corrections made during review

- Tests that copied `OptionCard`, `ActionButton`, profile stats, and current-program widgets into the test files were rejected as false confidence: copied code cannot detect regressions in production.
- The production widgets are now exercised directly through `ImportOptionCard`, `ImportActionButton`, `ProfileStatsRow`, and `ProfileCurrentProgram`.
- Those real tests found and fixed a production defect: `ImportActionButton` remained tappable while `loading == true`.
- `HealthSyncScreen` now accepts an injected `HealthSyncBloc`; its previous mock was unused because the screen always constructed a real BLoC internally.

## Remaining priorities

### Priority 1 — stateful workout execution

| File | Current coverage | Plan |
|---|---:|---|
| `screens/workout/workout_execution_screen.dart` | 0 / 739 | inject TTS, wakelock and clock/timer adapters; test phase transitions, pause/resume, set completion and finish |
| `screens/workout/workout_session_screen.dart` | 0 / 483 | test shared `WorkoutSession` rendering, lifecycle ownership and mini-player synchronization |

Do not solve this by copying private widgets into tests. First isolate platform adapters and deterministic time.

### Priority 2 — complete large-screen workflows

| File | Current coverage | Next useful scenarios |
|---|---:|---|
| `screens/workout/import_workout_sheet.dart` | 62 / 719 (8.62%) | source selection, QR rationale, parsing/error/save transitions |
| `screens/profile/profile_screen.dart` | 66 / 767 (8.60%) | repository load, edit/save flows, notifications rationale, logout/delete |
| `screens/onboarding/profile_setup_screen.dart` | 314 / 777 (40.41%) | location denial/manual fallback and final persisted payload |
| `core/router/app_router.dart` | 5 / 77 (6.49%) | actual GoRouter refresh/listener integration, not only the pure redirect helper |

### Priority 3 — integration and security boundaries

- Firestore client-SDK rules tests for allowed reads and denied direct social/challenge/feed writes.
- DeepSeek mock-transport tests for provider timeout, malformed response, non-200 response and missing secret behavior.
- Real-device Health Connect/HealthKit and permission deny/Settings-return scenarios.

## Recalculate

```powershell
flutter test --coverage --reporter=expanded
```

On Windows the two Linux-generated goldens currently differ by 0.77% and 0.59%. Do not update tracked baselines from Windows merely to make the local run green; the authoritative verification is Linux/Flutter 3.38.5 CI plus visual review.
