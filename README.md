# FitnesBuster

**Издатель:** Югов Максим Александрович  
**Email:** maksim.yugov.89@gmail.com

**Персональный AI-фитнес-тренер в кармане.**

FitnesBuster — Flutter-приложение (Android / iOS), которое генерирует персонализированные программы тренировок и питания на базе целей пользователя, уровня подготовки, доступного оборудования и медицинских ограничений. Используется **DeepSeek AI** для создания и корректировки планов, **Google Health Connect / Apple HealthKit** для синхронизации данных здоровья, **Firebase** (Firestore, Auth, Cloud Functions, FCM, Hosting) для бэкенда, **Hive** для офлайн-кэша, **OpenFoodFacts** для сканирования штрих-кодов. Интерактивная **3D анатомическая модель** на базе Z-Anatomy визуализирует задействованные мышцы с X-ray эффектом. База из **1 346 упражнений** с GIF-демонстрациями (100% покрытие) раздаётся через **Firebase Hosting CDN** с immutable-кэшированием.

Версия: `1.0.0+1` | **Рефакторинг завершён** (28.06.2026): 73/73 проблем закрыто, `dart analyze` — 0 ошибок

| Метрика | До рефакторинга | После |
|---------|----------------|-------|
| Файлов >1000 строк | 4 | **0** |
| God-объектов | 2 (1120+754) | **0** |
| Хардкодированных `Color(0x…)` | 125+ | ~65 → SemanticColors |
| Хардкодированных UI-строк | 50+ | **0** |
| Неиспользуемых зависимостей | 8 | **0** |
| Тестов | 225 | **337** (321 + 16 E2E) |
| Локализаций | 632 ключа | **845+** ключей |
| `dart analyze` | — | **0 ошибок** |

---

## Скриншоты

|<img src="assets/skrin/Screenshot_0.jpg" width="180">|<img src="assets/skrin/Screenshot_1.jpg" width="180">|<img src="assets/skrin/Screenshot_2.jpg" width="180">|<img src="assets/skrin/Screenshot_3.jpg" width="180">|
|---|---|---|---|

|<img src="assets/skrin/Screenshot_4.jpg" width="180">|<img src="assets/skrin/Screenshot_5.jpg" width="180">|<img src="assets/skrin/Screenshot_6.jpg" width="180">|<img src="assets/skrin/Screenshot_7.jpg" width="180">|
|---|---|---|---|

|<img src="assets/skrin/Screenshot_8.jpg" width="180">|<img src="assets/skrin/Screenshot_9.jpg" width="180">|<img src="assets/skrin/Screenshot_10.jpg" width="180">|
|---|---|---|

---

## Конкурентные преимущества

| Преимущество | Описание | Конкуренты |
| --- | --- | --- |
| **3D анатомия с X-ray** | Z-Anatomy GLB, 239 региональных мешей, выделение первичных/вторичных мышц | Нет ни у одного из топ-10 |
| **Полная AI-экосистема** | Планы тренировок + питания + чат + дебриф + советы по технике — в одном приложении | Fitbod (только планы), BetterMe (только питание) |
| **Recovery Score** | Формула: сон (40%) + HRV (35%) + пульс покоя (25%) → адаптация нагрузки | Freeletics, Future (без авто-адаптации) |
| **Смарт-уведомления (ML)** | 21-дневный анализ паттернов → адаптивное время напоминания тренировки | Нет ни у одного из топ-10 |
| **6 кастомных тем** | 24 токена на тему, Neon Dark / Ocean Blue / Sunset Warm / Forest Green / Midnight Purple / CyberPunk | Нет ни у одного из топ-10 |
| **1 346 GIF + 15 языков** | Полный перевод базы упражнений на русский, CDN без API-ключей | Конкуренты не локализуют контент для RU-рынка |
| **WorkoutMiniPlayer** | Плавающий мини-плеер выполнения поверх всех экранов приложения | Нет ни у одного из топ-10 |
| **15 провайдеров здоровья** | Samsung Health, Garmin, Fitbit, Oura, Whoop, Polar и другие | Только Strava (но без AI и питания) |

---

## Быстрый старт

### Требования
- Flutter 3.27+ / Dart 3.6+
- Android 8.0+ (API 26) с установленным Google Health Connect
- iOS 14+ (Apple HealthKit)
- Firebase проект (Blaze plan) с Firestore, Authentication, Cloud Functions, FCM и Analytics
- DeepSeek API ключ
- Node.js 22+ и Firebase CLI (для деплоя Cloud Functions)

### Установка

```bash
git clone https://github.com/your-org/fitnesbuster.git
cd fitnesbuster
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

Добавьте `google-services.json` (Android) в `android/app/` и `GoogleService-Info.plist` (iOS) в `ios/Runner/`.

```bash
# Деплой Firebase (правила, индексы, Cloud Functions)
cd functions && npm install && npm run build && cd ..
firebase login
firebase deploy

# Запуск приложения
flutter run --dart-define=DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## Архитектура

```
lib/
├── main.dart                       # Entry point, MultiBlocProvider, Hive init, NotificationService
├── bloc/                           # State management (BLoC)
│   ├── auth/                       # AuthBloc — email/Google вход, регистрация (AuthException в domain)
│   ├── user/                       # UserBloc — профиль, цели, параметры тела
│   ├── workout/                    # WorkoutBloc — выполнение тренировки (таймер, фазы, подходы)
│   ├── health/                     # HealthBloc, HealthSyncBloc — Health Connect / HealthKit
│   ├── nutrition/                  # NutritionBloc — дневной лог питания, AI-план (try-catch)
│   ├── ai/                         # AiBloc — генерация планов, AI-вопросы
│   ├── onboarding/                 # OnboardingBloc — 5-шаговый онбординг (+ OnboardingWorkflowService)
│   └── training/                   # TestWeekBloc — калибровочная неделя (TestWeekStateError + CompleteTestWeekUseCase)
├── core/                           # Сервисы и конфигурация
│   ├── ai/
│   │   ├── base_client.dart        # Общий HTTP-клиент с retry
│   │   ├── services/               # WorkoutPlanService, MealPlanService, PlanRefinementService,
│   │   │                           # ProgressAnalyzer, ChatService — 5 специализированных AI-сервисов
│   │   └── deepseek_service.dart   # Фасад (110 строк)
│   ├── analytics/                  # AnalyticsService — события login/signup/workout/onboarding/testweek
│   ├── constants/                  # SemanticColors (11 констант), AvatarPresets, AppConstants
│   ├── di/                         # GetIt DI — все сервисы по интерфейсам, 0 cast-выражений
│   ├── health/                     # HealthConnectService, HealthServiceAdapter (IHealthService)
│   ├── localization/               # AppLocalizations (845+ ключей, 15 языков), LanguageService
│   ├── notifications/              # NotificationService — локальные push + смарт-напоминание (DailyTime)
│   ├── router/                     # go_router (AppRouter) — навигация с ShellRoute, AuthRouterNotifier
│   ├── services/                   # WorkoutSession (DI), GamificationService, NutritionService,
│   │                               # FcmService, RecoveryScoreService, OnboardingWorkflowService,
│   │                               # TestWeekWorkflowService, MuscleZoneMatcher
│   └── theme/                      # ThemeService + ThemePalette (6 динамических тем)
├── data/                           # Репозитории и модели
│   ├── models/                     # ChatMessageModel, ExerciseDbModel (data-слой)
│   └── repositories/               # AuthRepository, UserRepository (Firestore + Hive), PrRepository,
│                                   # SettingsRepository
├── domain/                         # Доменный слой (чистый, без зависимостей на data/framework)
│   ├── entities/                   # 24 @freezed класса: UserProfile, WorkoutPlan, BodyMeasurement,
│   │                               # PersonalRecord, NutritionEntities, HealthEntities, DailyTime и др.
│   │                               # + 18 автогенерированных файлов (.freezed.dart + .g.dart)
│   ├── exceptions/                 # AuthException
│   ├── repositories/               # IAuthRepository, IUserRepository, IPrRepository, ISettingsRepository
│   ├── services/                   # 10 интерфейсов: IDeepSeekService, IGamificationService,
│   │                               # IHealthConnectService, IAdaptiveTrainingService, INutritionService,
│   │                               # IAnalyticsService, INotificationService, IFcmService,
│   │                               # IExerciseService, IHealthAnalyticsService
│   └── usecases/                   # CompleteTestWeekUseCase
└── presentation/
    ├── screens/                    # 33 экрана (все <700 строк после декомпозиции)
    └── widgets/                    # 65+ переиспользуемых виджетов по доменам:
        ├── dashboard/              # DashboardAppBar, ActivityRingsCard, TodaysWorkoutCard, XpBar,
        │                           # NutritionSummaryCard, QuickStatsCard, AiChatCard, SocialCard
        ├── workout/                # WorkoutPlanHeader, WorkoutExerciseCard, WorkoutDaySelector,
        │                           # DayDetailView, WeeklySummaryCard, TechniqueSheet,
        │                           # MuscleMapWidget, ExerciseGifThumb, WorkoutPlanWidgets
        ├── nutrition/              # MealCard, DailyProgressCard, NutritionHeader, WeeklyPlanView,
        │                           # BarcodeScanCard, MealProgressBar, AddedFoodTile, WaterTrackerCard,
        │                           # FoodItemRow, ManualFoodForm, MacroRing, MealAlternativesTile
        ├── progress/               # ProgressPeriodSelector, ProgressStatsPanel, ProgressWorkoutLog,
        │                           # ProgressPhotoSection, ProgressAiAnalysisSection, ProgressWeightSection,
        │                           # ProgressHealthList, ProgressMeasurementCard, BodyMeasurementsDialog
        ├── profile/                # ProfileSheetWidgets, ProfileEditSheets, ProfileEditor,
        │                           # ProfileMiscWidgets, AvatarPickerSheet, LanguageSelectionSheet,
        │                           # ThemeSelectionSheet
        └── router/                 # MainShell, RouterWorkoutMiniPlayer, RouterBottomNav
```

**Паттерны:** Clean Architecture + BLoC + Repository

**DI:** GetIt — все сервисы и репозитории регистрируются по доменным интерфейсам (`IXxx`). Конкретные типы дополнительно регистрируются через ту же переменную-экземпляр — 0 cast-выражений (`as ConcreteType`). Все 35+ `sl<Concrete>()` заменены на `sl<IInterface>()`.

**Логирование:** `appLogger` (пакет `logger`) — 0 вызовов `print()` / `debugPrint()` / `kDebugMode`-гейтов.

**Офлайн-очередь:** `OfflineQueue` (Hive) + `connectivity_plus` listener + DI — операции буферизируются при отсутствии сети.

**Data → Domain:** `BodyMeasurement`, `PersonalRecord`, `TestDayExercise`, `ExerciseInfo` — в `domain/entities/`. `ChatMessageModel` — в data-слое, domain `ChatMessage` — чистая сущность без сериализации.

**Строгий линтер:** 8 правил (`prefer_const_constructors`, `avoid_print` и др.), `dart fix --apply` — 117 авто-исправлений; `dart analyze` → «No issues found!»

**Навигация:** go_router с ShellRoute (bottom navigation) + WorkoutMiniPlayer поверх всех табов. Виджеты навигации (`MainShell`, `RouterBottomNav`, `RouterWorkoutMiniPlayer`) вынесены в `widgets/router/` и используют локализацию через `AppLocalizations.tl()`.

**Декомпозиция экранов:**
| Экран | До (строк) | После (строк) | Сокращение |
|--------|-----------|--------------|-----------|
| dashboard_screen.dart | 1814 | 561 | −69% |
| profile_screen.dart | 1873 | 987 | −47% |
| workout_plan_screen.dart | 1460 | 445 | −70% |
| progress_screen.dart | 1449 | 666 | −54% |
| nutrition_screen.dart | 1320 | 699 | −47% |
| deepseek_service.dart | 1120 | 110 | −90% (фасад) |
| functions/src/index.ts | 754 | 7 файлов | разбит на домены |

**DeepSeekService:** фасад (110 строк) → 5 специализированных AI-сервисов + BaseClient. Смена AI-провайдера — одна реализация `IDeepSeekService`, без изменений в BLoC и UI.

---

## BLoC — полный перечень

| BLoC | Назначение | Ключевые события |
|---|---|---|
| **AuthBloc** | Email/Google вход, регистрация, проверка сессии | `AuthLoginRequested`, `AuthRegisterRequested`, `AuthGoogleLoginRequested`, `AuthLogoutRequested` |
| **UserBloc** | CRUD профиля, онбординг, настройки | `UserLoadRequested`, `UserUpdateProfile`, `UserUpdateBodyParams`, `UserUpdateGoal`, `UserUpdateSettings` |
| **WorkoutBloc** | Выполнение тренировки (таймер, фазы, сеты) | `WorkoutStartRequested`, `WorkoutPauseRequested`, `WorkoutResumeRequested`, `WorkoutStopRequested`, `WorkoutSetCompleted`, `WorkoutTick` |
| **HealthBloc** | Чтение данных из Health Connect | `HealthFetchRequested`, `HealthWatchRequested` |
| **HealthSyncBloc** | Полная синхронизация Health Connect | `HealthSyncInitializeRequested`, `HealthSyncReadToday`, `HealthSyncReadDateRange` |
| **NutritionBloc** | Дневной лог питания, AI-план питания | `NutritionLoadRequested`, `NutritionAddFood`, `NutritionRemoveFood`, `NutritionRegenerateMealPlan` |
| **AiBloc** | Генерация планов, AI-вопросы | `AiGenerateWorkoutPlan`, `AiGenerateMealPlan`, `AiAskQuestion`, `AiReset` |
| **OnboardingBloc** | 5-шаговый онбординг → генерация AI-планов | `OnboardingSetGoal`, `OnboardingSetIntensity`, `OnboardingSetLocation`, `OnboardingSetProfile`, `OnboardingFinalize` |
| **TestWeekBloc** | Тестовая неделя → калибровка → адаптация плана | `TestWeekStartDay`, `TestWeekRecordExercise`, `TestWeekFinishDay`, `TestWeekComplete`, `TestWeekAdjustGoal` |

Все BLoC-зависимости инъецируются через доменные интерфейсы (`IUserRepository`, `IAuthRepository`, `IDeepSeekService` и т.д.), без прямых ссылок на Firebase или конкретные реализации.

---

## Функциональность

### Онбординг и профиль
| Экран | Описание |
|---|---|
| Цель | Похудеть / набрать массу / форма / пляжный сезон / спортивные результаты |
| Интенсивность | Хардкор / интенсив / баланс / постепенный / лайт |
| Место тренировок | Тренажёрный зал / улица / дома + настройка бега |
| Профиль | Рост, вес, возраст, пол, уровень активности, медицинские ограничения |
| Health Connect | Запрос разрешений, первичная синхронизация (шаги, пульс, сон, вес) |

После онбординга DeepSeek AI генерирует персональный 7-дневный план тренировок с периодизацией и план питания.

### Тренировки
| Функция | Описание |
|---|---|
| 3D мышечная карта | Интерактивная 3D модель тела на базе Z-Anatomy (GLB, Draco-сжатие). При выборе мышцы или упражнения — X-ray эффект: нерелевантные мышцы становятся прозрачными (18% opacity), первичные подсвечиваются красным, вторичные синим. Парные мышцы подсвечиваются одновременно с обеих сторон. Тело покрыто 239 региональными мешами |
| AI-план | JSON-план от DeepSeek с периодизацией (Адаптация → Прогресс → Интенсификация → Пик), ротацией мышечных групп, RPE, темпом, подсказками по технике, схемами прогрессии |
| Rich-поля упражнений | Основная/вторичная мышца, guideline веса, RPE, темп, техника-подсказка, прогрессия |
| Тестовая неделя | 4 дня базовых упражнений для калибровки плана. AI анализирует реальные результаты и адаптирует веса/объём |
| AI-коррекция плана | 6 источников входных данных (Strava, Hevy, GPX, текст, файл, пост-тренировка), 3 режима: merge / preference / post_workout |
| GIF-демонстрации | 1 346 анимированных GIF (360p, ~276 КБ каждый) раздаются с Firebase Hosting CDN (`https://fitnesbuster.web.app/gifs/{id}.gif`). `Cache-Control: public, max-age=31536000, immutable`. Отображение через `CachedNetworkImage` |
| Видео-демо упражнений | Кнопка YouTube + AI советы по технике от DeepSeek с кэшем в SharedPreferences |
| Календарь тренировок | Месячный вид (table_calendar), перенос тренировок на другие дни |
| Выполнение | Система фаз (подготовка 15с / выполнение / отдых), TTS озвучка упражнений, счётчик подходов, WakeLock |
| WorkoutSession | Singleton, управляемый через DI (`sl<WorkoutSession>()`), — сессия живёт между экранами, таймер по wall-clock |
| WorkoutMiniPlayer | Плавающий мини-плеер поверх всех экранов с ShellRoute: фаза, упражнение, прогресс, обратный отсчёт |
| Сохранение | SharedPreferences: `workout_done_{date}`, `workout_kcal_{date}`, `workout_sets_{date}` |
| Персональные рекорды | PR трекер — упражнение, вес, повторения, подходы |

### Питание
| Функция | Описание |
|---|---|
| AI-план | Меню на день (завтрак, обед, ужин, перекусы) с макросами, добавками, советами по готовке |
| Расчёт макросов | `NutritionService.calculateMacros(UserProfile)` — автоматический расчёт нормы белков (30%), углеводов (40%), жиров (30%) по суточной цели калорий |
| Трекер воды | Кнопки +/– стакан (250 мл), персистентность по дате |
| Ручное добавление | Имя блюда + ккал, сохраняются в SharedPreferences |
| Штрих-код | Сканирование через `mobile_scanner` + OpenFoodFacts API — питательная ценность продукта |
| Список покупок | Автоматическое извлечение ингредиентов из AI-плана питания, категоризация по 7 группам, чекбоксы с персистентностью, AI-замена ингредиента (долгое нажатие), копирование, прогресс-бар |
| Калории | Визуальный прогресс-бар съедено/цель с макросами |

### Прогресс
| Функция | Описание |
|---|---|
| Статистика по периодам | Сегодня / Неделя / Месяц / Год с баровым графиком |
| Вес | График (из Health Connect или профиля) |
| Замеры тела | Грудь, талия, бёдра, % жира с дельтами. Сохраняются в Firestore. Модель `BodyMeasurement` — в `domain/entities/` |
| Фото | 3 ракурса (спереди, сбоку, сзади) с инструкциями по позированию |
| AI-анализ | DeepSeek анализирует динамику замеров и даёт рекомендации |
| AI-дебриф | Еженедельный отчёт: оценка 1-10, adherence, сводка тренировок и питания |
| Серия | Streak — количество последовательных дней с тренировкой |
| PR трекер | Отслеживание персональных рекордов (`PersonalRecord` — в `domain/entities/`) |

### Дашборд
| Функция | Описание |
|---|---|
| Приветствие | Имя пользователя + аватар (preset/фото) + время суток |
| XP-бар | Текущий уровень, название, прогресс до следующего уровня, кнопка к достижениям |
| Ежедневные задания | 4 авто-задания (тренировка / вода / питание / шаги) с XP-наградами |
| Кольца активности | Шаги, ккал, вода (из Health Connect + SharedPreferences) |
| Recovery Score | Индекс восстановления (0–100) на базе сна (×40%), HRV (×35%), пульса покоя (×25%) |
| Карточка питания | Съедено / Цель / Сожжено (BMR + активность) / Дефицит с прогресс-баром |
| Недельный график | Реальные данные о выполненных тренировках за 7 дней |
| Социальная карточка | Быстрый доступ к Ленте / Друзьям (badge с кол-вом запросов) / Челленджам |

### Гейм-фикация
| Функция | Описание |
|---|---|
| XP-система | Опыт начисляется за тренировки (+100), воду (+20), питание (+30), шаги (+40), достижения |
| 9 уровней | Новичок → Любитель → Атлет → Профи → Ветеран → Мастер → Элита → Легенда → Чемпион (названия локализованы через `tl()`) |
| 30 достижений | 6 категорий: серия дней, тренировки, вода, шаги, питание, XP-вехи |
| AchievementsScreen | Сетка достижений с анимацией разблокировки, прогресс-барами |

### Восстановление и адаптация
| Функция | Описание |
|---|---|
| Recovery Score | Автоматический подсчёт ночного восстановления по данным Health Connect (`RecoveryScoreService`) |
| HealthAnalyticsService | Агрегирует данные Health Connect: `sumSleepMinutes`, `sumValue`, `avgValue`, `lastValue` |
| Адаптация нагрузки | При низком восстановлении (<50) — баннер с рекомендацией снижения интенсивности на 15–20% |
| TDEE авторасчёт | При изменении веса через Health Connect автоматически пересчитывается дневная цель калорий (Mifflin-St Jeor) |
| Смарт-уведомления | Напоминание о тренировке адаптируется к реальному паттерну активности (анализ 21 дня) |

### Социальные функции
| Функция | Описание |
|---|---|
| Друзья | Поиск по username, отправка/принятие/отклонение запросов, удаление |
| Лента активности | Персонализированная лента событий друзей: тренировки, PR, достижения, челленджи |
| Челленджи | Создание публичных/приватных челленджей (тренировки / шаги / серия / калории), таблица лидеров |
| FCM-уведомления | Push при получении запроса в друзья, принятии, победе в челлендже |

---

## Firebase Cloud Functions (europe-west1, Node.js 22)

| Функция | Тип | Безопасность | Назначение |
|---|---|---|---|
| `sendFriendRequest` | Callable | Валидация toUid | Создаёт запрос, отправляет FCM + in-app уведомление |
| `acceptFriendRequest` | Callable | Транзакция Firestore | Принимает запрос, добавляет в friends обоих пользователей |
| `declineFriendRequest` | Callable | — | Отклоняет запрос |
| `removeFriend` | Callable | — | Удаляет из friends обоих направлений |
| `searchUsers` | Callable | Проверка типа query, .limit(500) | Поиск по usernameLower с prefix-match, возвращает isFriend |
| `fanoutActivityEvent` | Firestore trigger | Best-effort чанки, .limit(500), retry | При записи в `activity_events/{uid}/items` — фанаут в feeds друзей |
| `createChallenge` | Callable | — | Создаёт челлендж + начальный progress-документ |
| `joinChallenge` | Callable | — | Добавляет uid в participants, создаёт progress-документ |
| `updateChallengeProgress` | Callable | — | Обновляет прогресс, FCM при достижении цели, публикует feed-событие |
| `cleanOldFeedEvents` | Scheduled (03:00) | — | Удаляет события ленты старше 30 дней |
| `recordWorkout` | Callable | Транзакция Firestore | Запись завершённой тренировки в Firestore |
| `deepseekProxy` | Callable | Rate limit 20 req/60s | Прокси для DeepSeek API — ключ в Secret Manager |
| `exerciseDbProxy` | Callable | Rate limit 30 req/60s | Прокси для ExerciseDB API |
| `seedChallenges` | Callable | Admin-only (`token.role === 'admin'`) | Инициализация дефолтных публичных челленджей |
| `fixNameLower` | Scheduled | — | Миграция: заполнение `usernameLower` для поиска |
| `cleanupDuplicateRequests` | Scheduled | — | Удаление дублированных `friend_requests` |

**Инфраструктура:** `withRetry(fn, 3)` в `shared.ts`, JSDoc на всех экспортируемых функциях, 21 константа в `constants.ts`, composite indexes в `firestore.indexes.json`, логирование 20 функций.

---

## AI-помощник

| Функция | Описание |
|---|---|
| AI-чат | Полноэкранный multi-turn чат с DeepSeek AI. Контекст: профиль пользователя, история диалога |
| Кэш чата | Hive — до 50 сообщений, восстановление при перезапуске |
| Быстрые вопросы | «Как часто тренироваться?», «Что есть после тренировки?» и др. |
| Контекстная осведомлённость | Профиль (BMR/TDEE/BMI), последние темы обсуждения |

### Профиль

| Функция | Описание |
|---|---|
| Аватар | 10 emoji-градиентов или своё фото (камера / галерея) |
| Темы | 6 динамических тем с 24 цветовыми токенами каждая |
| Язык | 15 языков (переключение UI с флагами и нативными названиями) |
| Health Connect | Синхронизация: шаги, пульс, сон, вес, вода, тренировки — 15 провайдеров |
| Достижения | Превью уровня, XP-прогресс, разблокированные значки |
| Уведомления | Смарт-напоминание о тренировке + 6 напоминаний пить воду (9:00–19:00) |

---

## Система тем (ThemePalette)

24 цветовых токена на тему: primary, primaryDark, primaryLight, accent, accentOrange, accentPurple, background, surface, surfaceLight, surfaceCard, elevated, textPrimary, textSecondary, textMuted, textOnPrimary, success, warning, error, info, primaryGradient (3-stop), accentGradient (2-stop), glowPrimary (radial), scaffoldBg, cardBg.

| # | Тема | Primary | Концепция |
|---|---|---|---|
| 1 | **Neon Dark** (Electric Volt) | `#C8FF00` | Nike Training Club × Apple Fitness+ — чёрный + кислотный лайм |
| 2 | **Ocean Blue** (Deep Horizon) | `#00CFFF` | Биолюминесцентный глубокий океан — ультра-тёмный navy + циан |
| 3 | **Sunset Warm** (Aurora Flame) | `#FF4D1A` | Северное огненное сияние — тёмно-бордовый + коралл + золотой |
| 4 | **Forest Green** (Jade Matrix) | `#00D46A` | Биолюминесцентные джунгли — почти чёрный + изумруд + мята |
| 5 | **Midnight Purple** (Nebula) | `#A855F7` | Космическая пустота + aurora borealis — пурпур + фиолет + роза |
| 6 | **CyberPunk** (Neon Tokyo) | `#00F5FF` | Максимальный киберпанк-контраст — абсолютный чёрный + циан + маджента |

Типографика: **Syne** (display, 56px–20px) + **Inter** (body, 16px–12px). 11 предопределённых стилей текста.

---

## Поддерживаемые языки (15)

| # | Язык | Код | Флаг |
|---|---|---|---|
| 1 | Русский | `ru` | 🇷🇺 |
| 2 | English | `en` | 🇬🇧 |
| 3 | Español | `es` | 🇪🇸 |
| 4 | Deutsch | `de` | 🇩🇪 |
| 5 | Français | `fr` | 🇫🇷 |
| 6 | Italiano | `it` | 🇮🇹 |
| 7 | Português | `pt` | 🇵🇹 |
| 8 | Türkçe | `tr` | 🇹🇷 |
| 9 | العربية | `ar` | 🇸🇦 |
| 10 | 中文 | `zh` | 🇨🇳 |
| 11 | 日本語 | `ja` | 🇯🇵 |
| 12 | 한국어 | `ko` | 🇰🇷 |
| 13 | हिन्दी | `hi` | 🇮🇳 |
| 14 | Українська | `uk` | 🇺🇦 |
| 15 | Беларуская | `be` | 🇧🇾 |

По умолчанию: Русский (`ru`). Локализация охватывает 845+ ключей через `AppLocalizations.tl()` / `tlp()`. Все BLoC-сообщения, роутер, сервисы и виджеты используют `tl()`. 0 хардкодированных UI-строк. Фоллбэк на английский при отсутствии перевода.

---

## Health Connect — поддерживаемые провайдеры (15)

| Провайдер | Тип подключения |
|---|---|
| Samsung Health ⌚ | Нативная запись в Health Connect |
| Google Fit / Health Connect 🔄 | Нативная запись в Health Connect |
| Health Connect (Android) 📊 | Прямой доступ |
| Garmin Connect 🏋️ | Требуется bridge (Health Sync) |
| Fitbit 💙 | Требуется bridge |
| Huawei Health 📱 | Требуется bridge |
| Zepp Life 🔵 | Требуется bridge |
| Mi Fitness ⚪ | Требуется bridge |
| Polar Flow 🔴 | Требуется bridge |
| Suunto ⏱️ | Требуется bridge |
| Coros 🟢 | Требуется bridge |
| Whoop 🟡 | Требуется bridge |
| Oura 💍 | Требуется bridge |
| Withings Health Mate ⚖️ | Требуется bridge |
| Apple Health 🍎 | HealthKit (iOS) |

Данные синхронизируются: шаги, активные ккал, общие ккал, пульс, пульс покоя, HRV, частота дыхания, вес, рост, дистанция, сон, вода, тренировки. Дедупликация шагов через `getTotalStepsInInterval`.

---

## Технологический стек

### Core
| Технология | Версия | Назначение |
|---|---|---|
| Flutter | 3.27+ | Кроссплатформенный UI (Android, iOS) |
| Dart | 3.10.3+ | Язык |
| flutter_bloc | ^9.1.1 | State management |
| go_router | ^17.3.0 | Навигация с ShellRoute |
| get_it | ^9.2.1 | Dependency Injection |
| equatable | ^2.0.5 | Сравнение состояний BLoC |
| freezed / freezed_annotation | — | Иммутабельные модели данных (24 класса, 18 автогенерированных файлов) |

### Хранение данных
| Технология | Назначение |
|---|---|
| Firebase Firestore | Профили, AI-планы, замеры, друзья, лента, челленджи, уведомления |
| Firebase Auth | Email/пароль + Google Sign-In |
| Firebase Analytics | Аналитика: экраны, тренировки, питание, онбординг |
| Firebase Cloud Functions | Бэкенд-логика: друзья, лента, челленджи, FCM, scheduled jobs |
| Firebase Messaging (FCM) | Push-уведомления: запросы в друзья, принятие, победа в челлендже |
| SharedPreferences | Ежедневный трекинг, кэш советов по упражнениям, список покупок, перенос тренировок |
| Hive | Офлайн-кэш AI-планов, истории чата, дебрифов; очередь отложенной синхронизации |

### AI и API
| Сервис | Назначение |
|---|---|
| DeepSeek API | Генерация планов тренировок и питания, анализ прогресса, AI-чат, дебриф, советы по технике, AI-коррекция плана, замена ингредиентов |
| ExerciseDB API | Pro план ($12.99/мес). Endpoint `GET /image?exerciseId={id}&resolution=360` → GIF. Ключ в Firebase Secret Manager. Прокси через Cloud Function `exerciseDbProxy` |
| Google Health Connect | Шаги, ккал, пульс, сон, вес, тренировки (Android) |
| Apple HealthKit | Аналогично (iOS) |
| OpenFoodFacts | Питательная ценность по штрих-коду |
| YouTube Search | Видео-демо упражнений (url_launcher → поиск по названию) |

### UI и анимации
| Пакет | Назначение |
|---|---|
| model_viewer_plus | 3D GLB viewer (WebView + localhost proxy) — анатомическая модель |
| syncfusion_flutter_charts | Продвинутые графики |
| shimmer | Placeholder загрузки |
| table_calendar | Календарь тренировок |
| cached_network_image | Кэширование изображений и GIF |

### Устройства и сенсоры
| Пакет | Назначение |
|---|---|
| health | Health Connect / HealthKit |
| permission_handler | Запрос разрешений |
| wakelock_plus | Экран не гаснет во время тренировки |
| flutter_tts | TTS — произносит упражнения голосом |
| mobile_scanner | Сканер штрих-кодов |
| image_picker | Камера / галерея для фото и аватаров |
| file_picker | Открытие файлов (GPX, JSON, TXT) для AI-коррекции плана |
| url_launcher | Открытие YouTube и внешних ссылок |

### Firebase (backend)
| Пакет | Версия | Назначение |
|---|---|---|
| firebase_core | ^4.10.0 | Инициализация Firebase |
| firebase_auth | ^6.5.2 | Аутентификация |
| cloud_firestore | ^6.5.0 | База данных |
| cloud_functions | ^6.0.2 | Вызов Cloud Functions |
| firebase_messaging | ^16.0.0 | FCM push-уведомления |
| firebase_analytics | ^12.4.2 | Аналитика |

### Утилиты
| Пакет | Назначение |
|---|---|
| flutter_local_notifications | Локальные push-уведомления |
| timezone | Часовые пояса для планировщика уведомлений |
| connectivity_plus | Мониторинг соединения |
| http | HTTP-клиент для DeepSeek API |
| intl | Интернационализация |
| uuid | Генерация уникальных ID |
| logger | Структурированное логирование (`appLogger`) |
| freezed / freezed_annotation | Иммутабельные модели данных |
| json_annotation / json_serializable | JSON-сериализация |

---

## SharedPreferences — ключи

Формат даты: `{year}_{month}_{day}` (например `2026_6_15`)

```
workout_done_{date}              bool    — тренировка выполнена
workout_kcal_{date}              int     — ккал сожжено на тренировке
workout_sets_{date}              int     — количество подходов
water_glasses_{date}             int     — стаканы воды
water_ml_{date}                  int     — вода в мл (glasses × 250)
eaten_cal_{date}                 int     — потреблено ккал
target_cal_{date}                int     — целевые ккал на день
manual_steps_{date}              int     — шаги введённые вручную
manual_heartrate_{date}          int     — пульс введённый вручную
workout_time_{date}              int     — время тренировки (для смарт-уведомлений)
avatar_mode                      String  — "preset" | "custom" | "initials"
avatar_preset_index              int     — 0–9
avatar_custom_path               String  — путь к фото аватара
app_theme                        int     — индекс темы (0–5)
app_language                     String  — код языка ("ru", "en", ...)
shopping_list_checked            String  — JSON Map<String, bool> — отмеченные ингредиенты
workout_calendar_overrides       String  — JSON Map<"yyyy-MM-dd", int> — переносы тренировок
exercise_tips_{exerciseId}       String  — кэш AI-советов по технике упражнения
social_username                  String  — username пользователя для социальных функций
```

## Hive — ключи кэша

```
ai_workout_{uid}            String  — JSON AI-плана тренировок
ai_meal_{uid}               String  — JSON AI-плана питания
ai_ts_{uid}                 String  — ISO timestamp последней генерации
test_week_{uid}             String  — флаг завершения тестовой недели
chat_{uid}                  String  — JSON истории AI-чата (до 50 сообщений)
debrief_{uid}               String  — JSON последнего еженедельного дебрифа
needs_sync_{uid}            String  — флаг "true" — требуется синхронизация с Firestore
```

---

## Firebase Firestore — структура

```
users/{uid}
  ├── name, email, avatarUrl, createdAt
  ├── fcmToken                              — FCM-токен для push-уведомлений
  ├── username, usernameLower               — для поиска в социальных функциях
  ├── onboarding/
  │   └── data: { goal, intensity, location, runningPreference }
  ├── profile/
  │   └── data: { weight, height, age, gender, activityLevel, medicalRestrictions, ... }
  ├── aiPlans/
  │   └── data: { workoutPlanJson, mealPlanJson, generatedAt }
  └── measurements/
      └── {measurementId}: { date, chestCm, waistCm, hipsCm, bodyFatPercent }

friend_requests/{reqId}
  └── { fromUid, fromName, toUid, status, createdAt }  — status: pending|accepted|declined

friends/{uid}/list/{friendUid}
  └── { name, addedAt }

activity_events/{uid}/items/{eventId}
  └── { type, data, timestamp }

feed/{uid}/events/{eventId}
  └── { type, fromUid, fromName, data, timestamp }

challenges/{challengeId}
  └── { title, description, goalType, targetValue, durationDays, isPublic,
        createdBy, creatorName, participants[], startDate, endDate }

challenge_progress/{challengeId}/participants/{uid}
  └── { name, currentValue, updatedAt }

notifications/{uid}/items/{notifId}
  └── { type, title, body, data, createdAt, read }
```

Имена коллекций вынесены в `FirestoreCollections` — строковые константы, нет хардкода `.collection('users')` в коде.

### Firebase Hosting (GIF CDN)

```
https://fitnesbuster.web.app/gifs/{exerciseDbId}.gif
```

- **1 346 GIF-файлов** (360p, суммарно ~376 МБ)
- Заголовки: `Cache-Control: public, max-age=31536000, immutable`
- Публичный доступ: без авторизации, без API-ключей

### Firestore Security Rules

- `users/{uid}`: чтение — любой авторизованный, запись — только владелец
- `friend_requests/{reqId}`: чтение — участники, создание — fromUid==caller, update — toUid==caller
- `friends/{uid}/list/*`: чтение — владелец, запись — только Admin SDK (Cloud Functions)
- `activity_events/{uid}/*`: чтение и запись — только владелец
- `feed/{uid}/*`: чтение — владелец, запись — только Admin SDK
- `challenges/*`: чтение — любой авторизованный, создание — createdBy==caller
- `challenge_progress/*`: чтение — любой авторизованный, запись — владелец записи

---

## Навигация (go_router)

```
/                               → SplashScreen
/login                          → LoginScreen
/register                       → RegisterScreen
/onboarding                     → OnboardingScreen
  /goal                         → GoalSelectionScreen
  /intensity                    → IntensitySelectionScreen
  /location                     → WorkoutLocationScreen
  /profile                      → ProfileSetupScreen

[ShellRoute — нижняя навигация + WorkoutMiniPlayer]
/dashboard                      → DashboardScreen
/workout                        → WorkoutPlanScreen
/nutrition                      → NutritionScreen
/progress                       → ProgressScreen
/profile                        → ProfileScreen

/workout/session/:id            → WorkoutSessionScreen
/workout/log/:id                → WorkoutLogScreen
/workout/calendar               → WorkoutCalendarScreen
/workout/execution              → WorkoutExecutionScreen
/test-week                      → TestWeekScreen
/nutrition/diary                → FoodDiaryScreen
/nutrition/meal-plan            → MealPlanScreen
/shopping-list                  → ShoppingListScreen
/health-sync                    → HealthSyncScreen
/pr                             → PrScreen
/exercises                      → ExerciseBrowserScreen
/exercises/:id                  → ExerciseDetailScreen
/chat                           → AiChatScreen
/debrief                        → WeeklyDebriefScreen
/achievements                   → AchievementsScreen
/social/feed                    → FeedScreen
/social/friends                 → FriendsScreen
/social/challenges              → ChallengesScreen
```

---

## Статус разработки

| Экран | Готовность | Примечание |
|---|---|---|
| SplashScreen | ✅ Готов | Auth check + redirect |
| LoginScreen | ✅ Готов | Email/пароль + Google Sign-In |
| RegisterScreen | ✅ Готов | Email + Firestore doc |
| Онбординг (5 шагов) | ✅ Готов | Goal → AI генерация планов |
| DashboardScreen | ✅ Готов | HC + XP-бар + Recovery Score + социальная карточка |
| WorkoutPlanScreen | ✅ Готов | AI-план с периодизацией + AI-коррекция + календарь |
| WorkoutCalendarScreen | ✅ Готов | Перенос тренировок, список ближайших |
| WorkoutExecutionScreen | ✅ Готов | Таймер, TTS, WakeLock, фазы, WorkoutMiniPlayer |
| WorkoutSessionScreen | ✅ Готов | Загружает реальный план через UserRepository |
| WorkoutLogScreen | ✅ Готов | Лог тренировки |
| ExerciseDetailScreen | ✅ Готов | GIF-демо + YouTube видео + AI советы по технике |
| ExerciseBrowserScreen | ✅ Готов | Каталог упражнений |
| TestWeekScreen | ✅ Готов | 4 дня → AI калибровка → адаптация плана |
| NutritionScreen | ✅ Готов | Трекер воды + питания |
| ShoppingListScreen | ✅ Готов | Категоризация, чекбоксы, AI-замена ингредиента |
| FoodDiaryScreen | ✅ Готов | Дневник питания |
| MealPlanScreen | ✅ Готов | AI-план питания |
| BarcodeScannerScreen | ✅ Готов | mobile_scanner + OpenFoodFacts |
| ProgressScreen | ✅ Готов | Периоды, графики, фото, замеры, AI-анализ |
| WeeklyDebriefScreen | ✅ Готов | AI-дебриф: оценка, adherence, улучшения |
| ProfileScreen | ✅ Готов | Аватар, темы, языки, HC-синхронизация, достижения |
| AchievementsScreen | ✅ Готов | XP, уровни, 30 достижений |
| HealthSyncScreen | ✅ Готов | Health Connect, 15 провайдеров |
| AiChatScreen | ✅ Готов | Multi-turn AI-чат, Hive-кэш, контекст профиля |
| PrScreen | ✅ Готов | Трекер персональных рекордов |
| FeedScreen | ✅ Готов | Лента активности друзей |
| FriendsScreen | ✅ Готов | Друзья / Запросы / Поиск (3 вкладки) |
| ChallengesScreen | ✅ Готов | Мои / Публичные, создать, таблица лидеров |

**Общая готовность: 100%** (33/33 экрана функциональны)

---

## Тестирование

```bash
flutter test
```

**337 тестов** (321 unit/widget + 16 E2E) в ~22 файлах:

| Файл | Покрытие |
|---|---|
| `test/bloc/auth_bloc_test.dart` | AuthBloc — login, register, google, logout |
| `test/bloc/user_bloc_test.dart` | UserBloc — load, update profile |
| `test/bloc/workout_bloc_test.dart` | WorkoutBloc — start, tick, complete |
| `test/bloc/nutrition_bloc_test.dart` | NutritionBloc — load, add/remove food |
| `test/bloc/ai_bloc_test.dart` | AiBloc — generate plan, ask question |
| `test/bloc/health_bloc_test.dart` | HealthBloc — fetch, watch |
| `test/bloc/health_sync_bloc_test.dart` | HealthSyncBloc — initialize, read |
| `test/bloc/onboarding_bloc_test.dart` | OnboardingBloc — 5 steps + finalize |
| `test/bloc/test_week_bloc_test.dart` | TestWeekBloc — start, record, complete |
| `test/data/auth_repository_test.dart` | AuthRepository — login/register flows |
| `test/data/user_repository_test.dart` | UserRepository — CRUD профиля |
| `test/data/settings_repository_test.dart` | SettingsRepository — safe getters/setters |
| `test/data/gamification_service_test.dart` | GamificationService — XP, уровни, достижения |
| `test/data/weekly_debrief_test.dart` | WeeklyDebrief — fromJson, defaults, round-trip |
| `test/domain/user_profile_test.dart` | UserProfile — BMR/TDEE, defaults() factory |
| `test/services/recovery_score_service_test.dart` | 17 тестов — уровни, shouldReduceIntensity, formatSleep |
| `test/services/adaptive_training_service_test.dart` | 12 тестов — calculateAdjustment, buildAdaptedPlan |
| `test/services/social_models_test.dart` | 9 тестов — FeedEvent, Challenge, ChallengeParticipant |
| `test/services/nutrition_service_test.dart` | NutritionService — calculateMacros |
| `test/services/deepseek_service_test.dart` | DeepSeekService — парсинг ответов |
| `test/services/onboarding_workflow_service_test.dart` | OnboardingWorkflowService — 3 теста |
| `test/widget_test.dart` | Smoke test |
| `test/integration/onboarding_e2e_test.dart` | **E2E** — 8 тестов (bloc_test + mockito) |
| `test/integration/workout_e2e_test.dart` | **E2E** — 8 тестов (bloc_test + mockito) |
| `test/golden/` | **Golden** — DashboardScreen + WorkoutPlanScreen (PNG сгенерированы) |

Mock-файлы генерируются через `mockito` + `build_runner`.

```bash
# Только E2E тесты
flutter test test/integration/

# Golden тесты (требуют display-сервер)
flutter test test/golden/
```

---

## 3D Анатомическая модель

### Стек

- **Источник**: Z-Anatomy (открытый Blender-проект, 2562 меша)
- **Формат**: GLB с Draco-сжатием (уровень 6), `assets/anatomy/muscles_3d.glb`
- **Рендеринг**: `model_viewer_plus` — обёртка над `<model-viewer>` web component через WebView
- **Прозрачность**: пост-обработка GLB (Python) — патчинг JSON-чанка бинарного GLB для установки `alphaMode: BLEND` и `doubleSided: true` на всех материалах

### Структура материалов

- **63 материала**: 31 группа мышц × 2 (стороны `_l` / `_r`) + `body_fill`
- Каждая сторона парной мышцы имеет **отдельный материал** (`latissimus_l`, `latissimus_r`)
- `body_fill` — 239 мешей из коллекции `7:Regions of human body` Z-Anatomy

### X-ray эффект (JavaScript в WebView)

```javascript
function isIn(matName, list) {
  for (var i = 0; i < list.length; i++) {
    var id = list[i];
    if (matName === id || matName === id + '_l' || matName === id + '_r') return true;
  }
  return false;
}
// Dart передаёт ['latissimus'] → JS матчит 'latissimus_l' и 'latissimus_r' одновременно
// Первичные мышцы: [0.91, 0.27, 0.24, 1.0]  — ярко-красный
// Вторичные:       [0.31, 0.64, 0.88, 1.0]  — ярко-синий
// Остальные:       [0.72, 0.45, 0.38, 0.18] — полупрозрачная плоть (X-ray)
// Нет подсветки:   [0.72, 0.45, 0.38, 1.0]  — нормальный тон кожи
```

---

## AI-архитектура (DeepSeek)

### Архитектура AI-слоя

`deepseek_service.dart` — **фасад (110 строк)**, делегирует вызовы 5 специализированным сервисам:

| Сервис | Файл | Назначение |
|---|---|---|
| `WorkoutPlanService` | `core/ai/services/` | Генерация + парсинг плана тренировок |
| `MealPlanService` | `core/ai/services/` | Генерация + парсинг плана питания |
| `PlanRefinementService` | `core/ai/services/` | Коррекция плана (6 источников, 3 режима) |
| `ProgressAnalyzer` | `core/ai/services/` | Анализ замеров + дебриф |
| `ChatService` | `core/ai/services/` | Multi-turn чат с историей |
| `BaseClient` | `core/ai/` | HTTP-клиент с retry, общий для всех сервисов |

### Возможности DeepSeekService (через `IDeepSeekService`)
1. **generateWorkoutPlan** — персональный недельный план с периодизацией
2. **generateMealPlan** — дневной план питания с макросами и добавками
3. **refineWorkoutPlan** — пост-тестовая калибровка на основе реальных данных
4. **correctWorkoutPlan** — AI-коррекция существующего плана (merge / preference / post_workout)
5. **parseWorkoutFromContent** — парсинг плана из произвольного текста/файла
6. **analyzeProgress** — анализ замеров тела с рекомендациями
7. **generateWeeklyDebrief** — еженедельный отчёт с оценкой и adherence
8. **askQuestion** — single-turn Q&A с контекстом профиля
9. **askWithHistory** — multi-turn чат с историей до 20 сообщений
10. **checkGoalFeasibility** — проверка реалистичности цели

### Параметры
- **Модель**: `deepseek-chat` (конфигурируется через `--dart-define=DEEPSEEK_MODEL`)
- **Temperature**: 0.7 | **Max tokens**: 8192 (планы), 2048 (чат) | **Top-p**: 0.9
- **Таймаут**: 60 секунд, 3 автоматических ретрая (кроме 401/429)
- **Ключ**: никогда не попадает в APK — только через `deepseekProxy` Cloud Function (Secret Manager)

---

## Платформы

| Платформа | Статус | Примечание |
|---|---|---|
| Android | ✅ Основная | API 26+, Health Connect, FCM, Google Sign-In |
| iOS | ✅ Поддержка | iOS 14+, HealthKit |

---

## Требования к окружению

- Google Health Connect установлен на устройстве (Android 8+)
- DeepSeek API ключ передаётся через `--dart-define=DEEPSEEK_API_KEY=sk-...`
- Файл `google-services.json` в `android/app/`
- Файл `GoogleService-Info.plist` в `ios/Runner/` (для iOS)
- Firebase проект **Blaze plan** с включёнными: Firestore, Authentication, Cloud Functions, FCM, Analytics
- SHA-1 / SHA-256 fingerprint добавлены в Firebase Console (для Google Sign-In)
- Node.js 22+ и Firebase CLI для деплоя Cloud Functions

---

## Дорожная карта

### ✅ Завершено (26–28 июня 2026)
| Задача | Статус | Описание |
| --- | --- | --- |
| Рефакторинг (Фазы 1–15) | ✅ | 73/73 проблем закрыто. Clean Architecture, freezed-сущности, декомпозиция God-классов, DI-интерфейсы, Cloud Functions безопасность, 8 пакетов удалено, 337 тестов |
| CI/CD | ✅ | GitHub Actions: flutter analyze + flutter test на каждый PR |
| DeepSeekService разделение | ✅ | 5 AI-сервисов + BaseClient + фасад (110 строк) |
| Use Cases | ✅ | CompleteTestWeekUseCase, TestWeekWorkflowService, OnboardingWorkflowService |
| Локализация | ✅ | 845+ ключей, 0 хардкодированных строк |
| Accessibility | ✅ | Semantics на ~77 виджетах в 42 файлах, touch targets ≥48dp |
| Analytics | ✅ | События в 4 BLoC-файлах через IAnalyticsService |
| Golden тесты | ✅ | DashboardScreen + WorkoutPlanScreen PNG сгенерированы |
| E2E тесты | ✅ | 16 тестов (onboarding + workout), bloc_test/mockito |
| Cloud Functions безопасность | ✅ | Rate-limiting, транзакции, admin-guard, withRetry, JSDoc, constants.ts |
| OfflineQueue | ✅ | Hive + connectivity_plus + DI |
| LoadingShimmer | ✅ | Переиспользуемый shimmer на 5 экранах |
| SemanticColors | ✅ | 11 констант, ~60 хардкодов заменено |

### Ближайшие задачи

| Задача | Приоритет | Описание |
| --- | --- | --- |
| Аудит безопасности | Высокий | GDPR, Firestore rules, Hive шифрование |
| Email-подтверждение | Средний | `sendEmailVerification()` + блокировка до подтверждения |
| Бета-тестирование | Высокий | 50–100 пользователей, Crashlytics, Retention D1/D7/D30 |

### Дальнейшее развитие

| Пункт | Функция |
| --- | --- |
| А | AI-анализ техники упражнений через камеру (MediaPipe / TensorFlow Lite) |
| Б | Раздел живых тренеров — маркетплейс для корпоративных подписок клубов |
| В | Переход на топовые AI API: Claude 4 / GPT-4o / Gemini 2.0 |
| Г | Полный автономный серверный бэкенд (Node.js + PostgreSQL + Redis) |
| Д | Полноценный iOS релиз (App Store) |
| Е | Бизнес-модель Premium: индивидуальные / семейные / корпоративные подписки |

---

## Лицензия

Код приложения: Proprietary — все права защищены.

### Сторонние материалы

#### Z-Anatomy (3D анатомические модели)

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

Подробности: [creativecommons.org/licenses/by-sa/4.0](https://creativecommons.org/licenses/by-sa/4.0/)
