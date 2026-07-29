# FitnesBuster — План подготовки к закрытой бете (задание для AI-агента DeepSeek V4 Pro)

**Версия плана:** 1.0 · 30 июля 2026
**Основание:** аудит `docs/AUDIT_2026-07-30.md` (находки B1–B7, приоритеты P0–P1)
**Репозиторий:** `C:\Users\Despa\fitnesbuster` · Flutter 3.38.5 · Dart SDK `>=3.10.3 <4.0.0` · Node 22 · регион `europe-west1` · named Firestore database `fitnesbuster`

---

# ЧАСТЬ 0. ИНСТРУКЦИЯ ДЛЯ АГЕНТА (прочитать полностью до начала работы)

## 0.1 Твоя роль

Ты — инженер-исполнитель. Твоя задача — выполнить этот план **точно как написано**, фаза за фазой, задача за задачей. План написан так, чтобы исключить творческие отклонения. Если тебе кажется, что ты нашёл решение лучше — **ты обязан остановиться и зафиксировать предложение в отчёте**, но выполнить план как написано. Самовольное «улучшение» считается ошибкой выполнения.

## 0.2 Жёсткие запреты (нарушение = провал задачи)

1. **ЗАПРЕЩЕНО** выполнять `firebase deploy`, `firebase functions:*` с записью, любые команды, меняющие production-проект Firebase. Ты работаешь только с файлами репозитория и локальными эмуляторами.
2. **ЗАПРЕЩЕНО** добавлять зависимости, не перечисленные явно в задачах (pubspec.yaml / package.json).
3. **ЗАПРЕЩЕНО** менять версии Flutter, Dart SDK, Node, firebase-tools, gradle.
4. **ЗАПРЕЩЕНО** трогать golden-файлы (`test/golden/**`), регенерировать моки (`*.mocks.dart`) вне явного указания, менять файлы `.github/workflows/**`.
5. **ЗАПРЕЩЕНО** рефакторить код, не перечисленный в задаче. Каждый diff должен быть минимальным и относиться только к файлам задачи.
6. **ЗАПРЕЩЕНО** хардкодить секреты, ключи, токены. Всё секретное — только через `defineSecret` (Functions) или существующие env-механизмы.
7. **ЗАПРЕЩЕНО** удалять или ослаблять существующие тесты. Тесты можно добавлять и обновлять только там, где задача прямо требует.
8. **ЗАПРЕЩЕНО** менять публичные API callable-функций (имена, регион, сигнатуры request/response), кроме случаев, явно описанных в задаче.
9. Комментарии в коде — на английском (как в существующем коде), отчёты — на русском.

## 0.3 Рабочая ветка и коммиты

```bash
git checkout master && git pull
git checkout -b feature/beta-hardening
```

- Один коммит на одну задачу. Формат сообщения: `type: описание (BETA-PhN.M)`, где `type` ∈ `fix|feat|test|chore`, N — фаза, M — задача. Пример: `fix: delete fcmToken only on invalid-token errors (BETA-Ph1.1)`.
- Незакоммиченные изменения в репозитории на старте (`assets/dox/`, `IDEA.md` и пр.) **не трогать и не коммитить**.

## 0.4 Базовые команды верификации (запускать из корня репозитория)

```bash
# Flutter
dart format --output=none --set-exit-if-changed lib/ test/ integration_test/
flutter analyze --no-fatal-infos --no-fatal-warnings lib/ test/ integration_test/
flutter test --reporter=expanded

# Functions (из каталога functions/)
cd functions
npm run build
npm test                      # unit/spec, baseline: 38 passed
npm run test:emulator:exec    # emulator, baseline: 6 passed
```

**Baseline (зафиксирован на 30.07.2026):** flutter test — 498 outcomes (485 passed, 13 skipped); functions unit — 38/38; emulator — 6/6; analyze — 0 issues; format — clean. Любая твоя работа обязана сохранить или улучшить эти числа. Регрессия = провал.

## 0.5 Цикл самопроверки (обязателен после КАЖДОЙ задачи)

Выполняй строго в этом порядке:

1. **Шаг 1 — Формат и анализ.** Запусти `dart format --set-exit-if-changed` и `flutter analyze` (для backend-задач — `npm run build`). Если не зелёное → исправь → повтори. Максимум 3 итерации, затем СТОП и отчёт о блокере.
2. **Шаг 2 — Тесты затронутой области.** Запусти тесты, относящиеся к задаче (указаны в критериях приёмки). Если красные → найди причину в СВОИХ изменениях (git diff) → исправь → повтори. Запрещено «чинить» тест под код, если код не соответствует спецификации задачи — сначала сверься со спецификацией.
3. **Шаг 3 — Полный прогон.** Все команды из п. 0.4. Все зелёные → задача принята.
4. **Шаг 4 — Самоаудит diff'а.** Выполни `git diff master --stat` и проверь: изменены ТОЛЬКО файлы, перечисленные в задаче (плюс новые файлы, явно разрешённые задачей). Есть лишние файлы → откати (`git checkout -- <file>`) → вернись к шагу 1.
5. **Шаг 5 — Чек-лист задачи.** Пройди по «Критериям приёмки» задачи и ответь ДА/НЕТ на каждый пункт письменно в отчёте. Хотя бы одно НЕТ → задача не сдана, возвращайся к работе.
6. **Шаг 6 — Коммит** с сообщением по формату п. 0.3.

## 0.6 Формат финального отчёта (после всех фаз)

```
# Отчёт о выполнении плана BETA-HARDENING
## Сводка: фаз выполнено X/7, задач Y/Z
## По каждой задаче: статус (ВЫПОЛНЕНО/БЛОКЕР), ссылка на коммит, результаты самопроверки (6 шагов), отклонения от плана (если были и почему)
## Финальные метрики: flutter test outcomes, functions unit, emulator, analyze issues
## Предложения сверх плана (не реализованные — только список)
```

---

# ЧАСТЬ 1. ФАЗЫ РАБОТ

---

## ФАЗА 1. Точечные backend-фиксы (находки B2, B3, B7 из аудита)

Цель фазы: устранить три мелких дефекта Cloud Functions, каждый — с тестом. Оценка: 1 день.

### Задача 1.1 — sendPush: удалять fcmToken только при невалидном токене (B2)

**Проблема:** `functions/src/shared.ts:124-126` — `catch` удаляет `fcmToken` при ЛЮБОЙ ошибке `messaging.send`, включая временные сетевые сбои и квоты. Валидный токен стирается, пользователь перестаёт получать push.

**Файлы для изменения:**
- `functions/src/shared.ts` (только функция `sendPush`)
- `functions/test/` — новый файл `sendPushLogic.test.js`

**Спецификация решения:**
1. Вынеси решение «удалять ли токен» в чистую экспортируемую функцию в новом файле `functions/src/sendPushLogic.ts`:

```ts
/** FCM error codes that mean the token is permanently dead and must be removed. */
const DEAD_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);

/** Returns true only when the FCM error proves the token is permanently invalid. */
export function shouldDeleteFcmToken(errorCode: string | undefined): boolean {
  return errorCode !== undefined && DEAD_TOKEN_CODES.has(errorCode);
}
```

2. В `shared.ts` в `catch` блоке `sendPush` извлекай `code` из ошибки (`(e as {code?: string})?.code`) и вызывай `shouldDeleteFcmToken(code)`; удаляй токен только если она вернула `true`. При любом исходе логируй через существующий `logWarn`/`logError` (не добавляй новых логгеров).
3. Экспортируй `shouldDeleteFcmToken` из `shared.ts` через существующий export-блок.
4. Тест `functions/test/sendPushLogic.test.js` (по образцу существующих `*.test.js`, node:test): dead-token коды → true; `messaging/internal-error`, `messaging/server-unavailable`, `undefined`, пустая строка, произвольная строка → false. Минимум 6 кейсов.

**Критерии приёмки:**
- [ ] `shouldDeleteFcmToken` существует, чистая (без I/O), покрыта ≥6 тестами.
- [ ] `sendPush` удаляет токен только на dead-token кодах.
- [ ] `npm run build && npm test` — зелёное, unit-тестов стало ≥44 (38+6).
- [ ] diff затрагивает только `shared.ts`, новый `sendPushLogic.ts`, новый тест.

---

### Задача 1.2 — declineFriendRequest: проверка статуса pending (B3)

**Проблема:** `functions/src/friends.ts:147-151` — decline не проверяет `status == "pending"`. Если получатель сначала принял заявку (созданы двунаправленные friend-записи), а затем вызовет decline, статус заявки перезапишется на `declined`, а friend-записи останутся — рассинхрон данных.

**Файлы:** `functions/src/friends.ts` (только `declineFriendRequest`).

**Спецификация:**
1. После проверки `toUid !== uid` добавь:
```ts
if (reqSnap.data()!.status !== "pending") {
  throw new HttpsError("failed-precondition", "Request already handled");
}
```
(точно тот же код ошибки и стиль, что в `acceptFriendRequest`, строка 104).
2. Тест: логика слишком тонкая для отдельного чистого модуля — покрытие обеспечь через emulator-тест, если в `functions/test/emulator/` уже есть тесты жизненного цикла заявок; если есть — добавь кейс «decline после accept → FAILED_PRECONDITION». Если emulator-тестов друзей нет — ограничься ручной проверкой в отчёте и не создавай новый emulator-файл.

**Критерии приёмки:**
- [ ] Повторный decline / decline после accept возвращает `failed-precondition`.
- [ ] Стиль ошибки идентичен accept-ветке.
- [ ] `npm run build && npm test` зелёное; diff — только `friends.ts` (+ возможно один emulator-тест).

---

### Задача 1.3 — cleanOldFeedEvents: убрать полный обход users (B7)

**Проблема:** `functions/src/maintenance.ts:28-40` — ежедневно читает ВСЕ документы `users`, затем для каждого делает запрос в `feed/{uid}/events`. O(N users) чтений ежедневно; не масштабируется.

**Файлы:** `functions/src/maintenance.ts`, `firestore.indexes.json`, `functions/test/` (новый тест при наличии чистой логики).

**Спецификация:**
1. Перепиши `cleanOldFeedEvents` на collectionGroup-запрос:
```ts
const oldEvents = await db
  .collectionGroup("events")
  .where("timestamp", "<", cutoff)
  .limit(FEED_CLEANUP_LIMIT)
  .get();
```
2. Удаляй найденные документы батчем (как сейчас). Логи: `scanned` = oldEvents.size, `totalDeleted`. Никакого обхода `users` больше быть не должно.
3. **ВАЖНО — индекс:** добавь в `firestore.indexes.json` в массив `indexes`:
```json
{
  "collectionGroup": "events",
  "queryScope": "COLLECTION_GROUP",
  "fields": [{ "fieldPath": "timestamp", "order": "ASCENDING" }]
}
```
Сохрани существующее форматирование файла (2-space indent).
4. **Ограничение, которое ты обязан зафиксировать:** collectionGroup `events` захватит любую коллекцию с именем `events` (сейчас это только `feed/{uid}/events` — проверь grep'ом по `functions/src` и `lib/`, что других коллекций `events` нет, и впиши результат проверки в отчёт).
5. Пагинация: если `oldEvents.size == FEED_CLEANUP_LIMIT`, выполни повторные итерации (цикл do/while, максимум 10 итераций за запуск), чтобы вычистить накопившийся хвост; между итерациями продвигай `startAfter` по последнему документу. Если реализация цикла усложняет код сверх 30 строк — оставь одиночный батч и зафиксируй это как известное ограничение в отчёте (ежедневный запуск постепенно догонит backlog).

**Критерии приёмки:**
- [ ] Обход `db.collection("users")` в maintenance.ts отсутствует.
- [ ] Индекс добавлен, JSON валиден (проверь `node -e "JSON.parse(require('fs').readFileSync('../firestore.indexes.json'))"`).
- [ ] Проверка единственности коллекции `events` задокументирована в отчёте.
- [ ] `npm run build && npm test` зелёное; emulator-прогон зелёный.

---

## ФАЗА 2. Целостность геймификации и streak (находка B1)

Цель: сервер — единственный писатель `currentStreak`/`lastWorkoutDate`; rules запрещают клиенту запись серверных полей. Оценка: 1–2 дня.

### Задача 2.1 — Инвентаризация клиентских записей в users/{uid} (исследование, без кода)

**Действия:**
1. Найди все клиентские записи: `grep -rn "FirestoreCollections.users" lib --include="*.dart"` и `grep -rn "\.set(\|\.update(" lib/data/repositories/user_repository.dart lib/core/services/social_service.dart lib/data/repositories/auth_repository.dart`.
2. Составь полный список полей, которые клиент ЛЕГИТИМНО пишет в `users/{uid}` (ожидаемо: `name`, `username`, `usernameLower`, `nameLower`, `fcmToken`, поля профиля онбординга, avatar, measurements, aiPlans-кэш и т.п.).
3. Выпиши список в отчёт в формате таблицы: `поле | файл:строка | тип записи (set/merge/update)`.

**КРИТИЧНО:** список из этой задачи — единственный источник истины для whitelist в задаче 2.2. Если пропустишь легитимное поле — сломаешь клиент.

**Критерии приёмки:** таблица в отчёте, подтверждённая grep-выводом.

### Задача 2.2 — Field-level whitelist в firestore.rules

**Файл:** `firestore.rules` (только блок `match /users/{uid}`).

**Спецификация:**
1. Определи два списка. SERVER_ONLY (запрещены клиенту): `currentStreak`, `lastWorkoutDate`, `totalXp`, `xp`, `level`, `entitlement`, `subscription`, `premium`, `role`, `admin`. CLIENT_WRITABLE — из задачи 2.1 МИНУС SERVER_ONLY.
2. Замени правило update на:
```
allow update: if signedInAs(uid) &&
  !request.resource.data.diff(resource.data).affectedKeys()
    .hasAny(['currentStreak','lastWorkoutDate','totalXp','xp','level','entitlement','subscription','premium','role','admin']) &&
  request.resource.data.diff(resource.data).affectedKeys()
    .hasOnly([ /* CLIENT_WRITABLE из задачи 2.1 */ ]);
```
Используй паттерн `diff().affectedKeys()` (НЕ `hasOnly` на всём документе — клиент пишет merge'ем, полный документ содержит и серверные поля, проверка всего документа сломает легитимные записи).
3. `allow create` и `allow delete` не меняй.
4. Сохрани стиль комментариев файла; добавь комментарий, почему серверные поля закрыты (server-authoritative streak via recordWorkout; entitlement via Functions).

**Критерии приёмки:** rules проходят парсинг (эмулятор стартует без ошибок в задаче 2.3); whitelist покрывает ВСЕ поля из 2.1.

### Задача 2.3 — Emulator-тесты rules для users/{uid}

**Файл:** `functions/test/emulator/` — существующий файл rules-тестов (найди его; если rules-тестов нет, создай `userRules.test.js` по образцу существующих emulator-тестов: `demo-fitnesbuster` project, `initializeTestEnvironment` из `@firebase/rules-unit-testing`).

**Обязательная матрица кейсов:**
1. Владелец МОЖЕТ обновить `name` (и каждое поле из CLIENT_WRITABLE — минимум 3 репрезентативных).
2. Владелец НЕ МОЖЕТ обновить `currentStreak`, `lastWorkoutDate`, `entitlement`, `totalXp` (каждое — отдельный assertFails).
3. Чужой пользователь НЕ МОЖЕТ читать/писать документ владельца.
4. Создание профиля с валидным legal consent работает (если уже покрыто существующими тестами — не дублируй, сошлись).

**Критерии приёмки:**
- [ ] `npm run test:emulator:exec` зелёное, emulator-тестов стало 6+X (X — новые кейсы).
- [ ] Все легитимные клиентские поля из 2.1 подтверждены записью через эмулятор.

### Задача 2.4 — Убрать клиентскую запись streak (user_repository.dart:173)

**Контекст:** сервер уже пишет `currentStreak`/`lastWorkoutDate` в `recordWorkout` и возвращает `{streak}` в ответе (`functions/src/challenges.ts:407`). Клиентская запись в `lib/data/repositories/user_repository.dart:173` — второй писатель, создающий гонку; после задачи 2.2 она станет запрещённой rules и будет падать.

**Файлы:** `lib/data/repositories/user_repository.dart` + файлы вызовов (найди через grep, кто вызывает этот метод) + связанные тесты в `test/`.

**Спецификация:**
1. Удали клиентскую запись `currentStreak` в Firestore (метод/блок около строки 173).
2. Источник истины для UI — ответ `recordWorkout` (поле `streak`) и чтение документа. Найди, где клиент вызывает `recordWorkout` (grep по `recordWorkout` в lib/), и убедись, что возвращаемый `streak` попадает в состояние (bloc/provider, отображающий streak на дашборде). Если сейчас ответ игнорируется и UI читает локальное значение — обнови локальное состояние из ответа callable, НЕ вводя новых записей в Firestore.
3. НЕ меняй сигнатуру и поведение `recordWorkout` на сервере.
4. Обнови затронутые тесты; если тест проверял клиентскую запись streak — перепиши его на проверку обновления состояния из ответа callable (мок callable уже должен существовать в тестовой инфраструктуре; если нет — используй существующие паттерны моков в `test/`).

**Критерии приёмки:**
- [ ] `grep -n "currentStreak" lib/data/repositories/user_repository.dart` — только чтение (строка ~438), записи нет.
- [ ] Streak на дашборде обновляется после тренировки (по коду: ответ callable → состояние).
- [ ] `flutter analyze` 0 issues, `flutter test` — 498+X outcomes, 0 регрессий.

---

## ФАЗА 3. App Check и суточные AI-квоты (находки B5, B6)

Цель: закрыть бесплатный доступ к DeepSeek-прокси. Оценка: 2 дня.

### Задача 3.1 — Суточная квота deepseekProxy

**Файлы:** `functions/src/proxies.ts`, `functions/src/constants.ts`, `functions/src/rateLimitLogic.ts` (только если потребуется расширение чистой логики), `functions/test/` (расширение `rateLimitLogic.test.js` или новый файл).

**Спецификация:**
1. В `constants.ts` добавь: `export const DEEPSEEK_DAILY_LIMIT = 50;` и `export const RATE_LIMIT_DAILY_WINDOW_MS = ONE_DAY_MS;`
2. В `proxies.ts` после существующей поминутной проверки добавь вторую:
```ts
const dailyAllowed = await checkRateLimit(
  uid, "deepseekProxyDaily", DEEPSEEK_DAILY_LIMIT, RATE_LIMIT_DAILY_WINDOW_MS, {failClosed: true}
);
if (!dailyAllowed) throw new HttpsError("resource-exhausted", "Daily AI limit reached. Try again tomorrow.");
```
Проверь, что существующая `evaluateRateLimit` корректно обрабатывает окно произвольной длины (она должна — окно параметризовано; если есть чистая логика сброса окна, добавь unit-тест на 24-часовое окно: «запрос после истечения суток сбрасывает счётчик»).
3. НЕ меняй существующий поминутный лимит 20/мин.

**Критерии приёмки:**
- [ ] 51-й запрос за сутки → `resource-exhausted` (покрыто unit-тестом логики и/или emulator-тестом).
- [ ] `npm test` зелёное, новых тестов ≥2.

### Задача 3.2 — Валидация role в messages (B6)

**Файл:** `functions/src/proxiesValidation.ts` + его тест `functions/test/proxiesValidation.test.js`.

**Спецификация:**
1. В цикле валидации сообщений добавь проверку: `m.role` обязана быть одной из `"system" | "user" | "assistant"`, иначе `HttpsError("invalid-argument", ...)`.
2. Ограничь количество system-сообщений: не более 2 на запрос (клиент BaseClient шлёт ровно 1). Превышение → `invalid-argument`.
3. Тесты: невалидная role → throw; 3 system → throw; валидные комбинации → pass. ≥4 новых кейса.

**Критерии приёмки:** `npm test` зелёное; клиент (`BaseClient`, 1 system + user) проходит валидацию — проверь по коду `lib/core/ai/base_client.dart` и `sendMessagesList` в chat (история до 50 сообщений: system может присутствовать в начале; лимит 40 сообщений уже есть и не конфликтует).

### Задача 3.3 — App Check (клиент + конфигурация)

**Разрешённые новые зависимости:** `firebase_app_check: ^0.4.1` (проверь актуальную совместимую версию через `flutter pub add firebase_app_check` — он сам подберёт; зафиксируй в отчёте, что поставилось).

**Файлы:** `pubspec.yaml`, `lib/main.dart` (или файл инициализации Firebase — найди, где `Firebase.initializeApp`).

**Спецификация:**
1. `flutter pub add firebase_app_check`
2. Сразу после `Firebase.initializeApp()` добавь:
```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
);
```
(`kDebugMode` из `package:flutter/foundation.dart`).
3. App Check НЕ должен блокировать работу при отсутствии enforcement — enforcement включается в консоли вручную (это шаг человека, Часть 2, п. 5). В отчёте явно напиши: «enforcement не включён кодом, требуется ручной шаг в Firebase Console».
4. Добавь в отчёт инструкцию для владельца: как получить debug-токен из логов (`flutter run`, искать `App Check debug token`) и куда его вписать в консоли для тестового устройства.

**Критерии приёмки:**
- [ ] Приложение собирается (`flutter analyze` 0 issues; debug-сборка запускается — если у тебя нет устройства/эмулятора, зафиксируй это и ограничься analyze + test).
- [ ] `flutter test` без регрессий.

---

## ФАЗА 4. Crashlytics и Performance Monitoring

Цель: бета не должна быть слепой. Оценка: 0.5–1 день.

### Задача 4.1 — Подключение Crashlytics

**Разрешённые зависимости:** `firebase_crashlytics` (через `flutter pub add`).

**Файлы:** `pubspec.yaml`, `lib/main.dart` (инициализация), при необходимости `android/app/build.gradle.kts` (только если плагин требует — современные версии firebase_crashlytics не требуют ручной gradle-конфигурации; НЕ добавляй ничего в gradle, если сборка проходит без этого).

**Спецификация:**
1. После инициализации Firebase добавь:
```dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```
(`PlatformDispatcher` из `dart:ui`).
2. В `catch (e, st)` ключевых верхнеуровневых местах НЕ добавляй массовых recordError — существующий appLogger остаётся; Crashlytics ловит необработанное. Допустимо добавить `recordError` только в существующий центральный error-handler, если он есть (проверь `lib/core/initialization/`).
3. В debug-режиме отключи сбор: `await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);`

### Задача 4.2 — Performance Monitoring

**Разрешённые зависимости:** `firebase_performance`.

**Спецификация:** подключи пакет, включи автоматические трейсы (работают из коробки). Добавь ОДИН кастомный трейс `ai_plan_generation` вокруг вызова генерации AI-плана тренировок (найди в `lib/core/ai/services/workout_plan_service.dart` точку вызова callable): `Trace trace = FirebasePerformance.instance.newTrace('ai_plan_generation'); await trace.start(); ... await trace.stop();` с `finally`-гарантией stop.

**Критерии приёмки (4.1+4.2):**
- [ ] `flutter analyze` 0 issues, `flutter test` без регрессий, debug-сборка компилируется.
- [ ] В debug-режиме Crashlytics отключён.
- [ ] diff не трогает gradle-файлы без крайней необходимости (обоснуй в отчёте, если тронул).

---

## ФАЗА 5. Аналитика: 8 core-событий из мастер-плана

Цель: KPI беты должны измеряться. Оценка: 1 день.

### Задача 5.1 — Аудит существующего AnalyticsService

**Действие:** прочитай `lib/core/analytics/analytics_service.dart` и `lib/domain/services/i_analytics_service.dart`. Выпиши в отчёт: какие события уже логируются, какие из 8 core отсутствуют. НЕ переписывай сервис — работай через существующий фасад/интерфейс; если метода для события нет — добавь метод в интерфейс и реализацию, следуя существующему стилю.

### Задача 5.2 — Внедрение событий

**Таксономия (строго по мастер-плану, §19):**

| Событие | Точка внедрения (найти grep'ом, ниже ориентир) | Параметры |
|---|---|---|
| `onboarding_step` | каждый шаг онбординга (`lib/bloc/onboarding/`) | `step: int` |
| `onboarding_complete` | завершение онбординга | — |
| `plan_generated` | успешная генерация AI-плана (`workout_plan_service`) | `duration_ms: int` |
| `workout_started` | старт выполнения тренировки (`workout_execution` или workout bloc) | — |
| `workout_completed` | завершение тренировки | `duration_min: int` |
| `daily_task_completed` | выполнение ежедневного задания | `task_type: string` |
| `streak_kept` | обновление streak из ответа recordWorkout (см. 2.4) | `streak: int` |
| `ai_chat_message` | отправка сообщения в AI-чат (`chat_service`) | — |
| `ai_debrief_viewed` | открытие экрана еженедельного дебрифа | — |
| `paywall_viewed` | показ paywall-экрана (если экрана нет — пропусти событие и зафиксируй в отчёте; появится в Фазе 6) | — |
| `challenge_joined` | успешный `joinChallenge` (клиентская сторона, после ответа callable) | `challenge_id` НЕ логировать — только `goal_type: string` |
| `friend_added` | успешный `acceptFriendRequest` (клиентская сторона) | — |

**Правила:**
- Имена событий и параметров — ровно как в таблице (snake_case, требование Firebase Analytics).
- Никаких PII в параметрах (никаких uid, имён, email).
- Логируй на клиенте ПОСЛЕ успешного результата операции, не до.
- Каждая точка — через существующий IAnalyticsService (никаких прямых вызовов FirebaseAnalytics из UI/bloc).

**Критерии приёмки:**
- [ ] Все реализуемые события таблицы внедрены; отсутствующие зафиксированы с причиной.
- [ ] Прямых вызовов `FirebaseAnalytics.instance` вне analytics_service — нет (проверь grep'ом).
- [ ] `flutter analyze` 0 issues; тесты без регрессий; добавь unit-тест, что сервис логирует событие с корректным именем (по образцу существующих тестов сервисов, если они есть).

---

## ФАЗА 6. Entitlement-модель и paywall-заглушка (без реальных платежей)

**ВАЖНО — граница задачи:** реальные платежи (Google Play Billing, ЮKassa) в эту фазу НЕ входят — это осознанное решение владельца, платёжный контур подключается после беты. Твоя задача — только модель доступа и UI-заглушка. НЕ интегрируй `in_app_purchase` или другие billing SDK. Оценка: 1–1.5 дня.

### Задача 6.1 — Серверная entitlement-модель

**Файлы:** `functions/src/` (новый `entitlements.ts` + экспорт в `index.ts`), `functions/test/` (тест).

**Спецификация:**
1. Модель: поле `entitlement` в `users/{uid}`: `{tier: "free"|"premium", source: "admin"|"billing", updatedAt: Timestamp, expiresAt: Timestamp|null}`. Запись — только через Functions (клиенту уже запрещена в задаче 2.2 списком SERVER_ONLY).
2. Новая callable `setEntitlement` (region `europe-west1`): admin-only по образцу `seedChallenges` (`functions/src/challenges.ts:418-428` — та же проверка custom claims). Валидация входа: `targetUid` (непустая строка), `tier` ∈ {free, premium}, `expiresAt` (ISO-строка или null). Rate limit не требуется (admin-only).
3. Тест чистой валидации (по образцу `*Validation.ts`): ≥5 кейсов.

### Задача 6.2 — Клиентское чтение entitlement и paywall-заглушка

**Файлы:** клиентские (определяются поиском: user model, profile/bloc, router) + новый экран `lib/presentation/screens/paywall/paywall_screen.dart`.

**Спецификация:**
1. Добавь `entitlement` в клиентскую модель пользователя (freezed-модель — найди, где парсится `users/{uid}`; добавь поле с дефолтом free при отсутствии). После изменения freezed-модели ЗАПУСТИ кодогенерацию: `dart run build_runner build --delete-conflicting-outputs` (это единственное разрешённое место для регенерации).
2. Новый экран paywall: минималистичный, в существующей теме приложения, локализованные строки RU+EN (добавь ключи в ОБА словаря `lib/core/localization/translations/ru.dart` и `en.dart`; остальные 13 локалей НЕ трогай — fallback покроет). Содержание: два тарифа (Индивидуальный 499 ₽/мес, 3 499 ₽/год — цены из мастер-плана §17.1) и текст «Оплата скоро будет доступна. В бета-тесте Premium предоставляется бесплатно». Кнопка оплаты — disabled.
3. Маршрут: добавь GoRoute по существующему образцу; точка входа — НЕ добавляй навязчивых баннеров; достаточно, чтобы экран был доступен из профиля/настроек (одна строка-ссылка «Premium»).
4. Логирование `paywall_viewed` из Фазы 5 — при открытии экрана.

**Критерии приёмки:**
- [ ] `setEntitlement` admin-only, валидирует вход, покрыт тестами; экспортирован в `index.ts`.
- [ ] Клиент читает entitlement, дефолт free; freezed сгенерирован и закоммичен.
- [ ] Paywall собирается, RU/EN ключи на месте, `paywall_viewed` логируется.
- [ ] `flutter analyze` 0 issues; `flutter test` без регрессий; `npm test` зелёное.

---

## ФАЗА 7. Финальная интеграционная проверка

### Задача 7.1 — Полный прогон и самоаудит

1. Все команды п. 0.4 — зелёные.
2. `git diff master --stat` — проверь, что суммарный diff покрывает ТОЛЬКО файлы задач фаз 1–6. Выпиши полный список изменённых файлов в отчёт с привязкой к задачам.
3. Проверь отсутствие случайных изменений: `git status` не должен содержать неотслеживаемых файлов вне разрешённых задачами.
4. Проверь, что число тестов выросло, а не упало: flutter test outcomes ≥ 498, functions unit ≥ 38, emulator ≥ 6.

### Задача 7.2 — Финальный отчёт

Сформируй отчёт по формату п. 0.6 и сохрани его в `docs/BETA_HARDENING_REPORT.md`.

---

# ЧАСТЬ 2. ШАГИ ДЛЯ ЧЕЛОВЕКА (НЕ для агента)

Агенту выполнять ЗАПРЕЩЕНО. Контрольный список для владельца после приёмки фаз 1–7:

1. **Ревью и мерж** ветки `feature/beta-hardening` в master (CI должен пройти: 4 workflow).
2. **Деплой rules:** `firebase deploy --only firestore:rules,firestore:indexes` — после деплоя смоук-тест на реальном проекте: сохранение профиля, установка username, FCM-токен (проверяет, что whitelist из 2.2 не забыл легитимные поля).
3. **Деплой Functions:** `cd functions && npm run deploy` (или точечно по изменённым функциям).
4. **App Check enforcement:** Firebase Console → App Check → зарегистрировать Play Integrity для Android-приложения → включить enforcement для Cloud Functions. Добавить debug-токен тестового устройства (инструкция — в отчёте агента, задача 3.3).
5. **Crashlytics:** проверить в консоли появление первого события (тестовый краш через `FirebaseCrashlytics.instance.crash()` на debug-сборке с включённым сбором — временно, потом убрать).
6. **Admin-claim для setEntitlement:** назначить `admin: true` владельцу через Admin SDK (разовый скрипт локально, ключ сервисного аккаунта не коммитить).
7. **Store-документация** (не код): Google Play Console → Data Safety (типы данных: health & fitness, personal info — по `docs/PERMISSIONS_AUDIT.md`); privacy policy URL (хостинг на Firebase Hosting, каталог `public/`); provenance-реестр GIF/упражнений (из мастер-плана, Приложение J).
8. **Закрытая бета:** трек Internal/Closed testing в Play Console, 30–50 тестеров, чек-лист `docs/RELEASE_SMOKE_CHECKLIST.md`.

---

# ЧАСТЬ 3. КАРТА «ЗАДАЧА → НАХОДКА АУДИТА»

| Задача | Находка | Приоритет аудита |
|---|---|---|
| 1.1 | B2 (fcmToken) | P1 |
| 1.2 | B3 (decline status) | P1 |
| 1.3 | B7 (feed cleanup) | P1 |
| 2.1–2.4 | B1 (rules whitelist, streak) | P0 |
| 3.1–3.3 | B5, B6 (App Check, квоты, role) | P0 |
| 4.1–4.2 | Observability gap | P0 |
| 5.1–5.2 | Analytics gap (KPI §19 плана) | P0 |
| 6.1–6.2 | Billing/entitlement (минимум для беты) | P0 |
| Часть 2 | Store delivery, деплой | P0 (человек) |

**Ожидаемый результат:** после мержа и ручных шагов проект готов к закрытой бете 30–50 пользователей по критериям мастер-плана §22, кроме реального биллинга (осознанно отложен).
