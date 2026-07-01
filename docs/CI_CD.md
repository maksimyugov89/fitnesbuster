# CI/CD

Документация по инженерной инфраструктуре проекта FitnesBuster: GitHub Actions workflows, секреты, релизы, покрытие тестами, безопасность.

## Обзор workflow

| Файл | Триггер | Что делает |
|---|---|---|
| [`ci.yml`](../.github/workflows/ci.yml) | push/PR → `master` | `dart format`, `flutter analyze`, все 337 тестов (`flutter test --coverage`), загрузка покрытия в Codecov + артефакт `lcov.info`, сборка Cloud Functions (`npm run build`) |
| [`build.yml`](../.github/workflows/build.yml) | push/PR → `master`, ручной запуск | Собирает APK и AAB (debug-подпись, для внутреннего тестирования) и сохраняет их как build-артефакты на 14 дней |
| [`release.yml`](../.github/workflows/release.yml) | push тега `v*.*.*` **или** ручной запуск (`workflow_dispatch`) | Прогоняет `flutter analyze` + `flutter test` как гейт качества, собирает **подписанные боевым ключом** APK/AAB, публикует GitHub Release с артефактами и авто-changelog, шлёт уведомление в Telegram |
| [`security.yml`](../.github/workflows/security.yml) | PR → `master`, push → `master`, еженедельно (пн 06:00 UTC), ручной запуск | Сканирует `pubspec.lock` и `functions/package-lock.json` через OSV-Scanner (результаты — во вкладке Security → Code scanning), проверяет diff зависимостей в PR (`dependency-review-action`), шлёт уведомление в Telegram при найденных уязвимостях |
| [`dependabot.yml`](../.github/dependabot.yml) | еженедельно (пн) | Автоматические PR на обновление зависимостей: `pub`, `npm` (`/functions`), `github-actions` |

Переиспользуемый компонент: [`.github/actions/telegram-notify`](../.github/actions/telegram-notify/action.yml) — composite action, единая точка отправки уведомлений в Telegram, используется в `ci.yml`, `release.yml`, `security.yml`.

## Требуемые секреты (Settings → Secrets and variables → Actions)

| Секрет | Используется в | Обязателен для |
|---|---|---|
| `CODECOV_TOKEN` | `ci.yml` | Загрузки отчёта покрытия в Codecov |
| `TELEGRAM_BOT_TOKEN` | `ci.yml`, `release.yml`, `security.yml` | Уведомлений в Telegram |
| `TELEGRAM_CHAT_ID` | `ci.yml`, `release.yml`, `security.yml` | Уведомлений в Telegram |
| `ANDROID_KEYSTORE_BASE64` | `release.yml` | Подписанной release-сборки APK/AAB |
| `ANDROID_KEYSTORE_PASSWORD` | `release.yml` | Подписанной release-сборки |
| `ANDROID_KEY_ALIAS` | `release.yml` | Подписанной release-сборки |
| `ANDROID_KEY_PASSWORD` | `release.yml` | Подписанной release-сборки |

Без этих секретов `ci.yml` и `build.yml` всё равно работают (Codecov просто пропускает загрузку, Telegram-шаги молча падают только на `failure()` веток — не блокируют пайплайн). `release.yml` без keystore-секретов не сможет собрать подписанный релиз.

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

### Как получить Codecov token

1. Зайдите на [codecov.io](https://codecov.io), авторизуйтесь через GitHub, добавьте репозиторий `maksimyugov89/fitnesbuster`.
2. Скопируйте `Repository Upload Token` со страницы настроек репозитория.
3. Добавьте как `CODECOV_TOKEN` в GitHub Secrets. Для публичных репозиториев Codecov принимает загрузки и без токена, но с ним отчёты стабильнее (нет rate limit).

## Как выпустить релиз

**Вариант 1 — через git-тег:**

```bash
git tag v1.2.0
git push origin v1.2.0
```

**Вариант 2 — вручную:** вкладка **Actions** → workflow **Release** → **Run workflow** → указать версию (например `1.2.0`, без `v`). Workflow сам создаст и запушит тег `v1.2.0`.

В обоих случаях: `flutter analyze` + все тесты должны пройти, иначе релиз не соберётся. По завершении в **Releases** появится запись с `app-release.apk`, `app-release.aab` и автосгенерированным списком изменений с момента предыдущего тега; в Telegram придёт уведомление со ссылкой.

## Отчёты о покрытии тестами

- **Codecov dashboard** — https://codecov.io/gh/maksimyugov89/fitnesbuster (графики, история, дифф покрытия в PR)
- **Artifact `coverage-report`** — сырой `lcov.info` на вкладке каждого workflow run в Actions (14 дней), можно открыть локально: `genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html`

Из покрытия исключён сгенерированный код (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`) — он не отражает реальное качество тестирования.

## Известные ограничения

- **Golden-тесты** (`test/golden/`) сравнивают точный рендер пикселей и чувствительны к ОС/версии шрифтов. Если эталонные изображения сгенерированы не на `ubuntu-latest`, возможны ложные падения в CI — при таком расхождении перегенерируйте голдены на Linux (`flutter test --update-goldens test/golden/`) и закоммитьте заново.
- `build.yml` собирает APK/AAB с **debug-подписью** — такие артефакты годятся для внутреннего тестирования, но не для публикации в Google Play. Боевая подпись — только в `release.yml`.
