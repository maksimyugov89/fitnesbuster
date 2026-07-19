# FitnesBuster: Codex Audit Fix Context

Дата аудита: 2026-07-09
Дата последней сверки с git history и текущими проверками: 2026-07-11
Проект: Flutter/Firebase приложение FitnesBuster
Назначение файла: рабочая память для будущих правок после аудита. Перед фиксом открывать этот файл, чтобы быстро понять, что было найдено, какие риски приоритетны и какие файлы смотреть первыми.

## Краткий вердикт

Проект уже выглядит заметно зрелее обычного прототипа: есть Clean Architecture/BLoC, GetIt DI, Firebase Auth/Firestore/Functions/FCM, AI через Cloud Function proxy, Health Connect/HealthKit, локализация, тесты, CI/CD, security scan, legal docs и большая база упражнений.

На момент аудита главными рисками были системные несостыковки между слоями: Firestore database id, недоделанная OfflineQueue и конфликт client writes с Firestore rules. Эти P0/P1-дефекты исправлены в коде и покрыты unit/callable tests. Firebase Emulator Suite добавлен; `deepseekProxy` получил fail-closed rate limiter. На realme RMX3853 / Android 16 проверены Health Connect, gallery Photo Picker, notifications, camera deny/lockout/Settings recovery, location deny/Settings recovery, Google re-login, Firebase reads, production AI chat, workout lifecycle, 3D/GIF и text scale 1.2/1.4. Локальный Linux/Docker CI gate на Flutter 3.38.5 подтверждён. Открытыми остаются внешние Firebase Console/Play/release checks и реальный GitHub Actions run.

Оценка состояния на момент первоначального аудита: примерно 7/10. Это историческая оценка, а не текущий пересчитанный рейтинг: большая часть найденных P0/P1-дефектов после аудита уже исправлена в коде, но внешние Firebase/release проверки еще не закрыты.

## Актуальный контекст worktree и истории изменений

До обновления этого файла 2026-07-10 `git status --short` был чистым. Audit-fixes и пользовательские изменения больше не являются незакоммиченным worktree: они вошли в историю git.

- `7202ac1` — основной пакет audit-fixes, Functions/Dart tests и пользовательское увеличение DeepSeek limits. В этот же коммит вошел `CODEX_AUDIT_FIX_CONTEXT.md`.
- `b2bf833` — private challenge invites, дополнительные SocialService tests, явный Firestore database id в `firebase.json` и загрузка покрытия в Codecov.
- `82862b4` — итоговый `dart format` по проекту.

Текущая ветка — `feature/replace-emoji-with-illustrated-icons`; до правки этого документа локальный HEAD `82862b4` совпадал с `origin/feature/replace-emoji-with-illustrated-icons`. По локальным remote refs `origin/master` остается на `04a8464`, поэтому audit-fixes еще не считаются подтвержденно влитыми в `master`.

После проходов 2026-07-10—2026-07-11 в worktree находятся незакоммиченные CI/Emulator/permissions/test/coverage изменения. Также остается историческая untracked `.codex-skill-staging/`; она не относится к приложению и в этот проход не изменялась.

Исторически до audit-fixes пользователь уже изменил:

- `functions/src/constants.ts`
- `lib/core/ai/base_client.dart`
- `lib/core/ai/services/plan_refinement_service.dart`

Суть пользовательских изменений: увеличены лимиты AI-запросов (`maxTokens`, длина сообщений). Они уже закоммичены, но по-прежнему не менять их смысл без явного запроса.

В `7202ac1` были зафиксированы следующие audit-fixes:

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

Удаление `REFACTORING_REPORT_V2.md` также уже находится в коммите `7202ac1`. Codex его не инициировал; не восстанавливать файл без явного запроса.

После основного audit-fix дополнительно сделано:

- Добавлены private challenge invites и UI для приглашений.
- Расширены `SocialService` и его unit-тесты для challenge flows.
- В `firebase.json` Firestore deployment явно привязан к database `fitnesbuster`.
- В CI добавлена загрузка очищенного `coverage/lcov.info` в Codecov и сохранены PR comment/job summary; GitHub coverage artifacts отключены, чтобы переполненная artifact quota не создавала ложные ошибки.
- В CI добавлены `npm test` и Firebase Emulator Suite gate; локально проходят 38 Functions unit/spec и 6 callable emulator tests.
- В emulator-прогоне найдена и исправлена несовместимость Firebase Admin v13: namespace-вызовы `admin.firestore.FieldValue/Timestamp` заменены modular imports.
- Добавлены локализованные camera/photo/notification rationale для 15 языков и недостающие iOS Camera/Photo Library purpose strings.
- Реализован fail-closed rate limiter для `deepseekProxy`: при инфраструктурной ошибке Firestore AI-прокси возвращает `UNAVAILABLE` вместо пропуска запроса без проверки лимита. Social endpoints (friends, challenges, feed) оставлены fail-open.
- Принято решение НЕ расширять OfflineQueue за пределы `user.aiPlans.sync`: Firestore SDK уже имеет встроенную offline persistence для прямых записей; вторая очередь создала бы риск дубликатов.

## Проверки, которые запускались

Актуально перепроверено 2026-07-11:

- `npm run build` в `functions`: успешно.
- `npm test` в `functions`: 38/38 tests успешно.
- `npm run test:emulator:exec` в `functions`: 6/6 callable integration tests успешно на Auth/Firestore/Functions emulators.
- `dart format --output=none --set-exit-if-changed lib test integration_test`: clean.
- `flutter analyze --no-fatal-infos --no-fatal-warnings lib test integration_test`: No issues found.
- Полный Linux/Docker Flutter 3.38.5 suite: 485 passed, 13 skipped; 498 зарегистрированных результатов.
- Исторический полный Windows suite: 474 passed, 13 skipped, 2 known Windows-only golden pixel diffs; 489 зарегистрированных результатов.
- Coverage: 4406/21391 = 20.60% non-generated lines (was 13.15%).
- Проверено 48 Dart `_test.dart` файлов; Functions считаются отдельно.
- Новые production-widget slices (`ImportOptionCard`, `ImportActionButton`, `ProfileStatsRow`, `ProfileCurrentProgram`) и injectable `HealthSyncBloc` targeted suite: 13/13 успешно.

Ранее успешно проверено после audit-fixes:

- `.\gradlew.bat :app:processDebugMainManifest --stacktrace` прошел успешно вне sandbox после удаления лишних permissions.
- `.\gradlew.bat :app:processDebugGoogleServices --stacktrace` прошел успешно после смены Android package id.
- `.\gradlew.bat :app:compileDebugKotlin --stacktrace` прошел успешно после переноса `MainActivity`.
- Контрольный `rg` не находит в проверяемых путях: namespace `admin.firestore().FieldValue/Timestamp`, неименованный `FirebaseFirestore.instance`, `BODY_SENSORS_BACKGROUND`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `TextScaler.noScaling`, `node-version: '20'`.

Статус проверок:

- В Docker image `ghcr.io/cirruslabs/flutter:3.38.5` оба golden PASS.
- На Windows renderer сохраняются ожидаемые pixel diffs: `dashboard.png` 0.77% / 3684 px и `workout_plan.png` 0.59% / 2836 px. Baseline с Windows не обновлять.
- Текущий реальный GitHub Actions run после последних коммитов не подтвержден: `gh` CLI не авторизован (`gh auth login`/`GH_TOKEN` отсутствуют), поэтому состояние Actions нельзя считать проверенным. Workflow запускается на push в `master` либо PR в `master`; текущая feature-ветка требует PR/merge для гарантированного CI run.
- В текущей среде Flutter/Dart команды надежно работают только через approved/escalated execution; это ограничение среды, а не проекта.

Итог по toolchain: format, analyze, Linux full Flutter suite/goldens, Functions unit/spec и callable emulator gate чистые. Предыдущее утверждение, что полный suite блокируют golden pixel diff, устарело: это Windows-only renderer diff.

## P0: Firestore database id mismatch — исправлено в коде

Статус: исправлено в коде, но нужен внешний smoke-check с реальным Firebase проектом.

Исходный риск: разные части приложения могли читать и писать в разные Firestore databases.

Факты:

- Основной DI регистрирует Firestore через `FirebaseFirestore.instanceFor(... databaseId: 'fitnesbuster')` в `lib/core/di/injection.dart`.
- `SocialService` теперь получает `FirebaseFirestore` через DI и использует тот же named database.
- Cloud Functions теперь используют `getFirestore(FIRESTORE_DATABASE_ID)`, где `FIRESTORE_DATABASE_ID = "fitnesbuster"`.
- Firestore trigger `fanoutActivityEvent` теперь явно указывает `database: FIRESTORE_DATABASE_ID`.
- `firebase.json` теперь также содержит `firestore.database: "fitnesbuster"` для deploy rules/indexes в ту же named database.

Что уже сделано:

- Добавлен `lib/core/constants/firebase_config.dart`.
- Добавлен `functions/src/firebaseConfig.ts`.
- `lib/core/di/injection.dart` больше не содержит hardcoded строку DB id.
- `functions/src/shared.ts` переведен с `admin.firestore()` на `getFirestore("fitnesbuster")`.
- `lib/core/services/social_service.dart` больше не использует `FirebaseFirestore.instance`.
- `functions/src/feed.ts` trigger слушает named database.
- `firebase.json` явно направляет Firestore rules/indexes deployment в `fitnesbuster`.

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

## P0: OfflineQueue — техническое ядро исправлено, расширение не требуется

Статус: исправлено, покрыто unit-тестами и закрыто. Принято продуктовое решение: очередь обслуживает исключительно `user.aiPlans.sync` и не расширяется на обычные Firestore-записи.

Исходный риск: механизм офлайн-синхронизации выглядел существующим, но фактически не исполнял операции типизированно.

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

Что еще можно доделать по продуктовой необходимости:

- Очередь покрывает только AI-plan sync и этого достаточно. Firestore SDK имеет встроенную offline persistence для всех прямых `doc.set()`/`collection.add()` — добавлять их в кастомную очередь не нужно во избежание двойного хранения и дубликатов. Расширение очереди целесообразно только для операций, где Firestore SDK не участвует напрямую (например, Health Connect → Firestore pipeline или собственный analytics backend).

Файлы:

- `lib/core/cache/offline_queue.dart`
- `lib/core/di/injection.dart`

## P1: publishActivity и Firestore rules — исправлено

Статус: исправлено, добавлен server path и validation.

Исходный риск: клиентская запись `publishActivity()` могла отклоняться rules, из-за чего social feed работал бы нестабильно.

Факты:

- `SocialService.publishActivity()` теперь вызывает callable `publishActivity`.
- `firestore.rules` оставляет прямую запись в `activity_events` закрытой и указывает на callable path.
- Callable `publishActivity` валидирует auth, `type`, размер/форму `data`, rate-limit и пишет через Admin SDK.
- Добавлены pure validation tests для `publishActivity`.

Что еще нужно доделать:

- Расширить allowed activity types при появлении новых событий.
- Callable auth/write/rate-limit path теперь покрыт Firebase Emulator Suite; при необходимости отдельно добавить client-SDK rules tests.

Файлы:

- `lib/core/services/social_service.dart`
- `lib/core/services/i_social_service.dart`
- `functions/src/feed.ts` или новый functions-файл
- `functions/src/feedValidation.ts`
- `functions/test/feedValidation.test.js`
- `functions/src/index.ts`
- `firestore.rules`

## P1: Node version mismatch в CI — исправлено

Статус: исправлено.

Исходный риск: локально/деплой требовали Node 22, а CI собирал на Node 20.

Факты:

- `functions/package.json` содержит `"engines": {"node": "22"}`.
- `.github/workflows/ci.yml` теперь использует `actions/setup-node` с `node-version: '22'`.

Что еще нужно доделать:

- Сам Node mismatch закрыт; остается проверить реальный GitHub Actions run после push/PR.
- Functions job теперь запускает и `npm test`, и `npm run test:emulator:exec`; локально оба gate подтверждены. Остается проверить реальный GitHub Actions run.

Файлы:

- `functions/package.json`
- `.github/workflows/ci.yml`
- возможно `.github/workflows/release.yml`/deploy workflow, если появится деплой functions.

## P1: AI retry и Firebase callable errors — исправлено

Статус: исправлено в `BaseClient`; mapping/retry classifier покрыты unit-тестами, а полный Flutter suite проходит за исключением двух несвязанных golden diffs.

Исходный риск: transient ошибки Firebase callable могли не ретраиться, хотя пользователь ожидает повтор.

Факты:

- `withRetry` в `lib/core/ai/network/retry_handler.dart` ловит только `AiException`.
- `BaseClient` вызывает Firebase callable `deepseekProxy`; реальные ошибки могут быть `FirebaseFunctionsException`.
- `BaseClient` теперь ловит `FirebaseFunctionsException` и маппит ее в `AiException` с `statusCode`.
- 400/401/403/429 не ретраятся; 500/503/504 остаются retryable через существующий `withRetry`.

Что еще нужно доделать:

- При желании расширить `AiException` типом ошибки, если UI должен различать rate limit/network/auth.

Файлы:

- `lib/core/ai/base_client.dart`
- `lib/core/ai/network/retry_handler.dart`
- `lib/core/ai/ai_exception.dart`

## P1: Cloud Functions tests — pure/spec и callable emulator готовы

Статус: закрыт основной test-infrastructure gap. Pure/spec tests покрывают validation/logic, а Firebase Emulator Suite проверяет реальные callable + Auth/Firestore взаимодействия.

Остающийся риск: внешний DeepSeek provider/Secret Manager не эмулируется; emulator test проверяет auth и validation до сетевого обращения. Production smoke-test AI endpoint по-прежнему нужен.

Что уже сделано:

- Добавлен `functions/package.json` script: `npm test`.
- Используется встроенный Node 22 `node:test`, без новых dev dependencies.
- Добавлен `functions/src/feedValidation.ts` как pure validation module.
- Добавлен `functions/test/feedValidation.test.js`: 5 тестов, проходят через `npm test`.
- Добавлен `functions/src/proxiesValidation.ts` и `functions/test/proxiesValidation.test.js`: 7 тестов на `deepseekProxy` payload/limits, проходят через `npm test`.
- Добавлены `functions/src/friendsValidation.ts`, `functions/src/challengesValidation.ts`, `functions/src/rateLimitLogic.ts`, `functions/src/accountCleanupPlan.ts` и соответствующие tests. Всего `npm test`: 38/38.
- `rateLimitFailureAction` покрывает три failure-policy ветки: contention → deny, DeepSeek infrastructure → throw, social infrastructure → allow.
- `npm run build` и `npm test` повторно пройдены 2026-07-11.
- В `firebase.json` настроены Auth 9099, Firestore 8080, Functions 5001 и named database `fitnesbuster`.
- Добавлен `functions/test/emulator/callables.test.js`: 6 последовательных demo-project сценариев.
- Проверены `publishActivity` auth/write, duplicate-safe friends lifecycle, private challenge invite/join/leave/delete permissions, `deepseekProxy` auth/validation, concurrent rate limit 30/32 и полный `deleteAccount` cleanup вместе с Auth user.
- `.github/workflows/ci.yml` теперь запускает 38 unit/spec tests и 6 emulator tests на Node 22 + Java 21 + Firebase CLI 15.22.0.
- Emulator run выявил реальные runtime-ошибки modular Firebase Admin v13; все `admin.firestore.FieldValue/Timestamp` заменены поддерживаемыми imports и повторный run прошел 6/6.

Что еще можно покрыть:

- `deepseekProxy`: сетевые/Secret Manager/provider response сценарии через управляемый mock transport; не обращаться к платному production API из CI.
- Добавить Firestore security-rules tests через client SDK для прямых client reads/writes; текущие callable tests намеренно выполняют серверный путь через Admin SDK.
- При расширении challenges добавить отдельные transaction race cases для одновременного join/leave.

Файлы:

- `functions/src/*.ts`
- `functions/test/*.test.js`
- `functions/test/emulator/callables.test.js`
- `firebase.json`

## P2: Accessibility/Text scaling — частично закрыто

Статус: исправлено в коде, добавлены точечные overflow fixes, нужна визуальная проверка экранов.

Исходный риск: приложение полностью отключало системное масштабирование текста. Это устранено, но текущий clamp все еще ограничивает максимальный scale значением 1.4.

Факт:

- `main.dart` больше не использует `TextScaler.noScaling`.
- Теперь используется `MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4)`.

Что еще нужно доделать:

- Проверить ключевые экраны при фактически поддерживаемых 1.2x и 1.4x.
- Системный scale 1.6x сейчас будет ограничен до 1.4x. Если нужна настоящая поддержка 1.6x, сначала поднять/убрать clamp, затем пройтись по плотным карточкам/табам и исправить layout overflow.
- Отдельно визуально ревьюить golden diffs dashboard/workout_plan перед обновлением эталонов.

Файл:

- `lib/main.dart`

## P2: Android package id и Firebase config — настроено

Статус: package id, официальный Firebase Android app config, локальные debug/release SHA и Google Auth provider настроены. Реальный Google sign-out/sign-in PASS на Android 16 (2026-07-11); Play App Signing SHA потребуется отдельно для сборок, распространяемых через Play Console.

Исходный риск: перед публикацией пришлось бы менять package id, что лучше было сделать до реального релиза.

Факты:

- `android/app/build.gradle.kts`: `namespace = "com.fitnesbuster.app"`.
- `android/app/build.gradle.kts`: `applicationId = "com.fitnesbuster.app"`.
- `MainActivity.kt` перенесен в `android/app/src/main/kotlin/com/fitnesbuster/app`.
- MethodChannel обновлен на `com.fitnesbuster.app/share`.
- В Firebase Console подтвержден Android app `com.fitnesbuster.app`.
- Официальный `android/app/google-services.json` заменен в проекте и содержит Firebase Android app id `1:184541768053:android:c2e5c53ee52e6c133c4b3c`.
- В `google-services.json` присутствуют Android OAuth clients для release SHA-1 `e90c4127...` и debug SHA-1 `b54dde5f...`, оба с package `com.fitnesbuster.app`, а также Web OAuth client.
- В Firebase Console добавлены debug/release SHA-1 и SHA-256 fingerprints.
- Firebase Authentication: Google provider включен, Project support email настроен; Email/Password и Phone providers также включены.
- `:app:processDebugGoogleServices` и `:app:compileDebugKotlin` прошли успешно после обновления package/config.

Что уже не требуется:

- Повторно генерировать `google-services.json` для локальных debug/release сборок без изменения Firebase app или SHA.
- Повторно включать Google provider или добавлять уже подтвержденные debug/release fingerprints.

Что еще нужно проверить:

- В Firebase Console подтвердить появление/обновление уже проверенного на устройстве пользователя в Authentication → Users и профиль в Firestore database `fitnesbuster` → `users`.
- Реальный sign-out/sign-in и чтение существующих profile/workout данных выполнены 2026-07-11 на Android 16.
- Перед распространением через Play Console добавить в Firebase SHA-1/SHA-256 из Play App Signing и подтвердить package `com.fitnesbuster.app` в Play Console. Upload/release keystore SHA не заменяет Play App Signing SHA для установленной из Google Play сборки.

Файлы:

- `android/app/build.gradle.kts`
- `android/app/google-services.json`
- Firebase console settings вне репозитория.

## P2: Permissions слишком широкие

Статус: код и manifests статически приведены в соответствие с фактическими flows; внешний Store/Data Safety policy review еще нужен.

Риск: Store review и доверие пользователя. Особенно чувствительны background sensors/location и health permissions.

Факты:

- Android все еще запрашивает camera, fine/coarse location, много Health Connect read permissions, post notifications.
- Android `BODY_SENSORS_BACKGROUND` убран.
- Android `ACTIVITY_RECOGNITION` и `BODY_SENSORS` убраны, так как код читает метрики через scoped Health Connect permissions.
- iOS `NSLocationAlwaysAndWhenInUseUsageDescription` убран; остался `NSLocationWhenInUseUsageDescription`.
- Каждый Android Health Connect READ scope соответствует типу в `HealthConnectService._types`; лишние широкие sensor/activity permissions не найдены.
- Добавлены недостающие iOS `NSCameraUsageDescription` и `NSPhotoLibraryUsageDescription`.
- Camera/photo/notification rationale добавлены для всех 15 локалей и покрыты translation parity + widget tests.
- Barcode/QR scanner, avatar и progress photo flows показывают rationale до системного запроса.
- FCM больше не запрашивает permission автоматически при sign-in: background init регистрирует token только при уже выданном разрешении; явный prompt вызывается после rationale из notification settings.
- `HealthSyncScreen` теперь тестируем через injected BLoC; loading/loaded/not-installed/lifecycle состояния покрыты widget tests.
- 2026-07-11 выполнена реальная проверка на realme RMX3853, Android 16/API 36, Health Connect `2026.05.14.00.release`.
- Официальный Health Connect Toolbox 2.3.3 подтвердил steps, active/total calories, HR/resting HR, HRV RMSSD, respiratory rate, weight, height, distance, hydration, sleep и workout; после проверки синтетические records и Toolbox удалены.
- Device test обнаружил ложное состояние «Синхронизировано: 0» после полного отзыва/lockout. Исправлено: per-type permission refresh, изолированное чтение типов, типизированная denied error и recovery UI с переходом в Health Connect Settings.
- Partial revoke HRV сохраняет остальные метрики; полный revoke показывает access-denied UI; повторная выдача 13 разрешений восстанавливает sync без перезапуска.
- Device probe подтвердил downstream: AI DTO получил steps/weight/HRV, Dashboard/Recovery показал score 52, HRV 58 ms и resting HR 58 bpm.
- Добавлены 6 regression tests; сфокусированный health suite 39/39 и analyzer `No issues found`.
- Gallery rationale открыл Android Photo Picker без broad media permission; cancel безопасно вернул в приложение.
- Notifications прошли rationale, два denial, `USER_FIXED` и Settings recovery до `POST_NOTIFICATIONS granted=true`. Найден и исправлен ложный success при denied callback; sheet теперь остаётся открытым и предлагает Settings.
- Barcode scanner после camera `USER_FIXED` оставался пустым. Теперь permission запрашивается явно, показывается recovery UI, а status обновляется при возврате из Settings. Добавлен widget regression. На release-signed APK подтверждены два отказа, `USER_FIXED`, переход в App Info, выдача camera permission и автоматическое восстановление scanner без перезапуска.
- Location device probe закрыт на realme RMX3853 / Android 16: первый системный отказ `Запретить` показал error/manual fallback, recovery UI открыл Android App Info, через Settings UI выдано `Разрешить только во время использования приложения`, итог `LocationPermission.whileInUse`. На этой прошивке повторный location request не даёт стабильный `deniedForever`, поэтому production UX усилен: Settings action показывается уже после обычного denial.

### Review исправлений DeepSeek от 11.07.2026

Переданный текстовый отчёт сверен с реальным worktree. Заявленные private-route guard, Auth reload/sign-out, принудительный Google account picker, поздняя Auth-синхронизация онбординга, overlay layout, единый hydrated Auth emit, Hive recovery, Firestore merge и location Settings action присутствуют в коде.

После review реализация усилена:

- удалён глобальный `onboarding_completed` fallback, небезопасный для нескольких UID на одном устройстве;
- email и Google login возвращают entity с загруженным Firestore profile, исключая промежуточный redirect в onboarding;
- неподтверждённый сетевой сбой `deleteAccount` больше не считается успешным cloud deletion, при этом локальный sign-out выполняется всегда;
- Hive cipher recovery согласован для cache, offline queue и dead-letter boxes;
- Mockito mocks регенерированы после изменения `IAuthRepository`.

Regression-набор auth/router/onboarding/cache/permissions прошёл 84/84; дополнительный focused suite после location-фикса прошёл 67/67; `flutter analyze --no-fatal-infos --no-fatal-warnings lib test integration_test` — `No issues found`. Location integration probe прошёл 1/1 на устройстве. Release pipeline исправлен и подтверждён: `flutter build apk --release --no-pub` успешно собирает `build/app/outputs/flutter-apk/app-release.apk`, `flutter build appbundle --release --no-pub` — `build/app/outputs/bundle/release/app-release.aab`. Для generated-state quirk Flutter 3.38.5, где dev `integration_test` попадал в release `GeneratedPluginRegistrant`, добавлен Gradle strip-task перед release compile; production classpath остаётся без тестового plugin.

На свежей release-установке подтверждены системный Google `AccountPickerActivity` и загрузка существующего Firestore-профиля непосредственно в dashboard без промежуточного onboarding redirect.

Что еще нужно доделать:

- Проверить Health Connect policy и Google Play Data safety.
- Gallery, notifications, camera, location и Health Connect device flows закрыты на Android. Для location классический второй deny/`deniedForever` на RMX3853 не воспроизводится стабильно, поэтому закрыт более надёжный пользовательский recovery после обычного denial.
- Продуктово решить, нужно ли запрашивать весь Health Connect набор сразу или часть метрик сделать ленивой/опциональной.
- Для международного iOS release добавить локализованные `InfoPlist.strings`: текущие native purpose strings в `Info.plist` только на русском, хотя in-app rationale локализован на 15 языков.
- Локализовать сам Health Sync screen: его rationale/status/action copy пока hardcoded на русском; 15-язычная локализация подтверждена только для camera/photo/notification и location rationale.

Файлы:

- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

## P2: Coverage и тесты

Статус: существенно усилены risk-boundary tests и реальный production-widget coverage. Общий non-generated показатель вырос с 13.15% до 20.60%.

Факты:

- В текущем дереве 48 Dart `_test.dart` файлов.
- Актуальный полный Linux/Docker Flutter 3.38.5 run: 485 passed, 13 skipped; всего 498 зарегистрированных результатов.
- Golden tests включены в общий `flutter test` и CI/release workflows; Linux baselines проходят, Windows renderer даёт ожидаемые 0.77%/0.59% pixel diffs.
- Локальный `coverage/lcov.info`: 4406/21391, 20.60% line coverage по non-generated строкам.
- В CI добавлены Codecov upload, PR coverage comment и job summary. GitHub coverage artifacts отключены после подтверждённого исчерпания storage quota; Codecov остаётся источником полного отчёта.
- `docs/CI_CD.md`, `docs/RELEASE_SMOKE_CHECKLIST.md` и CI labels синхронизированы с baseline 498 / 38 / 6.
- `docs/TEST_COVERAGE_PRIORITIES.md` — приоритеты по непокрытым risk boundaries.

Что сделано:

- **SocialService**: добавлены тесты для всех 6 Firestore streams (friendsStream, incomingRequestsStream, feedStream, publicChallengesStream, myChallengesStream, challengeLeaderboardStream) — проверка пустых uid, маппинга snapshot→модель. Добавлены тесты error propagation для sendFriendRequest, createChallenge, removeFriend. С `@GenerateNiceMocks`.
- **Auth redirect**: 18 тестов вместо 6 — покрыты все комбинации: public routes (login/register), social routes (feed/friends), onboarding sub-routes, verifyEmail переходы, edge cases без redirect loop.
- **HiveCache**: новый файл `test/core/cache/hive_cache_test.dart`, 23 теста. Покрыты AI-планы (save/get/update), cache metadata (isFresh/getCacheTime/hasAiPlans), test-week flag, per-user изоляция, chat history (включая malformed JSON), sync-флаг (setNeedsSync/clearSyncNeeded).
- **Social/UI**: production screens feed/friends/challenges и profile sheets покрыты empty/data/tab scenarios; фактическое покрытие составляет 57.81%, 51.99%, 33.33% и 31.67% соответственно.
- **Health Sync**: экран теперь принимает injected `HealthSyncBloc`; покрыты loading, loaded metrics, not-installed UI и ownership. Фактическое покрытие 89.05%.
- **Workout models/session**: `WorkoutDay` — 65.52%, `WorkoutSession` — 62.96%.
- **Проверка качества тестов**: исходные Priority 3 тесты копировали private widgets в test-файлы и не проверяли production-код. Они заменены тестами реальных `ImportOptionCard`, `ImportActionButton`, `ProfileStatsRow`, `ProfileCurrentProgram`. Это подняло production coverage import/profile до 8.62%/8.60% и выявило реальный баг: loading-кнопка импорта оставалась кликабельной.

Что делать:

- Priority 1/2 существенно продвинуты, но не считать все UI priorities полностью закрытыми.
- `workout_execution_screen.dart` (0/739) и `workout_session_screen.dart` (0/483): сначала внедрить clock/timer, TTS и wakelock adapters, затем тестировать реальные phase/lifecycle transitions.
- Продолжить полные workflows `import_workout_sheet.dart` (8.62%), `profile_screen.dart` (8.60%) и actual GoRouter integration (pure redirect helper уже покрыт).
- Добавить client-SDK Firestore rules tests и DeepSeek mock-transport/secret/network tests.

## Дополнительные наблюдения

AI и безопасность:

- Хорошо: DeepSeek key не в клиенте, используется Secret в Functions.
- Хорошо: request auth и rate limit есть.
- Защита от transaction contention уже исправлена: Firestore `ABORTED` обрабатывается fail-closed и покрыт pure test.
- Rate limiter теперь имеет двойную стратегию: social endpoints (friends, challenges, feed) — fail-open при инфраструктурной ошибке; `deepseekProxy` — fail-closed с `HttpsError("unavailable", …)`, чтобы при падении Firestore платные AI-запросы не уходили без проверки лимита.
- Недавние изменения увеличивают `maxTokens` и message length. Это может быть нужно для больших планов, но растит стоимость, latency и нагрузку.

Локализация:

- Поддерживается много языков, включая RTL для Arabic.
- Legal docs пока Russian only, что нормально для РФ-правовой базы, но если приложение международное, нужно решить стратегию legal localization.

Ассеты:

- GIF раздаются через Firebase Hosting CDN, это хорошо.
- В workspace локально лежат большие assets/public/build, но Git в основном их игнорирует. Следить, чтобы тяжелые исходники не попали в репозиторий.

Firebase client config:

- `android/app/google-services.json` и `lib/firebase_options.dart` закоммичены. Это нормально для Firebase client config, но API key нужно ограничить в Google Cloud Console по package/bundle/SHA и разрешенным API.
- Официальный Firebase Android config для `com.fitnesbuster.app`, debug/release SHA-1/SHA-256 и Google Auth provider подтверждены. Отдельно остаются runtime Google login smoke-test и будущие Play App Signing fingerprints.

## Рекомендуемый порядок будущих фиксов

1. В Firebase Console подтвердить runtime-проверенного Google-пользователя, target project и профиль в named Firestore database `fitnesbuster`.
2. Прогнать social/challenges/profile smoke-check с реальным Firebase проектом.
3. Открыть/обновить PR feature-ветки в `master` и подтвердить реальный GitHub Actions run: Flutter 498 результатов, Functions 38 unit/spec + 6 emulator, Codecov upload.
4. Не обновлять Windows golden diffs `dashboard.png`/`workout_plan.png`; Linux/Flutter 3.38.5 baselines подтверждены и остаются источником истины.
5. Заполнить Google Play Data safety / Health Connect policy declarations. Android permission deny/settings flows для Health Connect, gallery, notifications, camera и location закрыты на realme RMX3853 / Android 16.
6. Проверить ключевые экраны при text scaling 1.2x/1.4x; отдельно решить, нужна ли настоящая поддержка 1.6x вместо текущего clamp.
7. Подготовить test seams и тесты для `workout_execution_screen.dart` (0/739) и `workout_session_screen.dart` (0/483): clock/timer, FlutterTts и Wakelock adapters, phase/lifecycle transitions.
8. Продолжить реальные workflow tests для import/profile/router; не копировать production widgets в test-файлы.
9. Добавить mock-transport tests DeepSeek provider/secret/network и client-SDK Firestore rules tests.
10. Для международного iOS release добавить локализованные `InfoPlist.strings` purpose descriptions.
11. Перенести hardcoded Health Sync copy в `AppLocalizations` для всех поддерживаемых языков.
12. Перед Play-distributed release добавить Play App Signing SHA-1/SHA-256 в Firebase и подтвердить package в Play Console.

## Быстрые команды для повторной проверки

```powershell
git status --short
Push-Location functions
npm run build
npm test
npm run test:emulator:exec
Pop-Location
flutter analyze --no-fatal-infos --no-fatal-warnings lib test
dart format --output=none --set-exit-if-changed lib test
flutter test --coverage --reporter=expanded
Push-Location android
.\gradlew.bat :app:processDebugGoogleServices :app:processDebugMainManifest :app:compileDebugKotlin --stacktrace
Pop-Location
```

Если Flutter-команды снова зависают локально, проверять в CI или отдельной чистой Flutter среде.
