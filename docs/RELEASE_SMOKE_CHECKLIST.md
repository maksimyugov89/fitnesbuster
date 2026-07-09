# FitnesBuster Release / Smoke Checklist

Use this checklist before a release candidate or after Firebase/config changes.

## Firebase project

- Confirm Firestore database id is `fitnesbuster`, not `(default)`.
- Deploy rules/indexes/functions to the same Firebase project/environment.
- Confirm Cloud Functions run on Node 22.
- Confirm `DEEPSEEK_API_KEY` secret is set for the functions region.

## Android identity

- Regenerate `android/app/google-services.json` from Firebase Console for `com.fitnesbuster.app`.
- Confirm SHA-1/SHA-256 fingerprints for debug/release signing keys.
- Confirm Google Sign-In OAuth client uses `com.fitnesbuster.app`.
- Confirm Play Console package name is `com.fitnesbuster.app` before publishing.

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
- Update progress with lower value and confirm progress remains monotonic.
- Record workout and confirm active challenges update correctly.
- Complete challenge and confirm `challenge_won` event appears.

## Health and permissions

- Open Health Sync screen and confirm rationale text is visible before the system prompt.
- Grant only Health Connect permissions needed for selected metrics.
- Deny Health Connect permissions and confirm graceful error.
- Detect city from onboarding; deny location and confirm manual-entry fallback.
- Confirm notifications prompt is expected and token registration succeeds after sign-in.

## Accessibility / UI

- Check dashboard, profile, Health Sync, friends, challenges, AI chat at text scale 1.2x and 1.4x.
- Spot-check 1.6x for overflow; decide whether to support beyond current 1.4 clamp.
- Check small Android device and one large device/tablet viewport.

## Final verification commands

```powershell
cd functions
npm test

cd ..
flutter analyze --no-fatal-infos --no-fatal-warnings lib test
flutter test --coverage --reporter=expanded

cd android
.\gradlew.bat :app:processDebugGoogleServices :app:processDebugMainManifest :app:compileDebugKotlin --stacktrace
```
