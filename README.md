<p align="center">
  <img src="assets/icons/icon.png" width="120" alt="FitnesBuster logo">
</p>

<p align="center">
  <strong>Издатель:</strong> Югов Максим Александрович &nbsp;|&nbsp; <strong>Email:</strong> maksim.yugov.89@gmail.com
</p>

# FitnesBuster

[![CI](https://github.com/maksimyugov89/fitnesbuster/actions/workflows/ci.yml/badge.svg)](https://github.com/maksimyugov89/fitnesbuster/actions/workflows/ci.yml)
[![Security](https://github.com/maksimyugov89/fitnesbuster/actions/workflows/security.yml/badge.svg)](https://github.com/maksimyugov89/fitnesbuster/actions/workflows/security.yml)

FitnesBuster — мобильное Flutter-приложение для персональных тренировок, питания и контроля восстановления. Основная поддерживаемая платформа проекта — Android 8.0+ (API 26). Приложение использует Firebase для аутентификации и серверных функций, DeepSeek через защищённую Cloud Function, Google Health Connect для данных здоровья и Hive/SharedPreferences для локального хранения.

Текущая версия: `1.0.0+1`.

## Скриншоты

|![Screenshot 0](assets/skrin/Screenshot_0.jpg)|![Screenshot 1](assets/skrin/Screenshot_1.jpg)|![Screenshot 2](assets/skrin/Screenshot_2.jpg)|![Screenshot 3](assets/skrin/Screenshot_3.jpg)|
|---|---|---|---|

|![Screenshot 4](assets/skrin/Screenshot_4.jpg)|![Screenshot 5](assets/skrin/Screenshot_5.jpg)|![Screenshot 6](assets/skrin/Screenshot_6.jpg)|![Screenshot 7](assets/skrin/Screenshot_7.jpg)|
|---|---|---|---|

|![Screenshot 8](assets/skrin/Screenshot_8.jpg)|![Screenshot 9](assets/skrin/Screenshot_9.jpg)|![Screenshot 10](assets/skrin/Screenshot_10.jpg)|
|---|---|---|

## Реализованные возможности

### Аккаунт и профиль

- регистрация и вход по email/паролю;
- вход через Google;
- подтверждение email и повторная отправка письма;
- сброс пароля;
- принятие актуальных юридических документов;
- редактирование профиля, цели, интенсивности, места и опыта тренировок;
- выбор встроенного аватара или фотографии;
- самостоятельное удаление аккаунта вместе с относящимися к нему данными Firebase и локальным кэшем.

### Тренировки

- генерация недельного плана с учётом профиля, доступного оборудования, медицинских ограничений и данных восстановления;
- тестовая неделя для первичной калибровки нагрузки;
- выполнение тренировки с подходами, фазами, таймером, отдыхом, TTS-подсказками и блокировкой сна экрана;
- сохранение выполненных тренировок и субъективной нагрузки RPE;
- календарь тренировок и перенос занятия на другую дату;
- импорт и AI-коррекция плана из текста, файла, QR-кода или общего контента;
- каталог из `1 346` упражнений и `1 346` соответствующих GIF-демонстраций;
- экран упражнения с техникой, целевыми мышцами и ссылкой на видеопоиск;
- персональные рекорды;
- интерактивная 3D-модель мышц на базе Z-Anatomy с выделением основных и вспомогательных мышечных групп;
- мини-плеер активной тренировки при переходе между основными экранами.

### AI-тренер

- создание плана тренировок;
- создание плана питания;
- уточнение плана по результатам тестовой недели;
- корректировка существующего плана по запросу пользователя или результатам тренировки;
- анализ прогресса и еженедельный отчёт;
- многоходовый чат с контекстом профиля;
- учёт Recovery Score, среднего RPE и ежедневного DOMS-чек-ина;
- валидация структурированных AI-ответов и повтор запросов при временных ошибках.

DeepSeek вызывается только через callable-функцию `deepseekProxy`. API-ключ хранится в Firebase Secret Manager и не включается в APK.

### Питание

- AI-план питания с калориями и макронутриентами;
- дневник питания и ручное добавление продуктов;
- учёт воды;
- сканирование штрих-кода через `mobile_scanner` и получение продукта из Open Food Facts;
- список покупок на основе плана питания с категориями, отметками и заменой ингредиентов;
- расчёт индивидуальной цели калорий и макронутриентов.

### Здоровье и восстановление

Интеграция Google Health Connect читает доступные и разрешённые пользователем показатели:

- шаги;
- активные и общие калории;
- пульс и пульс покоя;
- HRV и частоту дыхания;
- сон;
- вес и рост;
- расстояние, воду и тренировки.

Recovery Score рассчитывается из сна, HRV и пульса покоя. Если часть данных недоступна, приложение продолжает синхронизацию остальных показателей. Разрешения выдаются и отзываются средствами операционной системы.

### Прогресс и мотивация

- статистика тренировок за разные периоды;
- замеры тела и фотографии прогресса;
- AI-анализ динамики;
- недельный отчёт;
- серии тренировок, XP, уровни и достижения;
- ежедневные задачи и кольца активности;
- шесть цветовых тем;
- локализация интерфейса на 15 языков: русский, английский, испанский, немецкий, французский, итальянский, португальский, турецкий, арабский, китайский, японский, корейский, хинди, украинский и белорусский.

### Социальные функции

- поиск пользователей;
- заявки в друзья и управление списком друзей;
- лента активности друзей;
- публичные и приватные челленджи;
- участие, выход, таблица лидеров и обновление прогресса;
- FCM- и внутриприкладные уведомления для поддерживаемых событий.

## Серверная часть

Cloud Functions работают в регионе `europe-west1` на Node.js 22.

| Группа | Реализованные функции |
|---|---|
| Друзья | `sendFriendRequest`, `acceptFriendRequest`, `declineFriendRequest`, `removeFriend`, `searchUsers` |
| Лента | `publishActivity`, `fanoutActivityEvent` |
| Челленджи | `createChallenge`, `joinChallenge`, `leaveChallenge`, `deleteChallenge`, `updateChallengeProgress`, `recordWorkout`, `seedChallenges` |
| Обслуживание | `cleanOldFeedEvents`, `cleanExpiredChallenges` |
| AI | `deepseekProxy` |
| Аккаунт | `deleteAccount` |

Callable-функции проверяют Firebase Auth, валидируют входные данные и применяют rate limit там, где это предусмотрено. Запись защищённых социальных и challenge-данных выполняется через Admin SDK; клиентские права задаются в `firestore.rules`.

Проект использует именованную базу Firestore `fitnesbuster`. Firebase Hosting раздаёт GIF упражнений из `public/gifs/` с immutable-кэшированием.

## Архитектура

```text
lib/
├── bloc/           # состояние экранов и пользовательских сценариев
├── core/           # AI, DI, Health Connect, локализация, уведомления, темы
├── data/           # модели и реализации репозиториев
├── domain/         # сущности, интерфейсы и use case
└── presentation/   # экраны и переиспользуемые виджеты

functions/
├── src/            # Firebase Cloud Functions на TypeScript
└── test/           # unit/spec и emulator-тесты
```

Основные технологии:

- Flutter, Dart, Material 3;
- BLoC, GetIt, go_router;
- Firebase Auth, Firestore, Cloud Functions, Analytics, FCM и Hosting;
- Hive с AES-шифрованием, SharedPreferences и Flutter Secure Storage;
- DeepSeek API через Firebase callable proxy;
- Health Connect, Open Food Facts, `model_viewer_plus`;
- Mockito, `bloc_test`, Flutter widget/golden tests и Node test runner.

## Быстрый старт

### Требования

- Flutter `3.38.5` (версия CI) и Dart SDK, совместимый с `>=3.10.3 <4.0.0`;
- Android SDK с API 36; минимальная версия устройства — API 26;
- Node.js 22;
- Java 21 и Firebase CLI `15.22.0` для emulator-тестов;
- Firebase-проект с Authentication, именованной базой Firestore `fitnesbuster`, Cloud Functions, FCM и Hosting;
- DeepSeek API-ключ для серверного секрета.

### Установка приложения

```bash
git clone https://github.com/maksimyugov89/fitnesbuster.git
cd fitnesbuster
flutter pub get
flutter run
```

Android-конфигурация Firebase находится в `android/app/google-services.json`, а сгенерированные параметры — в `lib/firebase_options.dart`. Для другого Firebase-проекта их необходимо пересоздать через FlutterFire CLI.

### Настройка и запуск Firebase

```bash
cd functions
npm ci
npm run build
cd ..

firebase login
firebase functions:secrets:set DEEPSEEK_API_KEY
firebase deploy
```

Cloud Function обращается к модели `deepseek-chat` на `api.deepseek.com`. Секретный API-ключ через `--dart-define` не используется.

### iOS

В репозитории есть Flutter iOS target и код чтения Apple Health, но готовая Firebase-конфигурация iOS (`GoogleService-Info.plist` и iOS-секция `firebase_options.dart`) не хранится в проекте. Перед запуском на iOS необходимо выполнить `flutterfire configure` для iOS, настроить signing/capabilities и проверить сборку на macOS. GitHub Actions проекта сейчас собирает Android APK/AAB.

## Проверка качества

Локальная последовательность совпадает с основными гейтами CI:

```bash
cd functions
npm ci
npm test
cd ..

dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze --no-fatal-infos --no-fatal-warnings lib test integration_test
flutter test --coverage --reporter=expanded
```

Полные Firebase emulator-тесты:

```bash
cd functions
npm run test:emulator:exec
```

GitHub Actions содержит четыре workflow:

- `ci.yml` — форматирование, анализ, Flutter-тесты, coverage, Functions unit/spec и emulator-тесты;
- `build.yml` — Android APK и AAB;
- `security.yml` — OSV-сканирование `pubspec.lock` и `functions/package-lock.json`;
- `release.yml` — повторные quality gates, подписанная Android-сборка и GitHub Release по тегу.

Подробнее: [docs/CI_CD.md](docs/CI_CD.md).

## Лицензия

Код приложения: Proprietary — все права защищены.

### Z-Anatomy

Интерактивная анатомическая модель содержит материалы, производные от проекта Z-Anatomy.

```text
© Z-Anatomy Project
License: Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
https://www.z-anatomy.com/

This application contains content derived from Z-Anatomy.
Modifications have been made for integration into FitnesBuster:
export to GLB format, Draco compression, bilateral muscle highlighting,
X-ray transparency effect.

Derived materials are distributed under CC BY-SA 4.0.
```

Условия лицензии: [creativecommons.org/licenses/by-sa/4.0](https://creativecommons.org/licenses/by-sa/4.0/).
