# FitnesBuster: Codex Audit Fix Context

Дата аудита: 2026-07-09
Проект: Flutter/Firebase приложение FitnesBuster
Назначение файла: рабочая память для будущих правок после аудита. Перед фиксом открывать этот файл, чтобы быстро понять, что было найдено, какие риски приоритетны и какие файлы смотреть первыми.

## Краткий вердикт

Проект уже выглядит заметно зрелее обычного прототипа: есть Clean Architecture/BLoC, GetIt DI, Firebase Auth/Firestore/Functions/FCM, AI через Cloud Function proxy, Health Connect/HealthKit, локализация, тесты, CI/CD, security scan, legal docs и большая база упражнений.

Главный риск не в качестве отдельных виджетов, а в системных несостыковках между слоями: Firestore database id, частично недоделанная offline queue, конфликт client writes с Firestore rules, незавершенно подтвержденный Flutter toolchain/testability и релизные настройки.

Оценка состояния на момент аудита: примерно 7/10.

## Важный контекст worktree

На момент аудита в git уже были пользовательские незакоммиченные изменения:

- `functions/src/constants.ts`
- `lib/core/ai/base_client.dart`
- `lib/core/ai/services/plan_refinement_service.dart`

Суть изменений: увеличены лимиты AI-запросов (`maxTokens`, длина сообщений). Эти изменения не трогать без явного запроса. Если правка касается тех же файлов, сначала внимательно смотреть diff и работать поверх текущего состояния.

Дополнительно после правок Codex в worktree появились изменения по audit-fixes:

- `.github/workflows/ci.yml` — Node 22 для Cloud Functions CI.
- `android/app/build.gradle.kts`, `android/app/google-services.json`, `android/app/src/main/kotlin/com/fitnesbuster/app/MainActivity.kt`, `lib/core/services/share_intent_service.dart` — Android package id переведен на `com.fitnesbuster.app`.
- `lib/core/constants/firebase_config.dart`, `functions/src/firebaseConfig.ts`, `functions/src/shared.ts`, `functions/src/feed.ts`, `lib/core/di/injection.dart`, `lib/core/services/social_service.dart` — Firestore named database `fitnesbuster` приведена к одному источнику.
- `lib/core/cache/offline_queue.dart` — очередь стала типизированной по `type`, с передачей `data`, retry attempts и dead-letter box.
- `functions/src/feed.ts`, `functions/src/feedValidation.ts`, `functions/src/index.ts`, `functions/src/types.ts`, `functions/test/feedValidation.test.js`, `firestore.rules` — добавлен callable `publishActivity` и первые Functions tests.
- `lib/core/ai/base_client.dart` — Firebase callable errors маппятся в `AiException`.
- `lib/main.dart` — text scaling теперь clamp до 1.4 вместо полного отключения.
- `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist` — убраны явно фоновые permissions.
- `functions/src/proxies.ts`, `functions/src/proxiesValidation.ts`, `functions/test/proxiesValidation.test.js` — валидация `deepseekProxy` вынесена в pure-модуль и покрыта тестами на payload/limits.
- `test/core/offline_queue_test.dart` — добавлены unit-тесты для parse/dispatch/retry/dead-letter `OfflineQueue`.
- `test/core/ai/base_client_error_test.dart` — добавлены unit-тесты для AI error mapping и retry/no-retry classifier.
- `functions/src/friendsValidation.ts`, `functions/src/challengesValidation.ts`, `functions/src/rateLimitLogic.ts`, `functions/src/accountCleanupPlan.ts`, `functions/test/*.test.js` — добавлены pure-spec tests для friends/challenges/rate limiter/deleteAccount cleanup plan.
- `lib/data/repositories/user_repository.dart`, `lib/core/di/injection.dart` — `OfflineQueue` подключена к deferred sync AI-планов через реальный handler `user.aiPlans.sync`.
- `lib/core/cache/offline_queue.dart` — добавлены events/hasDeadLetters и warning-логирование dead-letter/no-handler.
- `lib/core/router/app_router.dart`, `test/core/router/auth_redirect_test.dart` — auth redirect decision вынесен в тестируемый helper.
- `lib/core/services/social_service.dart`, `test/core/services/social_service_test.dart` — SocialService стал тестируемым через injectable callable invoker/current uid provider.
- `lib/core/health/health_data_mapper.dart`, `test/core/health/health_data_mapper_test.dart` — добавлены tests health mapper.
- `android/app/src/main/AndroidManifest.xml` — убраны широкие `ACTIVITY_RECOGNITION` и `BODY_SENSORS`; остаются scoped Health Connect permissions.
- `lib/presentation/screens/onboarding/profile_setup_screen.dart`, `lib/presentation/screens/profile/health_sync_screen.dart` — добавлен runtime rationale для location/Health Connect.
- `lib/presentation/widgets/profile/avatar_picker.dart`, `lib/presentation/widgets/profile/avatar_picker_sheet.dart`, `lib/presentation/screens/profile/health_sync_screen.dart` — точечные text-scale overflow fixes.
- `docs/RELEASE_SMOKE_CHECKLIST.md` — добавлен release/manual smoke checklist.

Также в worktree есть удаление `REFACTORING_REPORT_V2.md`; Codex его не делал и не должен восстанавливать/трогать без явного запроса.

## Проверки, которые запускались

Успешно:

- `npm run build` в `functions` прошел успешно, `tsc` собрал Cloud Functions.
- `npm test` в `functions` прошел успешно после добавления `node:test` suites: 35/35 tests.
- `dart --version` и `flutter --version` зависают внутри sandbox, но успешно проходят вне sandbox: Dart 3.10.4, Flutter 3.38.5.
- `dart format` по затронутым Dart-файлам успешно прошел вне sandbox; контрольный `dart format --output=none --set-exit-if-changed ...` показал 0 changes.
- Точечный `flutter test test/core/offline_queue_test.dart test/core/ai/base_client_error_test.dart test/core/router/auth_redirect_test.dart test/core/health/health_data_mapper_test.dart test/core/services/social_service_test.dart --reporter=expanded` успешно прошел вне sandbox: 21/21 tests.
- Точечный `flutter analyze --no-fatal-infos --no-fatal-warnings ...` по затронутым файлам успешно прошел вне sandbox: No issues found.
- Полный `flutter analyze --no-fatal-infos --no-fatal-warnings lib test` успешно прошел вне sandbox: No issues found.
- `.\gradlew.bat :app:processDebugMainManifest --stacktrace` прошел успешно вне sandbox после удаления лишних permissions.
- `.\gradlew.bat :app:processDebugGoogleServices --stacktrace` прошел успешно после смены Android package id.
- `.\gradlew.bat :app:compileDebugKotlin --stacktrace` прошел успешно после переноса `MainActivity`.
- `.\gradlew.bat :app:processDebugMainManifest --stacktrace` прошел успешно после правки permissions.
- Контрольный `rg` не находит в проверяемых путях: `admin.firestore()`, `FirebaseFirestore.instance`, `BODY_SENSORS_BACKGROUND`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `TextScaler.noScaling`, `node-version: '20'`.

Не удалось подтвердить в текущей среде:

- `flutter analyze --no-fatal-infos --no-fatal-warnings lib test` не завершился за 5 минут.
- `dart format --output=none --set-exit-if-changed lib test` не завершился за 2 минуты.
- `flutter test test/services/recovery_score_service_test.dart --reporter=expanded` не завершился за 2 минуты.
- Внутри sandbox даже `dart --version`/`flutter --version` зависают; вне sandbox tooling работает. Для Flutter/Dart проверок в этой среде использовать approved/escalated command.
- Полный `flutter test --reporter=expanded` вне sandbox доходит до конца, но падают 2 существующих golden tests: `test/golden/dashboard_golden_test.dart` (`goldens/dashboard.png`, 0.77% diff) и `test/golden/workout_plan_golden_test.dart` (`goldens/workout_plan.png`, 0.59% diff). Новые targeted tests проходят.

Это не доказывает, что Flutter-часть сломана: вне sandbox Dart/Flutter tooling работает. Полный analyze чистый; полный test suite блокируют только существующие golden pixel diffs, которые нужно визуально ревьюить/обновлять отдельно.

## P0: Firestore database id mismatch

Статус: исправлено в коде, но нужен внешний smoke-check с реальным Firebase проектом.

Риск: разные части приложения могут читать и писать в разные Firestore databases.

Факты:

- Основной DI регистрирует Firestore через `FirebaseFirestore.instanceFor(... databaseId: 'fitnesbuster')` в `lib/core/di/injection.dart`.
- `SocialService` теперь получает `FirebaseFirestore` через DI и использует тот же named database.
- Cloud Functions теперь используют `getFirestore(FIRESTORE_DATABASE_ID)`, где `FIRESTORE_DATABASE_ID = "fitnesbuster"`.
- Firestore trigger `fanoutActivityEvent` теперь явно указывает `database: FIRESTORE_DATABASE_ID`.

Что уже сделано:

- Добавлен `lib/core/constants/firebase_config.dart`.
- Добавлен `functions/src/firebaseConfig.ts`.
- `lib/core/di/injection.dart` больше не содержит hardcoded строку DB id.
- `functions/src/shared.ts` переведен с `admin.firestore()` на `getFirestore("fitnesbuster")`.
- `lib/core/services/social_service.dart` больше не использует `FirebaseFirestore.instance`.
- `functions/src/feed.ts` trigger слушает named database.

Что еще нужно доделать:

- В Firebase Console/CLI подтвердить, что реальная Firestore DB проекта действительно называется `fitnesbuster`, а не `(default)`.
- Прогнать ручной smoke-check на dev/staging: profile write/read, friends/search, challenges, feed fanout работают в одной базе.
- Если выяснится, что production использует `(default)`, откатить константу DB id на default-стратегию или мигрировать данные.

Файлы:

- `lib/core/di/injection.dart`
- `lib/core/constants/firebase_config.dart`
- `lib/core/services/social_service.dart`
- `functions/src/shared.ts`
- `functions/src/firebaseConfig.ts`
- `functions/src/feed.ts`
- `firestore.rules`
- `firestore.indexes.json`

## P0: OfflineQueue недоделана

Статус: основная техническая проблема исправлена, unit-тесты добавлены, первый реальный product handler подключен для deferred AI-plan sync.

Риск: механизм офлайн-синхронизации выглядит как существующий, но фактически не исполняет операции типизированно.

Факты:

- `QueueOperation` теперь принимает `Map<String, dynamic> data`.
- handlers теперь хранятся как `Map<String, QueueOperation>`.
- `flush()` парсит JSON, достает `type`, ищет конкретный handler и передает `data`.
- Добавлены `attempts`, `maxAttempts` и `offline_queue_dead_letter` box для записей, которые не удается выполнить.
- Очередь регистрируется в DI до `UserRepository`.
- `UserRepository` регистрирует handler `user.aiPlans.sync`, который пушит cached AI plans в Firestore при восстановлении сети.
- Dead-letter теперь логируется и публикуется через `OfflineQueue.events`.

Что уже сделано:

- Типизированный dispatch по `type`.
- Удаление битых JSON-записей, которые нельзя распарсить.
- Retry attempts и dead-letter после лимита.

Что еще нужно доделать:

- Решить продуктово, какие еще реальные операции должны enqueue/registerHandler.
- Пока очередь покрывает только AI-plan sync; не позиционировать приложение как полноценное offline-first для всех действий.

Файлы:

- `lib/core/cache/offline_queue.dart`
- `lib/core/di/injection.dart`

## P1: publishActivity конфликтует с Firestore rules

Статус: исправлено, добавлен server path и validation.

Риск: если клиент начнет использовать `publishActivity()`, запись будет отклонена правилами, а social feed будет работать нестабильно.

Факты:

- `SocialService.publishActivity()` теперь вызывает callable `publishActivity`.
- `firestore.rules` оставляет прямую запись в `activity_events` закрытой и указывает на callable path.
- Callable `publishActivity` валидирует auth, `type`, размер/форму `data`, rate-limit и пишет через Admin SDK.
- Добавлены pure validation tests для `publishActivity`.

Что еще нужно доделать:

- Расширить allowed activity types при появлении новых событий.
- Добавить callable/integration тест с mock/emulator DB, если будет выбрана полноценная Functions test-инфраструктура.

Файлы:

- `lib/core/services/social_service.dart`
- `lib/core/services/i_social_service.dart`
- `functions/src/feed.ts` или новый functions-файл
- `functions/src/feedValidation.ts`
- `functions/test/feedValidation.test.js`
- `functions/src/index.ts`
- `firestore.rules`

## P1: Node version mismatch в CI

Статус: исправлено.

Риск: локально/деплой требуют Node 22, CI собирает на Node 20.

Факты:

- `functions/package.json` содержит `"engines": {"node": "22"}`.
- `.github/workflows/ci.yml` теперь использует `actions/setup-node` с `node-version: '22'`.

Что еще нужно доделать:

- Ничего по этому пункту, кроме проверки реального GitHub Actions run после push/PR.

Файлы:

- `functions/package.json`
- `.github/workflows/ci.yml`
- возможно `.github/workflows/release.yml`/deploy workflow, если появится деплой functions.

## P1: AI retry ловит не все реальные сбои

Статус: исправлено в `BaseClient`, unit-тесты mapping/retry classifier добавлены и точечно пройдены вне sandbox.

Риск: transient ошибки Firebase callable могут не ретраиться, хотя пользователь ожидает повтор.

Факты:

- `withRetry` в `lib/core/ai/network/retry_handler.dart` ловит только `AiException`.
- `BaseClient` вызывает Firebase callable `deepseekProxy`; реальные ошибки могут быть `FirebaseFunctionsException`.
- `BaseClient` теперь ловит `FirebaseFunctionsException` и маппит ее в `AiException` с `statusCode`.
- 400/401/403/429 не ретраятся; 500/503/504 остаются retryable через существующий `withRetry`.

Что еще нужно доделать:

- Прогнать полный Flutter test suite в CI/вне sandbox; точечные новые Dart unit-тесты уже прошли вне sandbox.
- При желании расширить `AiException` типом ошибки, если UI должен различать rate limit/network/auth.

Файлы:

- `lib/core/ai/base_client.dart`
- `lib/core/ai/network/retry_handler.dart`
- `lib/core/ai/ai_exception.dart`

## P1: Cloud Functions без unit/spec тестов

Статус: существенно продвинуто. Инфраструктура появилась; pure/spec tests покрывают `publishActivity`, `deepseekProxy`, friends validation/search merge, challenges validation/streak/progress, rate limiter logic, deleteAccount cleanup plan. Полноценные emulator/callable integration tests еще не закрыты.

Риск: самая критичная серверная логика не покрыта локальными тестами.

Что уже сделано:

- Добавлен `functions/package.json` script: `npm test`.
- Используется встроенный Node 22 `node:test`, без новых dev dependencies.
- Добавлен `functions/src/feedValidation.ts` как pure validation module.
- Добавлен `functions/test/feedValidation.test.js`: 5 тестов, проходят через `npm test`.
- Добавлен `functions/src/proxiesValidation.ts` и `functions/test/proxiesValidation.test.js`: 7 тестов на `deepseekProxy` payload/limits, проходят через `npm test`.
- Добавлены `functions/src/friendsValidation.ts`, `functions/src/challengesValidation.ts`, `functions/src/rateLimitLogic.ts`, `functions/src/accountCleanupPlan.ts` и соответствующие tests. Всего `npm test`: 35/35.

Что нужно покрыть:

- `deepseekProxy`: auth required и сетевые/secret сценарии еще не покрыты; pure tests уже покрывают limits, invalid messages, maxTokens cap, invalid temperature, missing payload.
- friends: callable/emulator tests на реальные Firestore reads/writes, duplicate request behavior.
- challenges: callable/emulator tests join/leave/delete permissions, transaction behavior.
- deleteAccount: emulator test полного удаления профиля, friends, requests, feeds, challenge progress, auth user last.
- rate limiter: emulator/concurrency test contention fail-closed.
- `publishActivity`: callable auth/rate-limit/write behavior через mock/emulator DB, не только pure validation.

Файлы:

- `functions/src/*.ts`
- `functions/test/*.test.js`

## P2: Accessibility/Text scaling

Статус: исправлено в коде, добавлены точечные overflow fixes, нужна визуальная проверка экранов.

Риск: приложение полностью отключает системное масштабирование текста, что плохо для accessibility и может ухудшать UX на устройствах пользователей с крупным шрифтом.

Факт:

- `main.dart` больше не использует `TextScaler.noScaling`.
- Теперь используется `MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4)`.

Что еще нужно доделать:

- Проверить ключевые экраны при 1.2x/1.4x/1.6x.
- Если 1.6x должен поддерживаться полностью, пройтись по плотным карточкам/табам и исправить layout overflow.
- Отдельно визуально ревьюить golden diffs dashboard/workout_plan перед обновлением эталонов.

Файл:

- `lib/main.dart`

## P2: Android package id все еще example

Статус: исправлено в репозитории, нужен официальный Firebase config для нового package id.

Риск: перед публикацией менять package id болезненно; лучше сделать до реального релиза.

Факты:

- `android/app/build.gradle.kts`: `namespace = "com.fitnesbuster.app"`.
- `android/app/build.gradle.kts`: `applicationId = "com.fitnesbuster.app"`.
- `MainActivity.kt` перенесен в `android/app/src/main/kotlin/com/fitnesbuster/app`.
- MethodChannel обновлен на `com.fitnesbuster.app/share`.
- `google-services.json` repo-level обновлен на `package_name = "com.fitnesbuster.app"`, чтобы локальная сборка не падала.

Что еще нужно доделать:

- Перегенерировать/обновить `google-services.json`.
- Проверить Google Sign-In SHA fingerprints и Firebase Auth settings.
- В Firebase Console добавить/подтвердить Android app с package `com.fitnesbuster.app`.
- Проверить, что Play Console/Google Sign-In/OAuth client используют новый package и нужные SHA.

Файлы:

- `android/app/build.gradle.kts`
- `android/app/google-services.json`
- Firebase console settings вне репозитория.

## P2: Permissions слишком широкие

Статус: частично исправлено. Background permissions и широкие sensor/activity permissions убраны, policy review еще нужен.

Риск: Store review и доверие пользователя. Особенно чувствительны background sensors/location и health permissions.

Факты:

- Android все еще запрашивает camera, fine/coarse location, много Health Connect read permissions, post notifications.
- Android `BODY_SENSORS_BACKGROUND` убран.
- Android `ACTIVITY_RECOGNITION` и `BODY_SENSORS` убраны, так как код читает метрики через scoped Health Connect permissions.
- iOS `NSLocationAlwaysAndWhenInUseUsageDescription` убран; остался `NSLocationWhenInUseUsageDescription`.

Что еще нужно доделать:

- Убедиться, что каждое permission реально нужно.
- Добавить/локализовать более полные runtime rationale там, где нужно. Сейчас добавлены location SnackBar и Health Connect пояснение.
- Проверить Health Connect policy и Google Play Data safety.
- Отдельно пересмотреть полный список Health Connect read permissions: возможно часть метрик можно запрашивать лениво/опционально.

Файлы:

- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

## P2: Coverage и тесты

Статус: не закрыто, но Functions/Dart hotspot tests усилены.

Факты:

- Есть 53 Dart test/integration файла и 20 mocks.
- Golden tests присутствуют.
- Локальный `coverage/lcov.info` показывает около 12.5% line coverage по non-generated строкам, что низко для такого объема.
- При этом отдельные сервисы/BLoC покрыты хорошо, но общий UI/infrastructure слой слабее.

Что делать:

- Не гнаться за общим процентом вслепую.
- Усилить тесты вокруг risk hotspots: auth router, Firestore repository behavior, AI error mapping, offline queue, social service, health mapper.
- Продолжить Cloud Functions emulator/callable tests: pure/spec layer уже расширен до 35 tests.

## Дополнительные наблюдения

AI и безопасность:

- Хорошо: DeepSeek key не в клиенте, используется Secret в Functions.
- Хорошо: request auth и rate limit есть.
- Риск: rate limiter fail-open на инфраструктурной ошибке. Для дорогих AI endpoint можно рассмотреть fail-closed или degraded quota.
- Недавние изменения увеличивают `maxTokens` и message length. Это может быть нужно для больших планов, но растит стоимость, latency и нагрузку.

Локализация:

- Поддерживается много языков, включая RTL для Arabic.
- Legal docs пока Russian only, что нормально для РФ-правовой базы, но если приложение международное, нужно решить стратегию legal localization.

Ассеты:

- GIF раздаются через Firebase Hosting CDN, это хорошо.
- В workspace локально лежат большие assets/public/build, но Git в основном их игнорирует. Следить, чтобы тяжелые исходники не попали в репозиторий.

Firebase client config:

- `android/app/google-services.json` и `lib/firebase_options.dart` закоммичены. Это нормально для Firebase client config, но API key нужно ограничить в Google Cloud Console по package/bundle/SHA и разрешенным API.
- После смены Android package id на `com.fitnesbuster.app` нужно официально перегенерировать `google-services.json` из Firebase Console. Repo-level package_name уже изменен, но OAuth/SHA/client ids должны быть подтверждены в Firebase/Google Cloud.

## Рекомендуемый порядок будущих фиксов

1. Подтвердить реальную Firestore DB в Firebase Console и прогнать social/challenges/profile smoke-check.
2. Перегенерировать официальный `google-services.json` для `com.fitnesbuster.app`, проверить Google Sign-In SHA fingerprints и Firebase Auth settings.
3. Добить Cloud Functions emulator/callable tests: deepseekProxy auth/secret/network, friends, challenges, deleteAccount, rate limiter contention, callable publishActivity.
4. Визуально проверить и либо принять/обновить golden baselines `dashboard.png`/`workout_plan.png`, либо исправить расхождения.
5. Проверить ключевые экраны при text scaling 1.2x/1.4x/1.6x и поправить overflow.
6. Провести permissions/policy review: Health Connect scopes, runtime rationale, Google Play Data safety.
7. Усилить coverage вокруг risk hotspots: auth router, Firestore repositories, social service, health mapper.

## Быстрые команды для повторной проверки

```powershell
git status --short
npm run build
npm test
flutter analyze --no-fatal-infos --no-fatal-warnings lib test
dart format --output=none --set-exit-if-changed lib test
flutter test --coverage --reporter=expanded
cd android
.\gradlew.bat :app:processDebugGoogleServices :app:processDebugMainManifest :app:compileDebugKotlin --stacktrace
```

Если Flutter-команды снова зависают локально, проверять в CI или отдельной чистой Flutter среде.
