<p align="center">
  <img src="assets/icons/icon.png" width="120" alt="FitnesBuster logo">
</p>

<p align="center">
  <strong>Издатель:</strong> Югов Максим Александрович &nbsp;|&nbsp; <strong>Email:</strong> maksim.yugov.89@gmail.com
</p>

# FitnesBuster

[![CI](https://github.com/maksimyugov89/fitnesbuster/actions/workflows/ci.yml/badge.svg)](https://github.com/maksimyugov89/fitnesbuster/actions/workflows/ci.yml)
[![Build](https://github.com/maksimyugov89/fitnesbuster/actions/workflows/build.yml/badge.svg)](https://github.com/maksimyugov89/fitnesbuster/actions/workflows/build.yml)
[![Security](https://github.com/maksimyugov89/fitnesbuster/actions/workflows/security.yml/badge.svg)](https://github.com/maksimyugov89/fitnesbuster/actions/workflows/security.yml)

**Персональный AI-помощник для тренировок, питания и контроля восстановления.**

FitnesBuster — мобильное Flutter-приложение, которое объединяет персональные тренировочные планы, дневник питания, данные здоровья, контроль прогресса, геймификацию и социальные функции. План строится с учётом цели, уровня подготовки, доступного оборудования, медицинских ограничений, результатов тестовой недели и доступных показателей восстановления.

Основная поддерживаемая платформа проекта — **Android 8.0+ (API 26)**. Серверная часть работает на Firebase, AI-запросы выполняются через защищённую Cloud Function к DeepSeek, данные здоровья на Android поступают из Google Health Connect, а локальный кэш хранится в Hive и SharedPreferences.

> FitnesBuster не является медицинским изделием и не заменяет консультацию врача. Рекомендации приложения предназначены для информационной поддержки тренировок и здорового образа жизни.

## Состояние проекта

| Область | Текущее состояние |
|---|---|
| Версия приложения | `1.0.0+1` |
| Основная платформа | Android, минимум API 26, compile SDK 36 |
| iOS | Flutter target и HealthKit-код присутствуют; требуется отдельная Firebase-конфигурация, signing и проверка на macOS |
| AI | DeepSeek `deepseek-chat` через callable-функцию `deepseekProxy` |
| Контент упражнений | `1 346` упражнений и соответствующих GIF-демонстраций |
| Локализация | 15 языков, включая RTL для арабского |
| Backend | Firebase Auth, именованная Firestore-база `fitnesbuster`, Cloud Functions, FCM, Analytics и Hosting |
| Качество | Format, analyzer, Flutter tests, Functions tests, emulator tests, Android APK/AAB и OSV security scan выполняются в GitHub Actions |

## Скриншоты

|![Screenshot 0](assets/skrin/Screenshot_0.jpg)|![Screenshot 1](assets/skrin/Screenshot_1.jpg)|![Screenshot 2](assets/skrin/Screenshot_2.jpg)|![Screenshot 3](assets/skrin/Screenshot_3.jpg)|
|---|---|---|---|

|![Screenshot 4](assets/skrin/Screenshot_4.jpg)|![Screenshot 5](assets/skrin/Screenshot_5.jpg)|![Screenshot 6](assets/skrin/Screenshot_6.jpg)|![Screenshot 7](assets/skrin/Screenshot_7.jpg)|
|---|---|---|---|

|![Screenshot 8](assets/skrin/Screenshot_8.jpg)|![Screenshot 9](assets/skrin/Screenshot_9.jpg)|![Screenshot 10](assets/skrin/Screenshot_10.jpg)|
|---|---|---|

## Как работает приложение

Типовой пользовательский сценарий выглядит так:

1. Пользователь создаёт аккаунт по email или входит через Google, подтверждает email и принимает актуальные юридические документы.
2. Во время онбординга указывает цель, интенсивность, место тренировок, доступное оборудование, параметры тела и ограничения по здоровью.
3. FitnesBuster создаёт первоначальные планы тренировок и питания.
4. Тестовая неделя помогает откалибровать рабочие веса, объём и субъективную нагрузку.
5. Пользователь выполняет тренировки, ведёт питание, воду, замеры и при желании подключает Health Connect.
6. Recovery Score, RPE, DOMS и история прогресса используются как контекст для рекомендаций и корректировки нагрузки.
7. Дашборд объединяет план на день, показатели здоровья, питание, прогресс, XP и социальную активность.

## Реализованные возможности

### Аккаунт, юридическое согласие и профиль

| Возможность | Реализация |
|---|---|
| Email-аутентификация | Регистрация и вход по email/паролю через Firebase Auth |
| Google Sign-In | Вход через Google с выбором аккаунта |
| Подтверждение email | Отдельный экран, ручная проверка статуса, повторная отправка письма и блокировка приватных маршрутов до подтверждения |
| Сброс пароля | Отправка письма через Firebase Auth |
| Юридическое согласие | Версионированная запись согласия с условиями использования и политикой конфиденциальности в `users/{uid}/legal_consents` |
| Профиль | Имя, дата рождения, пол, рост, вес, активность, цель, опыт, место тренировок и медицинские ограничения |
| Аватар | Встроенные изображения либо собственная фотография из камеры/галереи |
| Настройки | Язык, тема, параметры тренировок, уведомления и синхронизация здоровья |
| Удаление аккаунта | Callable-функция удаляет Firebase Auth и связанные пользовательские данные; приложение очищает локальный кэш |

### Онбординг

Онбординг собирает данные, необходимые для персонализации:

- цель: снижение веса, набор массы, поддержание формы и другие доступные сценарии;
- желаемую интенсивность;
- место тренировок: зал, дом или улица;
- доступное оборудование и предпочтения по бегу;
- параметры тела и уровень активности;
- ограничения по здоровью;
- разрешение на подключение Health Connect.

Автоматическое определение города является необязательным: пользователь видит объяснение перед системным запросом геолокации и может ввести город вручную.

### Тренировки

| Возможность | Реализация |
|---|---|
| Персональный план | Недельная программа с упражнениями, подходами, повторениями, отдыхом, RPE, темпом и подсказками по технике |
| Контекст генерации | Цель, профиль, опыт, оборудование, ограничения, восстановление, средний RPE и результаты тестовой недели |
| Тестовая неделя | Последовательность калибровочных тренировок с сохранением результатов и последующим уточнением плана |
| Выполнение тренировки | Фазы подготовки/работы/отдыха, таймер, подходы, пауза, TTS-подсказки и запрет отключения экрана |
| Сохранение результата | Выполненные упражнения, подходы, время, калории и субъективная нагрузка |
| Календарь | Просмотр недельного/месячного расписания и перенос тренировки на другую дату |
| Импорт плана | Разбор текста, файла, QR-кода или переданного в приложение содержимого с AI-валидацией и коррекцией |
| Каталог | `1 346` упражнений с мышечными группами, описанием техники и GIF-демонстрациями |
| Экран упражнения | Техника, целевые мышцы, GIF, AI-подсказки и переход к видеопоиску |
| Персональные рекорды | Сохранение результата по упражнению, весу, повторениям и подходам |
| Активная сессия | Мини-плеер продолжает показывать состояние тренировки при переходе между основными разделами |

GIF-файлы упражнений раздаются через Firebase Hosting:

```text
https://fitnesbuster.web.app/gifs/{exerciseDbId}.gif
```

Для `/gifs/**` настроен `Cache-Control: public, max-age=31536000, immutable`.

### AI-тренер

AI-слой реализует несколько отдельных сценариев:

- создание плана тренировок;
- создание плана питания;
- корректировка плана после тестовой недели;
- изменение существующего плана по запросу пользователя;
- разбор импортированного плана;
- анализ прогресса и замеров;
- еженедельный дебриф;
- проверка реалистичности цели;
- советы по технике упражнений;
- многоходовый чат с контекстом профиля и истории диалога.

Структурированные ответы проходят очистку и JSON-валидацию. Для временных ошибок предусмотрены ограниченные повторные запросы, а ошибки callable-функции преобразуются в понятные приложению категории.

API-ключ DeepSeek не передаётся через `--dart-define` и не включается в APK. Клиент вызывает Firebase callable-функцию `deepseekProxy`, а секрет хранится в Firebase Secret Manager.

### Питание

| Возможность | Реализация |
|---|---|
| План питания | AI-меню с приёмами пищи, ингредиентами, калориями и макронутриентами |
| Индивидуальные цели | Расчёт дневной калорийности и макросов на основе профиля и цели |
| Дневник | Добавление и удаление продуктов, дневной итог и сравнение с целью |
| Ручной ввод | Добавление собственного блюда и калорийности |
| Штрих-код | Сканирование через `mobile_scanner` и поиск продукта в Open Food Facts |
| Вода | Дневной счётчик потребления воды |
| Список покупок | Формирование из плана питания, категории, чекбоксы, прогресс, копирование и замена ингредиентов |

### Здоровье и восстановление

На Android приложение интегрировано с Google Health Connect и читает только те типы данных, на которые пользователь выдал разрешение:

- шаги и пройденное расстояние;
- активные и общие калории;
- пульс и пульс покоя;
- HRV и частоту дыхания;
- сон;
- вес и рост;
- гидратацию;
- тренировки.

Синхронизация не прекращается целиком, если отдельный показатель недоступен: приложение продолжает обработку остальных типов данных. Разрешения выдаются и отзываются средствами операционной системы.

Recovery Score рассчитывается по доступным данным сна, HRV и пульса покоя. При неполном наборе данных интерфейс не выдаёт отсутствующие значения за измеренные. Показатель восстановления используется как рекомендационный контекст, а не как медицинский диагноз.

### Прогресс и мотивация

- статистика тренировок за день, неделю, месяц и год;
- история веса и параметров тела;
- замеры груди, талии, бёдер и процента жира;
- фотографии прогресса с нескольких ракурсов;
- AI-анализ динамики;
- еженедельный отчёт по выполнению плана;
- серии тренировок;
- XP, уровни и достижения;
- ежедневные задания;
- кольца активности на дашборде;
- персональные рекорды.

### Социальные функции

| Возможность | Реализация |
|---|---|
| Поиск | Поиск пользователей по username через Cloud Function |
| Друзья | Отправка, принятие и отклонение заявок, удаление из друзей |
| Лента | События друзей о поддерживаемой активности |
| Челленджи | Публичные и приватные челленджи, участие, выход, удаление, прогресс и таблица лидеров |
| Уведомления | FCM и локальные уведомления для поддерживаемых событий |

Изменения дружбы, ленты и челленджей выполняются серверными callable-функциями. Прямая клиентская запись в защищённые коллекции закрыта Firestore Rules.

## Интерактивная 3D-анатомия

В приложении используется интерактивная модель мышц, производная от открытого проекта Z-Anatomy.

Основные компоненты:

- GLB/glTF-модель в `assets/anatomy/`;
- Draco-сжатие для уменьшения размера;
- `model_viewer_plus` и WebView для отображения;
- сопоставление упражнений с основными и вспомогательными мышечными зонами;
- двусторонняя подсветка парных мышц;
- разные цвета для основных и вспомогательных мышц;
- X-ray-режим, делающий остальные области полупрозрачными;
- управление камерой и адаптивное кадрирование модели.

Контракт подсветки строится вокруг идентификаторов мышечных зон: упражнение передаёт основные и вспомогательные зоны, а WebView меняет материалы соответствующих мешей.

## Локализация и темы

### Поддерживаемые языки

| Язык | Код | Язык | Код | Язык | Код |
|---|---|---|---|---|---|
| Русский | `ru` | English | `en` | Español | `es` |
| Deutsch | `de` | Français | `fr` | Italiano | `it` |
| Português | `pt` | Türkçe | `tr` | العربية | `ar` |
| 中文 | `zh` | 日本語 | `ja` | 한국어 | `ko` |
| हिन्दी | `hi` | Українська | `uk` | Беларуская | `be` |

Русский язык используется по умолчанию. Выбранная локаль сохраняется в SharedPreferences и применяется без перезапуска приложения. Для арабского языка поддерживается RTL-направление интерфейса.

### Цветовые темы

В приложении доступны шесть динамических тем:

1. Neon Dark / Electric Volt;
2. Ocean Blue / Deep Horizon;
3. Sunset Warm / Aurora Flame;
4. Forest Green / Jade Matrix;
5. Midnight Purple / Nebula;
6. CyberPunk / Neon Tokyo.

Тема управляет основными цветами, поверхностями, текстом, статусами, градиентами и декоративными изображениями приложения.

## Firebase и серверная часть

Cloud Functions размещаются в регионе `europe-west1` и выполняются на Node.js 22.

| Группа | Функции | Назначение |
|---|---|---|
| Друзья | `sendFriendRequest`, `acceptFriendRequest`, `declineFriendRequest`, `removeFriend`, `searchUsers` | Поиск и жизненный цикл дружбы |
| Лента | `publishActivity`, `fanoutActivityEvent` | Публикация валидированного события и распространение в ленты друзей |
| Челленджи | `createChallenge`, `joinChallenge`, `leaveChallenge`, `deleteChallenge`, `updateChallengeProgress`, `recordWorkout`, `seedChallenges` | Создание, участие, прогресс, результаты и начальные челленджи |
| Обслуживание | `cleanOldFeedEvents`, `cleanExpiredChallenges` | Плановая очистка устаревших данных |
| AI | `deepseekProxy` | Защищённый прокси к DeepSeek API |
| Аккаунт | `deleteAccount` | Каскадное удаление пользовательских данных и Firebase Auth |

Callable-функции проверяют Firebase Auth, валидируют форму и ограничения входных данных, используют транзакции там, где требуется согласованность, и применяют rate limit для чувствительных операций.

### Firestore

Проект использует не базу `(default)`, а именованную Firestore-базу:

```text
fitnesbuster
```

Основная структура данных:

```text
users/{uid}
  ├── профиль, onboarding и настройки
  ├── AI-планы и замеры тела
  └── legal_consents/{versionId}

friend_requests/{requestId}
friends/{uid}/list/{friendUid}
activity_events/{uid}/items/{eventId}
feed/{uid}/events/{eventId}
challenges/{challengeId}
challenge_progress/{challengeId}/participants/{uid}
notifications/{uid}/items/{notificationId}
```

### Границы доступа

- профиль пользователя доступен только его владельцу;
- запись юридического согласия разрешена только самому пользователю, имеет фиксированную версию и серверное время;
- заявки в друзья читают только их участники;
- списки друзей, лента и уведомления читаются их владельцем;
- челленджи и таблицы прогресса доступны авторизованным пользователям для чтения;
- прямые клиентские записи в server-owned социальные коллекции запрещены;
- серверные Cloud Functions используют Admin SDK и выполняют валидацию до записи.

## Архитектура

Проект следует разделению ответственности в стиле Clean Architecture с BLoC, Repository и dependency injection через GetIt.

```text
lib/
├── main.dart
├── bloc/
│   ├── ai/
│   ├── auth/
│   ├── health/
│   ├── nutrition/
│   ├── onboarding/
│   ├── training/
│   ├── user/
│   └── workout/
├── core/
│   ├── ai/                 # AI-клиент, специализированные сервисы, JSON-валидация
│   ├── analytics/          # события приложения
│   ├── constants/          # общие константы и Firebase database id
│   ├── di/                 # регистрация зависимостей GetIt
│   ├── health/             # Health Connect / HealthKit adapters
│   ├── initialization/     # этапы запуска приложения
│   ├── legal/              # версии документов и модель согласия
│   ├── localization/       # локали и переводы
│   ├── notifications/      # локальные и push-уведомления
│   ├── router/             # go_router и route guards
│   ├── services/           # прикладные сервисы
│   └── theme/              # темы и изображения
├── data/
│   ├── models/             # DTO и сериализация
│   └── repositories/       # Firebase и локальные реализации
├── domain/
│   ├── entities/           # доменные сущности
│   ├── exceptions/         # типизированные исключения
│   ├── repositories/       # интерфейсы репозиториев
│   ├── services/           # интерфейсы сервисов
│   └── usecases/           # отдельные сценарии предметной области
└── presentation/
    ├── screens/            # экраны приложения
    └── widgets/            # переиспользуемые виджеты по доменам

functions/
├── src/                    # Firebase Cloud Functions на TypeScript
└── test/                   # unit/spec и emulator-тесты
```

### Ответственность слоёв

| Слой | Ответственность |
|---|---|
| Presentation | Экраны, виджеты, отображение состояний и пользовательский ввод |
| BLoC | Состояния и последовательность пользовательских сценариев |
| Domain | Сущности, интерфейсы и правила предметной области без зависимости от UI/Firebase |
| Data | Репозитории, DTO, Firestore, Auth, Hive и SharedPreferences |
| Core | Общая инфраструктура: AI, DI, health, router, localization, notifications и theme |
| Functions | Доверенная серверная логика и операции с Admin SDK |

### Основные BLoC-модули

| Модуль | Зона ответственности |
|---|---|
| `AuthBloc` | Сессия, вход, регистрация, Google Sign-In, email verification и legal consent |
| `UserBloc` | Загрузка и изменение профиля пользователя |
| `OnboardingBloc` | Сбор параметров онбординга и завершение первичной настройки |
| `WorkoutBloc` | Активная тренировка, фазы, подходы, таймер и результат |
| `TestWeekBloc` | Калибровочная неделя и сохранение прогресса |
| `NutritionBloc` | План питания и дневной журнал |
| `HealthBloc` / `HealthSyncBloc` | Чтение, синхронизация и отображение health-данных |
| `AiBloc` | Генерация AI-планов и вопросы к тренеру |

### AI-поток

```text
UI / BLoC
  → IDeepSeekService
    → WorkoutPlanService / MealPlanService / PlanRefinementService /
      ProgressAnalyzer / ChatService
        → BaseClient
          → Firebase callable deepseekProxy
            → DeepSeek API
```

Такое разделение оставляет API-ключ на сервере и позволяет менять реализацию AI-провайдера без прямой зависимости экранов и BLoC от HTTP-клиента.

### Хранение данных

| Хранилище | Использование |
|---|---|
| Firestore | Профиль, согласия, планы, замеры, друзья, лента, челленджи и серверные данные |
| Firebase Auth | Email/пароль, Google Sign-In, email verification и жизненный цикл аккаунта |
| Hive | Кэш AI-планов, история чата, дебрифы и данные, которым нужен быстрый локальный доступ |
| Flutter Secure Storage | Ключ шифрования Hive |
| SharedPreferences | Язык, тема, дневные локальные показатели и небольшие настройки |
| Firebase Hosting | GIF-демонстрации упражнений |

## Технологический стек

| Область | Технологии |
|---|---|
| UI | Flutter, Dart, Material 3 |
| State management | `flutter_bloc`, `equatable` |
| Навигация и DI | `go_router`, `get_it` |
| Модели | `freezed`, `json_serializable` |
| Firebase | Core, Auth, Firestore, Cloud Functions, Analytics, Messaging, Hosting |
| Локальные данные | Hive с AES-шифрованием, SharedPreferences, Flutter Secure Storage |
| AI | DeepSeek API через Firebase callable proxy |
| Здоровье | `health`, Google Health Connect, Apple HealthKit adapter |
| Контент | Open Food Facts, Firebase Hosting GIF CDN |
| Устройства | `mobile_scanner`, `image_picker`, `file_picker`, `flutter_tts`, `wakelock_plus` |
| 3D | `model_viewer_plus`, GLB/glTF, Draco, WebView JavaScript |
| Тестирование | Flutter test, `bloc_test`, Mockito, golden tests, Node test runner, Firebase Emulator Suite |

## Платформы и ограничения

| Платформа | Статус | Примечание |
|---|---|---|
| Android | Основная | API 26+, Google Sign-In, FCM, Health Connect, APK/AAB в CI |
| iOS | Требует настройки | Target и HealthKit-код есть, но `GoogleService-Info.plist` и готовая iOS Firebase-конфигурация не хранятся в репозитории |

Важные эксплуатационные ограничения:

- AI, социальные функции, Firebase Auth и загрузка GIF требуют подключения к интернету;
- состав доступных health-данных зависит от устройства, ОС, установленных источников и выданных разрешений;
- Health Connect может потребовать отдельную установку или обновление на поддерживаемых версиях Android;
- артефакты обычного `build.yml` подписаны debug-ключом и предназначены для внутреннего тестирования, а не для Google Play;
- полноценный iOS-релиз необходимо проверять на macOS с корректными signing/capabilities;
- результат AI может требовать проверки пользователем, особенно при наличии травм и медицинских ограничений.

## Быстрый старт

### Требования

- Flutter `3.38.5` — версия, закреплённая в CI;
- Dart SDK `>=3.10.3 <4.0.0`;
- Android SDK: compile SDK 36, минимум устройства API 26;
- Node.js 22 для Cloud Functions;
- Java 21 и Firebase CLI `15.22.0` для полного emulator-прогона;
- Firebase-проект с Authentication, именованной Firestore-базой, Functions, FCM и Hosting;
- DeepSeek API-ключ для Firebase Secret Manager.

### Получение проекта

```bash
git clone https://github.com/maksimyugov89/fitnesbuster.git
cd fitnesbuster
flutter pub get
```

Сгенерированные файлы моделей и mock-файлы хранятся в репозитории. После изменения аннотаций или интерфейсов их можно пересоздать:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Запуск Android

```bash
flutter run
```

Android Firebase-конфигурация находится в `android/app/google-services.json`, а параметры FlutterFire — в `lib/firebase_options.dart`. При подключении другого Firebase-проекта эти файлы необходимо пересоздать через FlutterFire CLI.

Сборка релизных Android-артефактов:

```bash
flutter build apk --release
flutter build appbundle --release
```

### Настройка Firebase backend

```bash
cd functions
npm ci
npm run build
cd ..

firebase login
firebase functions:secrets:set DEEPSEEK_API_KEY --project fitnesbuster
firebase deploy --only functions,firestore:rules,firestore:indexes,hosting --project fitnesbuster
```

`firebase.json` направляет Firestore Rules и indexes в именованную базу `fitnesbuster`. Перед развёртыванием в другой проект проверьте project id, database id, регион Functions и секреты.

### Настройка iOS

Для запуска на iOS необходимо:

1. выполнить `flutterfire configure` с добавлением iOS-приложения;
2. добавить `GoogleService-Info.plist` в `ios/Runner/`;
3. обновить iOS-секцию `lib/firebase_options.dart`;
4. настроить signing, HealthKit capability, push notifications и background modes;
5. выполнить сборку и smoke-тесты на macOS с реальным устройством или симулятором.

## Проверка качества

### Flutter

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze --no-fatal-infos --no-fatal-warnings lib test integration_test
flutter test --coverage --reporter=expanded
```

Отдельные наборы:

```bash
flutter test test/integration/
flutter test test/golden/
```

### Cloud Functions и Firebase Emulator Suite

```bash
cd functions
npm ci
npm run build
npm test
npm run test:emulator:exec
```

Emulator-тесты используют demo-проект и проверяют callable-сценарии, Firebase Auth и поведение Firestore Rules без обращения к production-данным.

### GitHub Actions

| Workflow | Назначение |
|---|---|
| `ci.yml` | Format, analyzer, Flutter tests/goldens/integration, coverage, Functions build/unit/emulator |
| `build.yml` | Android arm64 APK и AAB для внутреннего тестирования |
| `security.yml` | OSV-сканирование `pubspec.lock` и `functions/package-lock.json` |
| `release.yml` | Quality gates, подписанные APK/AAB и GitHub Release по тегу или ручному запуску |

Подробнее о pipeline: [docs/CI_CD.md](docs/CI_CD.md).

## Безопасность и приватность

- DeepSeek API-ключ хранится в Firebase Secret Manager;
- callable-функции требуют Firebase Auth и проверяют входные данные;
- rate limit ограничивает чувствительные и потенциально дорогостоящие операции;
- защищённые Firestore-коллекции нельзя изменять напрямую из клиента;
- Firestore Rules привязаны к uid владельца и именованной базе `fitnesbuster`;
- юридическое согласие хранится отдельной неизменяемой версионированной записью;
- локальный Hive-кэш шифруется, а ключ хранится в Flutter Secure Storage;
- приложение запрашивает системные разрешения непосредственно перед соответствующим пользовательским действием;
- удаление аккаунта очищает Firebase Auth, связанные серверные данные и локальное состояние.

Дополнительные документы:

- [CI/CD](docs/CI_CD.md)
- [Аудит разрешений](docs/PERMISSIONS_AUDIT.md)
- [Release smoke checklist](docs/RELEASE_SMOKE_CHECKLIST.md)
- [Тексты политики конфиденциальности и условий использования](lib/core/legal/legal_documents.dart)

## Лицензия

Код приложения: **Proprietary — все права защищены**.

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
