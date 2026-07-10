# CI/CD

Документация по инженерной инфраструктуре проекта FitnesBuster: GitHub Actions workflows, секреты, релизы, покрытие тестами, безопасность.

## Обзор workflow

| Файл | Триггер | Что делает |
|---|---|---|
| [`ci.yml`](../.github/workflows/ci.yml) | push/PR → `master` | `dart format`, `flutter analyze`, полный Flutter suite (текущий baseline: 489 результатов), coverage/Codecov, Cloud Functions build + 38 unit/spec тестов + 6 callable-тестов в Auth/Firestore/Functions emulators |
| [`build.yml`](../.github/workflows/build.yml) | push/PR → `master`, ручной запуск | Собирает APK и AAB (debug-подпись, для внутреннего тестирования); на push/manual сохраняет их как неблокирующие build-артефакты на 3 дня, на PR только проверяет сборку |
| [`release.yml`](../.github/workflows/release.yml) | push тега `v*.*.*` **или** ручной запуск (`workflow_dispatch`) | Прогоняет `flutter analyze` + `flutter test` как гейт качества, собирает **подписанные боевым ключом** APK/AAB, публикует GitHub Release с артефактами и авто-changelog, шлёт уведомление в Telegram |
| [`security.yml`](../.github/workflows/security.yml) | PR → `master`, push → `master`, еженедельно (пн 06:00 UTC), ручной запуск | Сканирует `pubspec.lock` и `functions/package-lock.json` через OSV-Scanner на известные CVE, роняет job при находках, шлёт уведомление в Telegram |
| [`dependabot.yml`](../.github/dependabot.yml) | еженедельно (пн) | Автоматические PR на обновление зависимостей: `pub`, `npm` (`/functions`), `github-actions` |

Переиспользуемый компонент: [`.github/actions/telegram-notify`](../.github/actions/telegram-notify/action.yml) — composite action, единая точка отправки уведомлений в Telegram, используется в `ci.yml`, `release.yml`, `security.yml`.

## Требуемые секреты (Settings → Secrets and variables → Actions)

| Секрет | Используется в | Обязателен для |
|---|---|---|
| `TELEGRAM_BOT_TOKEN` | `ci.yml`, `release.yml`, `security.yml` | Уведомлений в Telegram |
| `TELEGRAM_CHAT_ID` | `ci.yml`, `release.yml`, `security.yml` | Уведомлений в Telegram |
| `ANDROID_KEYSTORE_BASE64` | `release.yml` | Подписанной release-сборки APK/AAB |
| `ANDROID_KEYSTORE_PASSWORD` | `release.yml` | Подписанной release-сборки |
| `ANDROID_KEY_ALIAS` | `release.yml` | Подписанной release-сборки |
| `ANDROID_KEY_PASSWORD` | `release.yml` | Подписанной release-сборки |
| `CODECOV_TOKEN` | `ci.yml` | Загрузки покрытия тестами в Codecov |

`GITHUB_TOKEN` для комментария с покрытием в PR создаётся GitHub автоматически на каждый workflow run — добавлять его вручную не нужно.

Без Telegram-секретов `ci.yml`/`security.yml` всё равно работают (шаги уведомления молча падают только на `failure()` веток — не блокируют пайплайн). Без `CODECOV_TOKEN` шаг загрузки покрытия в Codecov будет пропущен, но PR-комментарий и job summary останутся. `release.yml` без keystore-секретов не сможет собрать подписанный релиз.

### Как подключить Codecov

1. Откройте Codecov → нужный репозиторий → **Settings** → **General** → **Repository Upload Token**.
2. Скопируйте токен.
3. Добавьте его в GitHub: **Settings** → **Secrets and variables** → **Actions** → **New repository secret** → `CODECOV_TOKEN`.
4. Запустите `CI` заново через новый push или вручную перезапустите failed/skipped workflow run.

В [`ci.yml`](../.github/workflows/ci.yml) загружается уже очищенный `coverage/lcov.info`: сгенерированный Dart-код (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`) предварительно исключается через `lcov --remove`.

## Firebase Emulator Suite

Callable integration tests используют demo project `demo-fitnesbuster` и не обращаются к production Firebase. Конфигурация портов хранится в `firebase.json`: Auth `9099`, Firestore `8080`, Functions `5001`; тесты работают с named database `fitnesbuster`.

```powershell
cd functions
npm test
npm run test:emulator:exec
```

`npm test` запускает 38 pure/unit/spec тестов. Три из них фиксируют failure policy rate limiter: contention всегда deny, инфраструктурная ошибка DeepSeek fail-closed, а social endpoints сохраняют fail-open. `npm run test:emulator:exec` собирает TypeScript, поднимает три эмулятора и запускает 6 последовательных callable-сценариев: `publishActivity`, friends lifecycle, private challenge invite/join/leave/delete, `deepseekProxy` auth/validation, concurrent rate limit и `deleteAccount` cleanup. Для локального запуска нужны Node 22, Java 21+ и Firebase CLI 15.22.0; CI закрепляет эти версии.

### Как создать Telegram-бота и получить chat_id

1. Откройте Telegram, найдите **@BotFather**, отправьте `/newbot` и следуйте инструкциям (имя, username). BotFather выдаст токен вида `123456789:AAExxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` — это `TELEGRAM_BOT_TOKEN`.
2. Напишите созданному боту любое сообщение (или добавьте его в нужный чат/канал).
3. Чтобы узнать `chat_id`:
   - для личного чата — напишите боту **@userinfobot**, он пришлёт ваш числовой id;
   - для группы/канала — добавьте бота в группу, затем откройте `https://api.telegram.org/bot<TOKEN>/getUpdates` в браузере после отправки любого сообщения в группу и найдите `"chat":{"id": ...}` в ответе.
4. Добавьте оба значения в GitHub: Settings → Secrets and variables → Actions → New repository secret → `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`.

### Как сгенерировать release keystore для Android

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Сохраните `upload-keystore.jks`, пароль хранилища и пароль ключа в надёжном месте (менеджер паролей) — при утере ключа обновить приложение в Google Play под тем же `applicationId` будет невозможно.

Закодируйте файл в base64 для хранения в GitHub Secrets:

```powershell
# Windows / PowerShell
certutil -encode upload-keystore.jks keystore-base64.txt
```

```bash
# Linux / macOS
base64 -i upload-keystore.jks -o keystore-base64.txt
```

Добавьте в GitHub Secrets:
- `ANDROID_KEYSTORE_BASE64` — содержимое `keystore-base64.txt`
- `ANDROID_KEYSTORE_PASSWORD` — пароль хранилища
- `ANDROID_KEY_ALIAS` — `upload` (или ваш alias)
- `ANDROID_KEY_PASSWORD` — пароль ключа

Для **локальной** release-сборки скопируйте `android/key.properties.example` → `android/key.properties` и заполните теми же значениями (файл в `.gitignore`, не коммитится).

## Как выпустить релиз

**Вариант 1 — через git-тег:**

```bash
git tag v1.2.0
git push origin v1.2.0
```

**Вариант 2 — вручную:** вкладка **Actions** → workflow **Release** → **Run workflow** → указать версию (например `1.2.0`, без `v`). Workflow сам создаст и запушит тег `v1.2.0`.

В обоих случаях: `flutter analyze` + все тесты должны пройти, иначе релиз не соберётся. По завершении в **Releases** появится запись с `app-release.apk`, `app-release.aab` и автосгенерированным списком изменений с момента предыдущего тега; в Telegram придёт уведомление со ссылкой.

## Отчёты о покрытии тестами

Покрытие публикуется в Codecov и дополнительно остаётся внутри GitHub:

- **Codecov** — шаг `codecov/codecov-action@v5` загружает очищенный `coverage/lcov.info` с флагом `flutter`
- **Комментарий в PR** — на каждый PR бот ([`zgosalvez/github-actions-report-lcov`](https://github.com/zgosalvez/github-actions-report-lcov)) публикует % покрытия и таблицу по файлам, обновляя один и тот же комментарий при новых пушах
- **Job summary** — краткая сводка `lcov --summary` видна на вкладке Summary каждого workflow run
- GitHub coverage artifacts отключены: отчёт доступен в Codecov, PR-комментарии и job summary, поэтому исчерпание Actions artifact quota не создаёт ложные ошибки CI.

Из покрытия исключён сгенерированный код (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`) — он не отражает реальное качество тестирования.

Локальный verified baseline 2026-07-11: 4406/21391 non-generated lines, 20.60%. Windows: 474 passed, 13 skipped, 2 known golden pixel diffs. Реальный Actions run после текущих изменений ещё не подтверждён; ожидаемый Linux baseline — 476 passed и 13 skipped, если tracked goldens остаются валидны.

## Известные ограничения

- ~~Golden-тесты исключены из CI~~ — **исправлено.** Настоящая причина зависания (10-минутный таймаут на `DashboardScreen`/`WorkoutPlanScreen`, воспроизводилось и локально, и на `ubuntu-latest`) не имела отношения к 3D-вьюеру/WebView: оба теста вызывали `bloc.close()` для блоков, всё ещё предоставленных смонтированному `BlocProvider.value`. `BlocProvider` держит собственную подписку на `bloc.stream`, а `Bloc.close()` дожидается закрытия этого стрима — что требует отмены всех подписчиков. Так как дерево виджетов ни разу не размонтировалось перед вызовом `close()`, эта внутренняя подписка никогда не отменялась, и `close()` не завершался. Минимальный репро: `bloc.stream.listen((_) {})` без отмены + `bloc.close()` — зависает даже без единого виджета. Исправление — не вызывать `close()` для блоков, которые всё ещё "живут" в смонтированном дереве (`GetIt.reset()` в `tearDownAll` — достаточная очистка для одного теста в файле). Golden-тесты снова включены в `ci.yml`/`release.yml`, оба проходят за ~0.1с.
- Linux PNG-файлы в `test/golden/goldens` являются эталоном. На текущем Windows renderer полный локальный run даёт два известных pixel diff (`dashboard` 0.77%, `workout_plan` 0.59%); не обновлять baselines на Windows без визуального review. Проверка в `ubuntu-latest` остаётся release gate.
- `build.yml` собирает APK/AAB с **debug-подписью** — такие артефакты годятся для внутреннего тестирования, но не для публикации в Google Play. Боевая подпись — только в `release.yml`.
- Build artifacts создаются только на push в `master` и при ручном запуске, хранятся 3 дня и не блокируют успешную сборку при исчерпанной storage quota. PR проверяет сборку APK/AAB без загрузки тяжёлых файлов.
- **`security.yml` не загружает SARIF в Security → Code scanning и не запускает `dependency-review-action`.** Обе функции — часть GitHub Advanced Security, которая для приватных репозиториев платная (репозиторий `fitnesbuster` приватный). Прямой OSV scanner action сканирует `pubspec.lock` и `functions/package-lock.json`, сохраняет строгий ненулевой exit code при известных CVE и не использует GitHub artifact storage. Результат виден в логе run'а. Если репозиторий станет публичным или появится лицензия GHAS, можно вернуть reusable workflow с `upload-sarif: true` и job `dependency-review`.
