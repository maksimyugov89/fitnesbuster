# Отчёт о выполнении — Топ-3 ответственные задачи (BETA-HARDENING)

**Дата:** 30 июля 2026 · **Исполнитель:** Hermes Agent · **Ветка:** `feature/beta-hardening`
**Scope:** топ-3 ответственные задачи из `docs/BETA_HARDENING_PLAN.md` — Фаза 2.1–2.3 (rules whitelist), Фаза 6.1 (entitlement), Фаза 3.3 (App Check).

---

## Сводка: 3/3 задач ВЫПОЛНЕНЫ, блокеров нет

| Задача | Статус | Коммит |
|---|---|---|
| 2.1 Инвентаризация клиентских полей `users/{uid}` | ✅ ВЫПОЛНЕНО | задокументировано ниже |
| 2.2 Field-level whitelist в firestore.rules | ✅ ВЫПОЛНЕНО | `8a0013f` |
| 2.3 Emulator-матрица rules (3 новых теста, 30+ кейсов) | ✅ ВЫПОЛНЕНО | `8a0013f` |
| 6.1 `setEntitlement` callable + валидация + 7 unit-тестов | ✅ ВЫПОЛНЕНО | `611562a` |
| 3.3 App Check активация (debug/playIntegrity) | ✅ ВЫПОЛНЕНО | `ad16a4d` |

---

## Задача 2.1 — Инвентаризация клиентских записей (источник истины для whitelist)

| Поле | Файл:строка | Тип записи |
|---|---|---|
| `name`, `nameLower`, `email`, `createdAt` | `auth_repository.dart:127-132`, `:174-180` | set / create |
| `photoUrl` | `auth_repository.dart:455-462`, `user_repository.dart:58` | update / set merge |
| `profile` (вкл. dot-обновления `profile.goal`) | `user_repository.dart:62,95,224,235` | set merge / update |
| `onboarding` | `user_repository.dart:88-96,120` | set merge |
| `aiPlans` (вкл. dot `aiPlans.workoutPlan`) | `user_repository.dart:146-151,273-278,350` | set merge / update |
| `bodyMeasurements` | `user_repository.dart:245` | arrayUnion set merge |
| `testWeekCompleted` | `user_repository.dart:181` | set merge |
| `testWeekProgress`, `testWeekProgressUpdatedAt` | `test_week_progress_repository.dart:44-47` | set merge |
| `username`, `usernameLower` | `social_service.dart:95-98` | set merge |
| `fcmToken` | `social_service.dart:49,55`; `auth_repository.dart:371` (delete) | set merge / delete |
| `updatedAt` | везде | serverTimestamp |
| ~~`currentStreak`, `lastWorkoutDate`~~ | `user_repository.dart:172-176` (`bootstrapStreak`) | **SERVER-ONLY → см. блокер ниже** |

Проверено отсутствие других писателей: `settings_repository` — только SharedPreferences; `gamification_service` — без Firestore-записей; grep по всем `FirebaseFirestore`-клиентам подтвердил полноту списка.

## Задача 2.2 — rules

- `allow update` для `users/{uid}` теперь требует: владелец + `!affectedKeys().hasAny(serverOnlyUserFields())` + `affectedKeys().hasOnly(clientWritableUserFields())`.
- Паттерн `diff().affectedKeys()` (НЕ hasOnly всего документа) — merge-записи содержат серверные поля, наивная проверка сломала бы легитимные записи.
- SERVER_ONLY: `currentStreak`, `lastWorkoutDate`, `totalXp`, `xp`, `level`, `entitlement`, `subscription`, `premium`, `role`, `admin`.
- `allow create` (с legal consent) и `allow delete` — без изменений, по плану.

## Задача 2.3 — emulator-матрица (добавлено в `firestoreRules.test.js`)

1. `owner can update every client-writable profile field` — 14 легитимных полей → allow.
2. `owner cannot write server-authoritative user fields` — 10 server-only полей → deny + смешанная запись (legit + streak) → deny.
3. `owner cannot write fields outside the client-writable inventory` — неизвестные поля → deny.

## Задача 6.1 — setEntitlement

- `functions/src/entitlements.ts`: admin-only (custom claims `role=="admin"` или `admin==true`, как `seedChallenges`), пишет `users/{uid}.entitlement = {tier, source:"admin", updatedAt, expiresAt}` merge'ем.
- `functions/src/entitlementsValidation.ts`: чистая валидация (targetUid 1–128, tier ∈ {free,premium}, expiresAt ISO|null).
- Экспорт в `index.ts`. 7 unit-тестов (валидные/невалидные payload, границы).

## Задача 3.3 — App Check

- `firebase_app_check: ^0.4.5+2` в pubspec; активация в `main.dart` сразу после `Firebase.initializeApp()`: debug → `AndroidDebugProvider()`, release → `AndroidPlayIntegrityProvider()` (новый API `providerAndroid`, deprecation исправлен).
- Ошибка активации non-fatal (`appLogger.w`) — приложение работает до включения enforcement.
- **Enforcement включается вручную в Firebase Console — НЕ кодом.** Debug-токен: запустить `flutter run`, скопировать токен из логов, вписать в Console → App Check → Apps → debug tokens.

---

## Результаты самопроверки (6 шагов по каждой задаче)

| Проверка | Результат |
|---|---|
| `dart format --set-exit-if-changed` (Linux) | ✅ 0 changed |
| `flutter analyze` (Linux) | ✅ No issues found |
| `flutter test` полный suite (**Linux Docker, Flutter 3.38.5 = CI**) | ✅ **507 passed, 13 skipped, 0 failed** |
| `npm run build` (tsc) | ✅ clean |
| `npm test` (unit) | ✅ **45/45** (38 baseline + 7 новых) |
| `npm run test:emulator:exec` (rules + callables) | ✅ **13/13** (включая 3 новых rules-теста; все 4 прежних rules-теста зелёные — легитимные flow не сломаны) |
| Самоаудит `git diff master --stat` | ✅ только файлы задач; чужие изменения не закоммичены |

### Про 2 падения golden на Windows
`dashboard_golden` и `workout_plan_golden` падают на Windows как до моих изменений, так и после — доказано контрольными прогонами в Docker Linux/Flutter 3.38.5: baseline `5c38970` — 2/2 PASS, ветка — 2/2 PASS, полный suite — 507/507 PASS. Причина — платформенный рендеринг шрифтов; источник истины для goldens — Linux/CI (коммит `04a8464`). Действий не требуется; CI пройдёт зелёным.

---

## ⛔ БЛОКЕР ДЕПЛОЯ RULES (критично, прочитать перед `firebase deploy`)

Клиент всё ещё содержит запись `currentStreak`/`lastWorkoutDate` через `bootstrapStreak`:
- `lib/data/repositories/user_repository.dart:167-177` (без try/catch — бросит `permission-denied`)
- вызов из `lib/presentation/screens/dashboard/dashboard_screen.dart:303`

После деплоя новых rules эта запись будет **отклонена**. Порядок обязателен:
1. Сначала выполнить **Фазу 2.4 плана** (убрать клиентскую запись streak, источник — ответ `recordWorkout`).
2. Потом `firebase deploy --only firestore:rules,firestore:indexes`.
3. Потом деплой functions (`setEntitlement`).

До выполнения 2.4 новые rules в production **не деплоить**.

## Ручные шаги владельца (после мержа и Фазы 2.4)

1. Мерж `feature/beta-hardening` → master (CI: 4 workflow должны пройти).
2. Выполнить Фазу 2.4 → деплой rules/indexes → смоук на реальном проекте (профиль, username, FCM).
3. Деплой functions. Назначить себе `admin: true` custom claim (разовый скрипт через Admin SDK, ключ не коммитить) для `setEntitlement`.
4. Firebase Console → App Check: зарегистрировать Play Integrity, добавить debug-токен тестового устройства, включить enforcement для Cloud Functions.
