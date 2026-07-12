# FitnesBuster Release / Smoke Checklist

Use this checklist before a release candidate or after Firebase/config changes.

## Firebase project

- Confirm Firestore database id is `fitnesbuster`, not `(default)`.
- Deploy rules/indexes/functions to the same Firebase project/environment.
- Confirm Cloud Functions run on Node 22.
- Confirm `DEEPSEEK_API_KEY` secret is set for the functions region.
- Run the local demo-project emulator gate; it must not read or mutate production data.

## Android identity

- [x] Official `android/app/google-services.json` is installed for Firebase Android app `com.fitnesbuster.app`.
- [x] Debug/release SHA-1 and SHA-256 fingerprints are registered in Firebase Console.
- [x] Android OAuth clients in `google-services.json` use `com.fitnesbuster.app` and the confirmed debug/release SHA-1 hashes.
- [x] Firebase Authentication Google provider is enabled and Project support email is configured.
- [x] Run real Google Sign-In and repeat sign-out/sign-in on Android; existing profile/workout plan read-back passed on realme RMX3853 (2026-07-11).
- [ ] Confirm the same user in Firebase Authentication → Users and the target project/database in Firebase Console.
- [ ] Before Play distribution, confirm Play Console package `com.fitnesbuster.app` and add Play App Signing SHA-1/SHA-256 to Firebase. Upload/release keystore SHA alone is not sufficient for Play-installed builds.

## Auth and profile

- Register a new account.
- Verify email flow redirects to `/verify-email` until verified.
- Complete onboarding and confirm redirect to dashboard.
- Edit profile and avatar from camera/gallery.
- [x] Sign out/sign in and confirm existing profile/workout plan persists on the real Android device.

## Firestore data flows

- Update profile and confirm read-back from app.
- Save onboarding/workout settings and confirm read-back.
- Generate AI workout/meal plans and confirm cached fallback still works offline.
- Toggle network offline, trigger queued AI-plan sync, reconnect, and confirm queue flushes.

## Social

- Search users by name and username.
- Send, accept, decline, and remove friend requests.
- Publish activity via app action and confirm `activity_events` write goes through callable.
- Confirm friend feed fanout appears in friends' feeds.

## Challenges

- Create, join, leave, and delete challenge.
- Create a private challenge and confirm only friends receive the invite/feed event.
- Confirm a stranger cannot join a private challenge and a non-owner cannot delete it.
- Update progress with lower value and confirm progress remains monotonic.
- Record workout and confirm active challenges update correctly.
- Complete challenge and confirm `challenge_won` event appears.

## Health and permissions

- [x] Open Health Sync screen and confirm the Android Health Connect permission flow (realme RMX3853, Android 16/API 36, 2026-07-11).
- [x] Grant full and partial Health Connect access; a missing HRV permission preserves every other available metric.
- [x] Revoke all Health Connect permissions; confirm access-denied UI instead of a successful zero sync.
- [x] Open Health Connect Settings from the app, grant all 13 scopes, tap `Проверить снова`, and confirm recovery without restart.
- [x] Verify Android units with Toolbox 2.3.3: kcal, bpm, HRV ms, breaths/min, kg, m/cm, km, ml, sleep minutes and workout count. Synthetic records and Toolbox were removed after the run.
- [x] Detect city from onboarding; verify real Android deny, manual fallback, Settings recovery and final `LocationPermission.whileInUse` after App Info → Permissions → Location → while-in-use grant. On RMX3853 / Android 16 repeated location deny did not produce a stable `deniedForever`, so the app now offers Settings recovery after a normal denial too.
- [x] Enable notifications from settings; verify rationale, two denials/Android `USER_FIXED`, Settings recovery and final `POST_NOTIFICATIONS granted=true`.
- [ ] Confirm FCM token write/read-back and actual notification delivery after grant.
- [x] Re-run the release-signed APK camera flow: rationale, deny, deny forever/`USER_FIXED`, recovery UI, Settings grant and automatic lifecycle refresh without app restart.
- [x] Confirm photo-library rationale opens Android Photo Picker without a broad media permission and cancel returns safely.
- [x] Confirm notification permission is not requested automatically at sign-in; it appears after saving enabled notification settings.
- iOS is outside the current release scope.

## Accessibility / UI

- [x] Check Dashboard at 1.2x and Profile/Notifications at 1.4x on real Android; no overflow/crash, then restore system scale to 1.0.
- [ ] Complete the 1.2x/1.4x matrix for Health Sync, friends, challenges and AI chat.
- Spot-check 1.6x for overflow; decide whether to support beyond current 1.4 clamp.
- Check small Android device and one large device/tablet viewport.

## Final verification commands

```powershell
cd functions
npm test
npm run test:emulator:exec

cd ..
dart format --output=none --set-exit-if-changed lib/ test/ integration_test/
flutter analyze --no-fatal-infos --no-fatal-warnings lib test integration_test
flutter test --coverage --reporter=expanded
flutter build apk --release --no-pub
flutter build appbundle --release --no-pub

cd android
.\gradlew.bat :app:processDebugGoogleServices :app:processDebugMainManifest :app:compileDebugKotlin --stacktrace
```

Expected current automated baseline:

- Functions unit/spec: 38 passed.
- Functions callable emulator: 6 passed.
- Flutter Linux/Docker 3.38.5: 498 registered results, 485 passed, 13 skipped.
- Windows renderer diagnostic: dashboard/workout_plan golden diffs remain known at 0.77% and 0.59%; do not update baselines from Windows.
- Non-generated Flutter line coverage: 4406/21391 (20.60%).
- `dart format --output=none --set-exit-if-changed lib test integration_test`: clean.
- `flutter analyze --no-fatal-infos --no-fatal-warnings lib test integration_test`: no issues.
- `flutter build apk --release --no-pub`: builds `build/app/outputs/flutter-apk/app-release.apk`; Flutter 3.38.5 Android generated registrant quirk is handled by the release Gradle strip-task.
- `flutter build appbundle --release --no-pub`: builds `build/app/outputs/bundle/release/app-release.aab`; current build emits a non-blocking `CupertinoIcons` tree-shake font warning with no direct `CupertinoIcons` usage found in app/test sources.

Linux/Flutter 3.38.5 CI is authoritative for the two golden tests. Do not update their tracked PNG baselines from Windows.

## Real Android feature smoke (2026-07-11)

- [x] Workout prep → execution → set → rest, TTS, wakelock, background/foreground recovery, mini-player reconnect and partial exit.
- [x] 3D GLB load, rotation and selected-muscle highlight without FATAL/OOM/WebView errors.
- [x] Exercise GIF thumbnail CDN smoke in the 1,346-item browser.
- [x] Production read smoke for profile/workout plan/feed/friends/challenges without permission errors.
- [x] Production AI chat callable returned and rendered an authenticated response within 20 seconds.
