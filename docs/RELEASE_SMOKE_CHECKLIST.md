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
- [ ] Run real Google Sign-In and confirm the user in Firebase Authentication → Users and profile in Firestore `fitnesbuster/users`.
- [ ] Before Play distribution, confirm Play Console package `com.fitnesbuster.app` and add Play App Signing SHA-1/SHA-256 to Firebase. Upload/release keystore SHA alone is not sufficient for Play-installed builds.

## Auth and profile

- Register a new account.
- Verify email flow redirects to `/verify-email` until verified.
- Complete onboarding and confirm redirect to dashboard.
- Edit profile and avatar from camera/gallery.
- Sign out/sign in and confirm profile persists.

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

- Open Health Sync screen and confirm rationale text is visible before the system prompt.
- Grant only Health Connect permissions needed for selected metrics.
- Deny Health Connect permissions and confirm graceful error.
- Detect city from onboarding; deny location and confirm manual-entry fallback.
- Enable notifications from settings and confirm the system prompt appears only after the in-app rationale; confirm token registration succeeds after grant.
- Confirm camera rationale appears before barcode/QR scanning and avatar/progress capture.
- Confirm photo-library rationale appears before avatar/progress photo selection.
- Confirm notification permission is not requested automatically at sign-in; it appears after saving enabled notification settings.
- On iOS, confirm Camera, Photo Library, Health, and When-In-Use Location system prompts show the matching purpose text.
- For an international release, verify localized Health Sync copy and localized iOS `InfoPlist.strings`; these remain pending in the current repository.

## Accessibility / UI

- Check dashboard, profile, Health Sync, friends, challenges, AI chat at text scale 1.2x and 1.4x.
- Spot-check 1.6x for overflow; decide whether to support beyond current 1.4 clamp.
- Check small Android device and one large device/tablet viewport.

## Final verification commands

```powershell
cd functions
npm test
npm run test:emulator:exec

cd ..
flutter analyze --no-fatal-infos --no-fatal-warnings lib test
flutter test --coverage --reporter=expanded

cd android
.\gradlew.bat :app:processDebugGoogleServices :app:processDebugMainManifest :app:compileDebugKotlin --stacktrace
```

Expected current automated baseline:

- Functions unit/spec: 38 passed.
- Functions callable emulator: 6 passed.
- Flutter: 489 registered results. Current Windows run: 474 passed, 13 skipped, 2 known golden diffs.
- Non-generated Flutter line coverage: 4406/21391 (20.60%).
- `flutter analyze --no-fatal-infos --no-fatal-warnings lib test`: no issues.

Linux/Flutter 3.38.5 CI is authoritative for the two golden tests. Do not update their tracked PNG baselines from Windows without visual review.
