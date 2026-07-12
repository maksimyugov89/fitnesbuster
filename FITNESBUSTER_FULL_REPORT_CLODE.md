# FitnesBuster — актуальный аудит продукта и план коммерческого запуска

**Дата актуализации:** 11 июля 2026 года
**Версия приложения:** `1.0.0+1`, pre-release
**Проверяемая ветка:** `feature/replace-emoji-with-illustrated-icons`
**Проверяемый commit:** `9979435` (`test: stabilize rate limiter emulator coverage`)
**Целевая платформа первого релиза:** Android
**Технологическая база релиза:** Flutter, Firebase, DeepSeek API, Health Connect
**Health release scope:** только Android; iOS/HealthKit не входят в текущий релизный контур

---

## 1. Резюме для принятия решения

FitnesBuster — функционально насыщенное pre-release приложение персонального AI-фитнес-тренера. В одном продукте объединены тренировки, питание, AI-планирование, показатели восстановления, социальные сценарии, геймификация и интерактивная анатомия.

По состоянию репозитория продукт заметно зрелее обычного MVP: есть слоистая архитектура, BLoC, DI, типизированные модели, Firebase callable backend, серверная валидация, rate limiting, локальный зашифрованный кэш, CI, security scanning и тесты нескольких уровней.

При этом приложение пока нельзя корректно называть production-ready. Кодовая база находится на стадии **beta candidate**: основные функции реализованы, но перед публичным релизом необходимо подтвердить реальный GitHub Actions run на целевой ветке, закрыть внешние Firebase/Play checks, усилить критическое UI-покрытие, подключить production-наблюдаемость и завершить store/compliance-подготовку.

### Текущий управленческий вердикт

| Область | Статус | Вывод |
|---|---|---|
| Продуктовая полнота | Высокая | Основные пользовательские контуры реализованы |
| Архитектура | Выше среднего | Хорошая база для дальнейшей разработки и тестирования |
| Backend security | Хорошая база | Ключевые мутации вынесены в callable Functions; остаются внешние и rules-тесты |
| Автоматизированное качество | Среднее/выше среднего | Linux/Flutter 3.38.5 full suite и goldens проходят; line coverage исторически 20,60%, два Windows-only golden diff задокументированы |
| Release engineering | Среднее/выше среднего | Четыре workflow, emulator gate, release workflow и локально подтверждённый Linux gate; реальный текущий Actions run ещё нужно подтвердить |
| Наблюдаемость | Недостаточная | Crashlytics и Firebase Performance в зависимостях не обнаружены |
| Локализация | Частичная | 15 локалей объявлены, но полное покрытие ключей подтверждено только для RU/EN |
| Коммерциализация | Ранняя стадия | Billing/subscription SDK и проверенная unit economics в репозитории отсутствуют |
| Готовность к закрытой бете | **Условно готов** | После прохождения P0 beta-gates |
| Готовность к публичному store-релизу | **Не подтверждена** | Нужны release, compliance, device и production smoke-gates |

### Оценка зрелости

Это внутренняя оценка по состоянию репозитория, а не «независимый рейтинг рынка».

| Направление | Оценка | Комментарий |
|---|---:|---|
| Функциональная полнота | 8,5 / 10 | Очень широкий продуктовый контур |
| Архитектура и сопровождаемость | 8,2 / 10 | Хорошее разделение слоёв; остаются крупные и слабо покрытые UI-файлы |
| Backend и защита данных | 7,5 / 10 | Сильные callable-контракты; не закрыты App Check и client rules integration tests |
| Автоматизированное тестирование | 6,5 / 10 | Хорошее количество сценариев, но невысокое покрытие production-кода |
| CI/CD и релизный процесс | 7,5 / 10 | Локальный Linux/Docker gate и release build подтверждены; текущий реальный GitHub run и store delivery не подтверждены |
| Локализация и accessibility | 5,8 / 10 | Есть 15 локалей и text scaling до 1,4x, но покрытие неравномерно |
| Observability и эксплуатация | 4,0 / 10 | Нет подтверждённых crash/performance инструментов и production SLO |
| Коммерческая готовность | 4,0 / 10 | Нет реализованного billing и подтверждённых рыночных метрик |

**Сводная инженерная зрелость:** около **7,2 / 10**.
**Сводная коммерческая готовность:** около **5,0 / 10**.

---

## 2. Методика и границы аудита

Отчёт основан на текущем дереве исходного кода, конфигурации Firebase, workflow GitHub Actions, тестах и внутренней release-документации.

Используются три уровня доказательности:

| Маркер | Значение |
|---|---|
| **Подтверждено кодом** | Реализация или конфигурация присутствует в репозитории |
| **Подтверждено локальной проверкой** | Команда успешно выполнена в текущем окружении |
| **Требует внешней проверки** | Факт зависит от Firebase Console, GitHub Actions, Play Console, Secret Manager или реального устройства |

Репозиторий сам по себе не доказывает, что Functions, rules, indexes, secrets и мобильная сборка развернуты в production. Поэтому прежние формулировки «задеплоено», «в продакшене» и «готово к нагрузке» заменены на проверяемые статусы.

Внешнее исследование конкурентов, объёма рынка, цен и финансовых прогнозов в эту актуализацию не входило. Такие данные должны оформляться отдельным market research с датированными источниками.

---

## 3. Подтверждённый технический инвентарь

### 3.1 Метрики текущего дерева

| Метрика | Текущее значение | Метод подсчёта / примечание |
|---|---:|---|
| Рабочие Dart-файлы в `lib/` | 249 | Без `*.g.dart`, `*.freezed.dart`, `*.mocks.dart` |
| Строк в этих Dart-файлах | 58 673 | Физические строки, включая комментарии и пустые строки |
| Файлы экранов | 38 | `lib/presentation/screens/**/*.dart` |
| Объявления `GoRoute` | 32 | Не равно числу файлов экранов |
| BLoC | 9 | Auth, User, Workout, Nutrition, Onboarding, Test Week, AI, Health, Health Sync |
| Domain service interfaces | 11 | Включая `ISocialService` и health abstractions |
| Переиспользуемые widget-файлы | 61 | `lib/presentation/widgets/**/*.dart` |
| Freezed domain-классы | 28 | В 9 domain entity-файлах |
| Flutter test-файлы | 49 | `test/**/*_test.dart`; добавлен отдельный Health Connect service suite |
| Cloud Functions exports | 18 | 15 callable, 1 Firestore trigger и 2 scheduled jobs |
| Упражнения в JSON-базе | 1 346 | По объектам `id` в `assets/data/exercises.json` |
| GIF-файлы в hosting-каталоге | 1 347 | Включая возможный служебный/дополнительный файл; соответствие 1:1 требует отдельной integrity-проверки |
| Объявленные локали | 15 | RU, EN, ES, DE, FR, IT, PT, TR, AR, ZH, JA, KO, HI, UK, BE |
| GitHub Actions workflows | 4 | CI, Build, Release, Security |

### 3.2 Важная корректировка прежних метрик

В старой версии отчёта одновременно использовались 319, 359 и 489 как «число тестов». Это разные исторические способы подсчёта. Актуальный проверяемый baseline:

- 48 Flutter test-файлов;
- 498 зарегистрированных результатов в полном Linux/Flutter 3.38.5 Docker-прогоне: 485 passed, 13 skipped;
- исторический полный Windows-прогон: 474 passed, 13 skipped, 2 failed golden cases;
- после старого Windows baseline добавлено 6 Health Connect regression-тестов; сфокусированный health suite 39/39 прошёл 11.07.2026;
- tracked Linux golden baselines валидны; Windows renderer даёт ожидаемые pixel diffs 0,77% и 0,59%;
- 38/38 Cloud Functions unit/spec тестов;
- 6/6 callable emulator-сценариев в последнем подтверждённом baseline;
- 20,60% line coverage production Dart-кода без generated-файлов: 4 406 / 21 391 строк.

Для внешних материалов следует использовать именно эти показатели и всегда указывать платформу, дату и правила подсчёта.

---

## 4. Архитектура и критические runtime-контракты

### 4.1 Клиентское приложение

Основной поток данных построен по схеме:

`Flutter UI → BLoC / workflow service → domain interface → repository/service → Firebase / platform API / Hive`

Сильные стороны:

- presentation-слой в основном отделён от конкретных Firebase-реализаций;
- зависимости регистрируются через GetIt по интерфейсам;
- `AuthBloc` имеет app-lifetime singleton, что важно для согласованности router/auth listener;
- `WorkoutSession` также зарегистрирован как lazy singleton, поэтому мини-плеер и экран используют одно состояние;
- AI-домен разделён на фасад и специализированные сервисы: workout plan, meal plan, refinement, progress analysis, chat и base client;
- domain-модели типизированы и в значительной части реализованы через Freezed;
- локальный Hive-кэш и offline queue используют шифрование.

Ограничения:

- наличие интерфейса не означает мгновенную замену поставщика: миграция AI потребует адаптации формата сообщений, ошибок, structured output, лимитов, стоимости и regression-тестов;
- offline queue не является универсальным offline-first слоем. В текущем коде зарегистрирован конкретный handler синхронизации AI-планов;
- крупные workout execution/session экраны зависят от таймеров, TTS и wakelock и пока почти не имеют production UI coverage.

### 4.2 Firebase backend

Все backend-компоненты используют регион `europe-west1`. Firestore-конфигурация клиента, Functions, rules и emulator направлена на named database `fitnesbuster`.

Экспортируемые функции:

- друзья: `sendFriendRequest`, `acceptFriendRequest`, `declineFriendRequest`, `removeFriend`, `searchUsers`;
- лента: `publishActivity`, `fanoutActivityEvent`;
- челленджи: `createChallenge`, `joinChallenge`, `leaveChallenge`, `deleteChallenge`, `updateChallengeProgress`, `recordWorkout`, `seedChallenges`;
- обслуживание: `cleanOldFeedEvents`, `cleanExpiredChallenges`;
- AI: `deepseekProxy`;
- аккаунт: `deleteAccount`.

Подтверждённые защитные механизмы:

- callable authentication;
- серверная валидация payload;
- транзакционный per-user rate limiting;
- `deepseekProxy` работает fail-closed при сбое rate-limit storage;
- DeepSeek API key хранится как Functions secret, а не в Flutter-клиенте;
- прямые client writes для friends/feed/challenges закрыты rules и проходят через Admin SDK callables;
- каскадный план удаления аккаунта учитывает пользовательские и взаимные данные;
- batch-размеры остаются ниже лимита Firestore.

Открытые backend-риски:

- Firebase App Check в коде и callable options не обнаружен;
- нет client-SDK integration tests для Firestore rules;
- внешний DeepSeek transport, Secret Manager и ответы провайдера не эмулируются;
- production deployment, активный secret и корректность target project требуют smoke-теста;
- политика fail-open для social endpoints сохраняет доступность при инфраструктурном сбое, но требует мониторинга злоупотреблений.

### 4.3 Health pipeline — Android device verification закрыт

Код поддерживает чтение шагов, активных и общих калорий, пульса, пульса покоя, HRV, частоты дыхания, веса, роста, дистанции, сна, воды и тренировок.

Для текущего Android-only release HRV запрашивается как RMSSD. Каждый тип теперь проверяется и читается отдельно: отсутствующее разрешение или ошибка одной необязательной метрики не обнуляет шаги, калории и остальные успешные данные.

Recovery Score вычисляется как 40% сон, 35% HRV, 25% пульс покоя. Одинаковая модель используется dashboard и контекстом генерации workout plan.

Важно: приложение интегрируется с Health Connect, а не напрямую с «15 провайдерами». Доступность Samsung Health, Garmin, Fitbit, Oura, Polar, Whoop и других источников зависит от того, записывают ли их приложения данные в системный health store. Прежнее заявление о прямой интеграции с 15 поставщиками было некорректным.

#### Подтверждённая проверка на реальном устройстве

**Дата:** 11.07.2026
**Устройство:** realme RMX3853
**ОС:** Android 16 / API 36
**Health Connect:** `2026.05.14.00.release`
**Источник контролируемых данных:** официальный Health Connect Toolbox 2.3.3; после теста синтетические записи и Toolbox удалены с устройства.

| Сценарий | Результат | Доказательство |
|---|---|---|
| Fresh install и запрос доступа | PASS | Health Connect показал 13 scoped read permissions, соответствующих manifest |
| Полная выдача разрешений | PASS | `initialized=true`, все типы прочитаны без исключений |
| Частичный доступ: HRV отозван | PASS | Шаги, калории, пульс, вес, сон, вода и дистанция сохранились; HRV стал недоступен |
| Полный отзыв разрешений | PASS после исправления | Вместо ложного «Синхронизировано: 0» показан отдельный экран отсутствия доступа |
| Повторный отказ / Android lockout | PASS после исправления | Повторный системный prompt не требуется; UI предлагает открыть Health Connect Settings |
| Settings recovery | PASS | Кнопка открывает системный Health Connect; после выдачи 13 разрешений «Проверить снова» восстанавливает данные без перезапуска |
| Ошибка одного типа | PASS | Изолированное чтение сохраняет успешные метрики; покрыто regression-тестом |
| Dashboard / Recovery | PASS | Dashboard отобразил health-метрики; Recovery Score 52, HRV 58 ms, resting HR 58 bpm |
| AI health mapper | PASS | Device probe: `aiSteps=2831`, `aiWeightKg=78.50`, `aiHrvMs=58.00` |

Подтверждённые значения и единицы в полном device probe:

| Тип | Полученное значение | Единица/преобразование |
|---|---:|---|
| Steps | 2 831 | count; Health Connect aggregation |
| Active calories | 420,00 | kcal |
| Total calories | 2 109,00 | kcal |
| Heart rate average | 57 | bpm |
| Resting heart rate | 58 | bpm |
| HRV RMSSD | 58,00 | ms |
| Respiratory rate | 16,00 | breaths/min |
| Weight | 78,50 | kg; Toolbox input 78 500 g |
| Height | 1,78 | m; UI/profile использует 178 cm |
| Distance | 5,36 | km; исходные Health Connect records в метрах |
| Hydration | 1 503,00 | ml; Health plugin возвращает литры, сервис переводит в ml |
| Sleep | 245 | minutes; UI показывает 4 ч 5 мин |
| Workout | 1 | session count |

Найденный на устройстве дефект был исправлен в `HealthConnectService`, `HealthSyncBloc` и `HealthSyncScreen`. Добавлены типизированная permission-denied ошибка, per-type permission refresh, изолированное чтение метрик и recovery UI со ссылкой в Health Connect Settings.

### 4.4 Остальные Android real-device проверки

**Дата и устройство:** 11.07.2026, realme RMX3853, Android 16 / API 36. Проверялся актуальный debug APK `com.fitnesbuster.app`; системный `font_scale` после проверки возвращён с 1.4 на исходный 1.0.

| Контур | Результат | Подтверждение / остаток |
|---|---|---|
| Google Sign-In и повторный вход | PASS | На свежей release-установке открылся системный `AccountPickerActivity`; после выбора существующего аккаунта полностью гидратированный Firestore-профиль сразу открыл dashboard без ложного перехода в onboarding |
| Named Firestore runtime reads | PASS для smoke | Profile/workout plan, feed, friends и challenges прочитаны без `permission-denied` или Firebase runtime errors. Состояние deployment/rules/indexes в Firebase Console этим не подтверждается |
| Production AI callable | PASS для smoke | Авторизованный AI chat получил и отобразил ответ через production callable/provider в пределах 20 секунд. Нужны SLO, correlation id, cost monitoring и regression dataset |
| Notifications rationale → deny → deny/lockout | PASS после исправления | Android установил `USER_FIXED`; UI больше не выдаёт ложный общий success, сохраняет sheet и предлагает Settings |
| Notifications Settings recovery | PASS | Кнопка открыла App Info → управление уведомлениями; после выдачи `POST_NOTIFICATIONS` Android показал `granted=true` |
| Gallery / photo picker | PASS | После in-app rationale открыт системный Android Photo Picker с доступом только к выбранным фото; cancel вернул в приложение без широкого media permission |
| Camera rationale и системный deny/lockout | PASS после исправления | Release-signed APK: первый и второй отказ показали recovery UI; Android установил `USER_FIXED`, кнопка Settings открыла App Info |
| Camera Settings recovery | PASS | В App Info выдано «Разрешить только во время использования»; после возврата scanner автоматически восстановил preview/status через lifecycle refresh, без перезапуска приложения |
| Location deny/Settings recovery | PASS после исправления | На realme RMX3853 / Android 16 первый системный отказ `Запретить` показал ошибку и manual fallback. Из-за OEM-поведения повторный location request не дал стабильный `deniedForever`, поэтому recovery усилен: кнопка `Настройки` показывается уже после обычного отказа. Probe подтвердил App Info → `Разрешения` → `Местоположение` → `Разрешить только во время использования приложения`, итог `LocationPermission.whileInUse` |
| Text scale 1.2 / 1.4 | PASS для проверенных экранов | Dashboard при 1.2 и Profile/Notifications при 1.4 отрисовались без overflow/crash; системный scale 1.6 по-прежнему clamp до 1.4 |
| Workout lifecycle | PASS smoke | Prep → execution → set log → rest; TTS и wakelock активировались, background/foreground сохранил таймер, mini-player восстановил сессию, штатный partial exit освободил wakelock |
| 3D anatomy | PASS smoke | Локальный GLB загрузился, camera rotation работала, выбранная грудная мышца подсветилась; FATAL/OOM/WebView errors не обнаружены |
| Exercise GIF CDN | PASS smoke | Реальные thumbnails загрузились в базе из 1 346 упражнений; полный JSON↔GIF integrity и лицензии остаются отдельным gate |

Во время notification/camera/location проверки обнаружен общий contract-риск: отрицательный результат системного permission API нельзя считать финальным success. Исправления не маскируют отказ: состояние остаётся на экране, пользователь получает Settings recovery, а camera/location recovery подтверждены через реальные Android Settings flows.

### 4.5 Проверка исправлений сессии DeepSeek от 11.07.2026

Переданный отчёт DeepSeek сопоставлен с фактическим diff, production-кодом и тестами. Девять заявленных направлений действительно присутствовали в worktree: private-route guard, серверная перепроверка Auth-пользователя, сброс Google account cache, перенос Auth-синхронизации после генерации AI-планов, исправление onboarding overlay, устранение промежуточного profileless Auth-state, восстановление encrypted Hive, merge-safe Google profile и Settings action для геолокации.

В ходе профессионального review обнаружены и закрыты четыре остаточных риска:

- глобальный `SharedPreferences`-флаг `onboarding_completed` удалён: он не был привязан к UID и мог позволить новому аккаунту B пропустить онбординг после аккаунта A;
- email/Google login теперь возвращают полностью гидратированный Firestore-профиль, а не промежуточный Firebase Auth entity без profile data;
- `deleteAccount` всегда пытается выполнить локальный sign-out, но больше не маскирует сетевой сбой callable как подтверждённое серверное удаление; `user-disabled` обрабатывается как недействительный аккаунт;
- Hive recovery очищает согласованно cache, offline queue и dead-letter encrypted boxes; очередь также умеет восстановиться после нечитаемого cipher state.

Generated Mockito mocks обновлены после расширения `IAuthRepository`. Добавлены regressions для гидратации login и сетевого сбоя `deleteAccount`; обновлены router/Auth mocks. Сфокусированный набор auth/router/onboarding/cache/permissions прошёл **84/84**, дополнительный focused suite после location-фикса прошёл **67/67**, а анализ `lib`, `test` и `integration_test` завершился с **No issues found**.

Google account picker и hydrated login дополнительно подтверждены на свежей release-установке: Android открыл системный выбор аккаунта, а существующий пользователь после входа попал непосредственно на dashboard с загруженными данными, без onboarding loop.

---

## 5. Продуктовые модули

| Модуль | Реализовано в коде | Что проверить до публичного релиза |
|---|---|---|
| Auth и профиль | Email/password, Google Sign-In, email verification, profile persistence, avatar; Google re-login PASS на Android | Email verification fresh-account flow, Firebase Console user verification, Play App Signing SHA |
| Онбординг | Цель, интенсивность, место, параметры, ограничения, health setup | Реальные устройства, back navigation, analytics funnel |
| AI-тренировки | Генерация и коррекция плана, test week, RPE/health/recovery context; production callable smoke PASS | Provider/network failure tests, SLO, safety regression, cost/latency budgets |
| Выполнение тренировки | Фазы, таймеры, отдых, TTS, wakelock, логирование; Android lifecycle smoke PASS | Автоматизированные lifecycle regressions и реальные длинные сессии |
| Упражнения | JSON-база 1 346 записей, GIF, поиск/детали; Android CDN smoke PASS | Полный integrity-аудит JSON↔GIF и лицензии |
| 3D-анатомия | GLB/model viewer integration и muscle mapping; Android interaction/highlight PASS | Расширенная device matrix, memory profiling, offline fallback, лицензия |
| Питание | AI meal plan, дневник, OpenFoodFacts/barcode, вода, shopping list | Barcode/device matrix, data quality, allergen/legal copy |
| Прогресс | Вес, замеры, фото, PR, календарь, weekly debrief | Privacy/retention фото, end-to-end persistence |
| Recovery/Health | Health sync, recovery score, dashboard/AI context; Android device verification PASS | Medical disclaimer и полная locale coverage остаются открытыми |
| Социальный модуль | Friends, feed, public/private challenges, leaderboard; production read smoke PASS | Полный write/permission matrix, abuse/report/block/moderation strategy |
| Геймификация | XP, levels, achievements, daily tasks/streaks | Anti-cheat, server authority, retention analytics |
| Уведомления | FCM и локальные уведомления; deny/lockout/Settings recovery PASS на Android | Token write/read-back, delivery, deep links, opt-out, metrics |

---

## 6. AI-контур: возможности и ограничения

### Реализовано

- генерация тренировочных планов;
- генерация meal plan;
- корректировка и импорт планов;
- multi-turn chat;
- weekly progress analysis;
- structured JSON parsing и validation;
- сопоставление Firebase callable ошибок с пользовательскими AI errors;
- retry policy;
- cached plan synchronization;
- health, recovery, RPE и DOMS context;
- серверный лимит 20 AI-запросов на пользователя в минуту;
- до 40 сообщений, до 40 000 символов на сообщение, до 8 192 output tokens.

### Коммерческие риски AI

1. Большие входные сообщения и 8 192 output tokens могут существенно увеличить стоимость и p95 latency.
2. Rate limit защищает частоту, но не задаёт месячный бюджет пользователя или тарифный quota.
3. Нет подтверждённого timeout в `https.request` к DeepSeek; зависшие provider connections нужно ограничить.
4. Нет circuit breaker и метрик provider error rate.
5. AI-рекомендации, особенно при health restrictions, не должны позиционироваться как медицинская диагностика.
6. Для смены модели нужен regression dataset на workout/meal JSON, safety и качество рекомендаций.

### Рекомендуемые production SLO

| Метрика | Начальная цель для beta |
|---|---:|
| AI success rate без пользовательских 4xx | ≥ 97% |
| p50 генерации | ≤ 15 секунд |
| p95 генерации | ≤ 40 секунд |
| Invalid structured response после retry | < 1% |
| Стоимость AI на одного активного пользователя | Задать до масштабирования beta |
| Доля cache hit для недельных планов | Измерять с первого beta build |

---

## 7. Локализация, UX и accessibility

Приложение объявляет 15 локалей и поддерживает RTL-направление для Arabic. Однако словари неравномерны:

- RU: около 909 ключей;
- EN: около 892 ключей;
- остальные 13 локалей: около 321 явного ключа каждая;
- отсутствующие значения обслуживаются fallback-механизмом, поэтому «15 полностью локализованных языков» заявлять нельзя.

Дополнительные ограничения:

- Health Sync содержит неполностью локализованный текст;
- legal documents ориентированы прежде всего на русский язык;
- text scaling ограничен максимумом 1,4x;
- ключевые экраны нужно визуально проверить при 1,2x и 1,4x и принять решение по 1,6x;
- два golden baseline расходятся только с Windows renderer на 0,77% и 0,59%; Linux/Flutter 3.38.5 Docker-прогон подтвердил оба golden как PASS.

---

## 8. Качество, тесты и CI/CD

### 8.1 Подтверждённые проверки

На 12 июля 2026 года в текущей сессии подтверждено:

- `functions`: TypeScript build — успешно;
- `functions`: 38/38 unit/spec tests — успешно.

Последний исторический baseline проекта:

- callable emulator: 6/6;
- Flutter full Windows run: 474 passed, 13 skipped, 2 golden diff;
- non-generated line coverage: 20,60%;
- analyzer: ранее проходил без issues.

Для текущего worktree `dart format --output=none --set-exit-if-changed lib/ test/ integration_test/` и `flutter analyze --no-fatal-infos --no-fatal-warnings lib test integration_test` завершились без замечаний. В Docker image `ghcr.io/cirruslabs/flutter:3.38.5` подтверждён Linux gate: оба golden PASS, полный `flutter test --coverage --reporter=expanded` — **485 passed, 13 skipped**. Functions gate подтверждён локально: TypeScript build PASS, **38/38** unit/spec PASS, **6/6** callable emulator PASS. Сфокусированный Health Connect suite прошёл 39/39; расширенный regression-набор auth/router/onboarding/cache/permissions — 84/84; повторный focused suite после location-фикса — 67/67. Location integration probe на Android прошёл 1/1. Release pipeline исправлен и подтверждён: `flutter build apk --release --no-pub` успешно собрал `build/app/outputs/flutter-apk/app-release.apk`, а `flutter build appbundle --release --no-pub` — `build/app/outputs/bundle/release/app-release.aab` на Flutter 3.38.5. Для generated-state quirk Flutter, где dev-only `integration_test` попадал в Android `GeneratedPluginRegistrant` при release-сборке, добавлен безопасный Gradle strip-task: тестовый plugin не попадает в production classpath и удаляется только из generated registrant перед release compile. AAB build выводит non-blocking warning про `CupertinoIcons` font; прямого usage `CupertinoIcons` в `lib/test/integration_test` не найдено, `uses-material-design: true` включён. Окончательным внешним gate остаётся реальный GitHub Actions run на PR/push в `master`; `gh` CLI в текущей среде не авторизован, поэтому состояние удалённых run'ов не подтверждено.

### 8.2 GitHub Actions

| Workflow | Назначение | Ограничение |
|---|---|---|
| `ci.yml` | Format, analyze, Flutter tests/coverage, Functions build/unit/emulator | Запускается для `master`; текущая feature-ветка требует PR/push verification |
| `build.yml` | APK/AAB для проверки сборки | Использует debug signing, не для Google Play |
| `release.yml` | Quality gate, release signing, GitHub Release | Требует корректных keystore secrets и не публикует автоматически в Play Store |
| `security.yml` | OSV scan Flutter/npm lockfiles | Без GHAS SARIF/dependency review для private repo |

### 8.3 Главные пробелы тестирования

- `workout_execution_screen.dart`: исторически 0/739 covered lines;
- `workout_session_screen.dart`: исторически 0/483 covered lines;
- слабое workflow-покрытие import/profile/router UI;
- отсутствуют client-SDK Firestore rules tests;
- отсутствуют mock-transport тесты DeepSeek timeout/secret/provider errors;
- skipped Firebase-dependent tests должны быть классифицированы: перенесены в emulator gate либо удалены как устаревшие;
- line coverage 20,60% недостаточно для заявления о низком regression risk всего продукта.

Цель для beta: не гнаться за формальным процентом, а закрыть 100% критических P0/P1 user journeys. После этого установить ratcheting coverage gate, например «не снижать baseline» с постепенным ростом до 35–40% на первом этапе.

---

## 9. Security, privacy и compliance

### Сильные стороны

- AI key отсутствует в клиенте;
- user-sensitive social writes проходят через server validation;
- Firestore named database согласована между слоями;
- Hive cache и offline queue используют encryption cipher;
- account deletion реализовано серверно;
- permission rationale добавлены перед чувствительными prompts;
- FCM permission не запрашивается автоматически при входе;
- Android health permissions приведены в соответствие запрашиваемым типам;
- из Android удалены избыточные `BODY_SENSORS`, `BODY_SENSORS_BACKGROUND`, `ACTIVITY_RECOGNITION`;
- Android Health Connect grant, partial revoke, full revoke и Settings recovery подтверждены на реальном устройстве.

### Что обязательно закрыть

| Приоритет | Риск | Требуемое действие |
|---|---|---|
| P0 | Production Firebase подтверждён только runtime smoke | В Console подтвердить целевой project, deployments, rules/indexes и named database; дополнить client allow/deny matrix |
| P0 | Нет подтверждённого App Check | Подключить и поэтапно включить enforcement для callable/backend |
| P0 | Store health/data declarations | Заполнить Google Play Data Safety и Health Connect declarations по фактическим flows |
| P0 | Play signing identity | Добавить Play App Signing SHA-1/SHA-256 в Firebase перед Play-distribution |
| P1 | Rules coverage | Добавить emulator tests через client SDK на allow/deny matrix |
| P1 | Abuse/moderation | Спроектировать block/report/moderation для social/feed/challenges |
| P1 | Privacy lifecycle | Зафиксировать retention/deletion policy для фото, health и analytics данных |
| P1 | API key restrictions | Проверить ограничения Firebase/Google API keys в Cloud Console |

---

## 10. Release readiness: обязательные gates

### P0 — до закрытой беты

1. Чистый PR run всех workflow на GitHub Actions: format, analyze, Flutter tests/goldens, Functions unit/emulator, Android build.
2. ~~Реальный Google Sign-In и повторный вход на Android~~ — **PASS 11.07.2026**. Fresh email verification и Play Signing identity остаются открытыми.
3. Named Firestore runtime read smoke для profile, workout plan, feed, friends и challenges — **PASS 11.07.2026**; Console deployment и write/deny matrix остаются открытыми.
4. Production AI callable smoke — **PASS 11.07.2026**; timeout/error monitoring, safety regression и cost budget остаются открытыми.
5. ~~Health Connect grant/partial revoke/full revoke/Settings recovery~~ — **закрыто 11.07.2026 на Android 16**. Gallery, notifications, camera и location deny/Settings recovery закрыты на Android. Location `deniedForever` в классическом виде на RMX3853 не воспроизводится стабильно: recovery теперь доступен уже после обычного denial и подтверждён через Settings UI.
6. Не обновлять golden baselines с Windows: Linux/Flutter 3.38.5 уже подтверждён, Windows diff признан renderer-only.
7. Crash reporting и минимальная performance telemetry до привлечения beta-пользователей.
8. Privacy policy, consent и Data Safety должны соответствовать фактическому сбору данных.

### P1 — до публичного Android-релиза

1. Play App Signing SHA и release build из Play internal testing.
2. Firestore rules client tests и App Check rollout.
3. Тестируемые adapters для clock/timer, TTS и wakelock; workout lifecycle regression tests.
4. Полная локализация целевых launch-языков; остальные языки либо переводятся, либо временно не заявляются в store listing.
5. Block/report/moderation и правила сообщества.
6. Billing/subscription implementation, restore purchases, entitlement source of truth.
7. Analytics funnel: install → registration → onboarding → first plan → first completed workout → D1/D7/D30 retention.
8. Incident runbook, rollback plan и production alerts.

### P2 — после стабильной beta

- расширение device matrix;
- оптимизация 3D/WebView и GIF CDN;
- повышение покрытия и contract tests;
- A/B framework с корректной статистикой;
- улучшение accessibility выше 1,4x;
- cost optimization AI/Firestore/Hosting.

---

## 11. Коммерческая стратегия без неподтверждённых обещаний

### 11.1 Позиционирование

Рабочее позиционирование:

> FitnesBuster — персональный AI-фитнес-компаньон, который объединяет план тренировок, питание, восстановление, обучение технике и мотивацию в одном приложении.

Позиционирование следует проверять интервью и retention-данными. Нельзя пока утверждать, что сочетание функций уникально среди всех топ-10 конкурентов: это требует отдельного актуального конкурентного исследования.

### 11.2 Приоритетная аудитория beta

Для первой beta целесообразно выбрать один основной сегмент:

- русскоязычные Android-пользователи;
- занимаются самостоятельно 2–4 раза в неделю;
- хотят готовый план и контроль прогресса;
- не готовы регулярно оплачивать персонального тренера;
- готовы подключить Health Connect, но приложение остаётся полезным и без него.

Одновременный запуск на 15 языков и для всех фитнес-сегментов размоет обратную связь и увеличит стоимость поддержки.

### 11.3 Гипотеза монетизации

В коде не обнаружен billing/subscription SDK, поэтому freemium пока является бизнес-гипотезой, а не реализованной функцией.

Рекомендуемый контур проверки:

- Free: базовый журнал, ограниченный каталог, ручное планирование, базовая статистика;
- Premium: AI workout/meal plans, расширенная адаптация, weekly debrief, глубокая аналитика;
- AI quota должна быть связана с тарифом и unit economics;
- цена определяется после willingness-to-pay интервью и анализа стоимости AI, а не из прежнего необоснованного прогноза.

### 11.4 Метрики beta

| Этап | Метрика | Начальный ориентир |
|---|---|---:|
| Acquisition | Install → registration | Измерить baseline |
| Activation | Registration → completed onboarding | ≥ 65% |
| Activation | Onboarding → first generated plan | ≥ 70% |
| Core value | First plan → first completed workout за 72 часа | ≥ 40% |
| Reliability | Crash-free users | ≥ 99,5% |
| Reliability | ANR-free sessions | ≥ 99,5% |
| AI quality | Successful structured responses | ≥ 97% |
| Retention | D7 | Целевой коридор 20–30%, затем корректировать по cohort data |
| Retention | D30 | Измерить после достаточной когорты |
| Economics | AI cost / activated user | Обязательный guardrail |

ARR, MAU, break-even и оценка компании не должны публиковаться без модели acquisition cost, conversion, churn, store commission, AI/infra cost и проверенных cohort assumptions.

---

## 12. План на 90 дней

### Недели 1–2: сделать beta измеримой и безопасной

- закрыть P0 release gates;
- подключить Crashlytics/Performance или эквивалент;
- подтвердить App Check strategy;
- добавить server/client correlation id для AI и callable ошибок;
- зафиксировать product analytics taxonomy;
- провести legal/data-flow review.

**Exit criteria:** зелёный CI, internal Android build, пройденный smoke-check, dashboard ошибок и latency, подписанный beta checklist.

### Недели 3–6: закрытая beta 30–50 пользователей

- запускать cohort волнами по 10–15 человек;
- ежедневно разбирать crashes, AI failures и onboarding drop-off;
- проводить интервью после первой и третьей тренировки;
- не расширять feature scope до устранения P0/P1 defects;
- измерить реальные AI/Firestore/Hosting costs.

**Exit criteria:** crash-free ≥99,5%, нет открытых data-loss/security P0, AI success ≥97%, понятен главный activation bottleneck.

### Недели 7–10: product hardening

- исправить top-5 причин отказа;
- закрыть workout lifecycle tests;
- улучшить onboarding и first-workout time-to-value;
- внедрить billing sandbox и entitlement tests;
- пройти Play internal testing и policy review.

**Exit criteria:** release candidate проходит полный checklist минимум два раза подряд без ручных исключений.

### Недели 11–13: staged rollout

- начать с 5% аудитории;
- заранее определить stop conditions по crashes, ANR, auth, data loss и AI errors;
- затем 20% → 50% → 100% только при стабильных SLO;
- сохранять возможность быстрого rollback.

---

## 13. Что было исправлено в этом отчёте

Удалены или скорректированы неподтверждённые заявления:

- «9,2/10 независимой оценки» заменено на прозрачную внутреннюю оценку по критериям;
- «14 Cloud Functions» исправлено на 18 экспортируемых функций;
- «33 экрана» заменено на 38 файлов экранов и 32 route declarations;
- противоречивые «319/359 тестов» заменены на актуальный baseline результатов и test-файлов;
- «15 health providers» заменено на корректную модель агрегации через Android Health Connect;
- «15 полностью локализованных языков» заменено на реальное покрытие RU/EN и частичное покрытие остальных;
- «полный offline mode» сужен до фактически зарегистрированного AI-plan sync handler;
- «всё задеплоено в production» заменено на external verification gate;
- «готово к нагрузке» заменено на результат emulator/concurrency tests без экстраполяции на production capacity;
- «смена AI-провайдера за один день» заменена на реалистичную оценку adapter + regression migration;
- неподтверждённые ARR, MAU, break-even, команда из семи специалистов и абсолютные сравнения с конкурентами удалены из фактической части.

---

## 14. Источники внутри репозитория

- `CODEX_AUDIT_FIX_CONTEXT.md` — история аудита и открытые verification gaps;
- `docs/RELEASE_SMOKE_CHECKLIST.md` — обязательные ручные сценарии;
- `docs/CI_CD.md` — workflows, baseline тестов и ограничения CI;
- `docs/TEST_COVERAGE_PRIORITIES.md` — приоритеты покрытия;
- `firebase.json`, `firestore.rules`, `firestore.indexes.json` — Firebase contract;
- `functions/src/index.ts` — список backend exports;
- `functions/src/proxies.ts` и `functions/src/rateLimitLogic.ts` — AI proxy и rate-limit policy;
- `lib/core/di/injection.dart` — lifetimes и dependency graph;
- `lib/core/cache/offline_queue.dart` — offline queue behavior;
- `lib/core/health/health_connect_service.dart` — per-type permissions, чтение и unit conversion;
- `integration_test/health_connect_device_probe.dart` — повторяемый Android device probe без Auth/Firebase;
- `test/core/health/health_connect_service_test.dart` — partial access, isolation и unit regression tests;
- `lib/core/services/recovery_score_service.dart` — Recovery Score;
- `lib/core/localization/` — локали и fallback;
- `.github/workflows/` — CI, build, release и security automation.

---

## 15. Итог

FitnesBuster уже имеет сильную продуктовую основу и инженерную структуру, достаточную для профессионально организованной закрытой beta. Главная задача сейчас — не добавлять ещё больше функций, а превратить широкий набор возможностей в доказуемо надёжный продукт: завершить реальные smoke-проверки, закрыть наблюдаемость и compliance, усилить тесты самых рискованных пользовательских потоков и получить первые cohort-данные.

Коммерчески сильная позиция проекта будет строиться не на количестве экранов и громких обещаниях, а на четырёх доказательствах:

1. пользователь быстро получает персональный план и завершает первую тренировку;
2. данные здоровья и прогресс не теряются и корректно защищены;
3. AI стабильно выдаёт валидный результат в заданном бюджете и latency;
4. пользователи возвращаются через 7 и 30 дней.

До подтверждения этих критериев корректный статус продукта: **pre-release beta candidate**, а не production-ready.

---

**Автор проекта:** Максим Югов
**Контакт:** maksim.yugov.89@gmail.com
