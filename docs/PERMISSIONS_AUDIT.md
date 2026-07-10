# Android / iOS Permissions Audit

Audit date: 2026-07-11.

## Android

| Permission | Product flow | Code evidence | Result |
|---|---|---|---|
| `INTERNET` | Firebase, DeepSeek proxy, OpenFoodFacts, CDN assets | network/Firebase services | Required |
| `CAMERA` | barcode scan, workout QR import, avatar/progress capture | `MobileScanner`, `ImagePicker(ImageSource.camera)` | Required; localized pre-prompt rationale added |
| `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` | optional city detection during onboarding | `Geolocator` in `profile_setup_screen.dart` | Required for current flow; manual fallback remains |
| `POST_NOTIFICATIONS` | workout reminders, challenge/social push | Firebase Messaging | Required when enabled; no automatic sign-in prompt |
| Health Connect READ scopes | steps, active/total calories, heart/resting rate, HRV, respiratory rate, weight, height, sleep, distance, hydration, exercise | exact `HealthConnectService._types` mapping | Scoped and matched |

Removed permissions remain absent: `BODY_SENSORS`, `BODY_SENSORS_BACKGROUND`, and `ACTIVITY_RECOGNITION`. No storage/media permission is declared; `image_picker` uses platform pickers.

## iOS purpose strings

| Key | Product flow | Result |
|---|---|---|
| `NSCameraUsageDescription` | barcode/QR and avatar/progress capture | Added |
| `NSPhotoLibraryUsageDescription` | avatar/progress selection | Added |
| `NSLocationWhenInUseUsageDescription` | optional city detection | Present |
| `NSHealthShareUsageDescription` | read HealthKit metrics | Present |
| `NSHealthUpdateUsageDescription` | workout/health write capability | Present |

`NSLocationAlwaysAndWhenInUseUsageDescription` remains absent; the app has no background-location flow.

## Runtime rationale behavior

- Camera: shown before barcode scanner, QR import, avatar camera, and progress camera.
- Photos: shown before avatar and progress gallery selection.
- Notifications: the auth-state listener only registers an FCM token when permission already exists. The system prompt is requested after an explicit localized rationale from notification settings.
- Health: Health Sync screen explains the requested data before authorization.
- Location: onboarding explains city detection and retains manual entry after denial.
- The six new camera/photo/notification strings exist in all 15 supported locales and are covered by a parity test.
- `HealthSyncScreen` supports injected BLoC state and has widget coverage for loading, loaded metrics, not-installed UI, and lifecycle ownership.

Camera/photo/notification rationale is localized for all 15 supported languages, and location uses the app localization layer. The Health Sync screen rationale is still hardcoded in Russian. Native iOS purpose strings in `Info.plist` are also currently Russian-only; international builds still need localized Health Sync copy and `InfoPlist.strings` resources.

## External checks still required

- Real-device deny, deny-forever, and Settings-return behavior on supported Android/iOS versions.
- Google Play Data safety and Health Connect declarations must match the final product usage.
- Decide whether all Health scopes should remain one authorization bundle or become lazy/optional by metric.
- Confirm App Store privacy labels and purpose wording with the final legal/privacy policy.
- Add localized iOS `InfoPlist.strings` for Camera, Photo Library, Location and Health purpose descriptions before an international release.
- Move Health Sync rationale/status/action strings into `AppLocalizations` for all supported languages.
