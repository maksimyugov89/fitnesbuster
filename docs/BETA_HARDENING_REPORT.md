# Отчёт о выполнении плана BETA-HARDENING

**Дата завершения:** 31 июля 2026
**Исполнитель:** Hermes Agent
**Целевая ветка:** `master`

## Сводка

План `docs/BETA_HARDENING_PLAN.md` выполнен по фазам 1–7. Backend-hardening, App Check, observability, продуктовая аналитика, entitlement-модель и paywall-заглушка реализованы. Firestore-конфигурация и изменённая scheduled Function задеплоены в production.

Единственный внешний незакрытый статус — hosted GitHub Actions: jobs не запускаются из-за account billing/spending-limit. Это инфраструктурная блокировка аккаунта GitHub, а не результат тестов. Локальные CI-equivalent gates полностью зелёные.

## Выполнение фаз

| Фаза | Результат | Статус |
|---|---|---|
| 1 | selective FCM token deletion; pending-only decline; collection-group feed cleanup | ✅ |
| 2 | field-level Firestore whitelist; server-authoritative streak и migration seed | ✅ |
| 3 | 50/day AI quota; role/system validation; App Check client + callable enforcement | ✅ |
| 4 | Crashlytics; Performance trace `ai_plan_generation` | ✅ |
| 5 | обязательная аналитическая таксономия и физические call-sites без PII | ✅ |
| 6 | admin-only `setEntitlement`; client entitlement; RU/EN paywall без billing SDK | ✅ |
| 7 | unit/emulator/Flutter/Linux regression; deployment; device smoke; отчёт | ✅ |

## Итоговые проверки

| Проверка | Результат |
|---|---|
| Functions TypeScript build | ✅ clean |
| Functions unit tests | ✅ 52/52 |
| Firebase emulator tests | ✅ 15/15 |
| Dart format CI gate | ✅ 360 файлов, 0 изменений |
| Flutter analyze | ✅ 0 issues |
| Flutter Linux Docker 3.38.5 | ✅ 508 passed, 13 skipped, 0 failed |
| Targeted entitlement tests | ✅ 2/2 |
| Targeted localization completeness | ✅ 1/1 |
| Android debug build | ✅ `app-debug.apk` собран |
| Realme install | ✅ `adb install -r` → `Success` |
| Realme launch smoke | ✅ Crashlytics initialized; нет `FATAL EXCEPTION`/`E/flutter` |

## Production deployment

1. Создан pre-deploy backup:
   `C:\Users\Despa\fitnesbuster-backups\2026-07-31_04-08-30-pre-final-beta-hardening`.
2. Firestore indexes deployment завершён успешно.
3. Попытка добавить composite index `events(timestamp)` была корректно отклонена Firestore как избыточная: collection-group query по единственному полю использует single-field index. Избыточная запись удалена из `firestore.indexes.json`.
4. `cleanOldFeedEvents` обновлена в production: Functions v2, scheduled, `europe-west1`, Node.js 22.
5. Остальные production Functions повторно не выкатывались без необходимости.

## Аналитика и приватность

Физически подключены core-события:

- `workout_started`;
- `workout_completed` (`duration_min`);
- `onboarding_step` (`step`);
- `onboarding_complete`;
- `plan_generated` (`duration_ms`);
- `daily_task_completed` (`task_type`), только при первом пересечении water goal;
- `streak_kept` (`streak_length`);
- `ai_chat_message` без текста prompt/response;
- `ai_debrief_viewed`;
- `challenge_joined` (`goal_type`);
- `friend_added`;
- `paywall_viewed`.

Прямых обращений к `FirebaseAnalytics.instance` вне `AnalyticsService` не обнаружено. Email, имя, username, AI-текст и медицинские ограничения в новые события не передаются.

## Entitlement и paywall

- В `UserEntity` добавлен безопасный entitlement с default tier `free`.
- Firestore `Timestamp` для `updatedAt`/`expiresAt` читается в клиентскую модель.
- Paywall доступен из профиля, локализован для RU/EN; остальные локали используют EN fallback.
- Кнопка оплаты намеренно disabled и сообщает, что платежи появятся после беты.
- Billing SDK и реальные платежи не добавлялись.

## Дополнительные исправления

- Android Firebase app ID в `firebase_options.dart` синхронизирован с `android/app/google-services.json`; секреты не выводились.
- Временные one-off credential scripts удалены/отсутствуют.
- Пользовательский stash `pre-merge local modifications (pre-existing, not from beta-hardening)` не применялся и не удалялся.
- Форматирование baseline приведено к существующему CI-gate `dart format --output=none --set-exit-if-changed lib/ test/ integration_test/`.

## Внешний blocker GitHub Actions

GitHub-hosted jobs ранее завершались до запуска шагов из-за billing/spending-limit аккаунта; для одного run GitHub не предоставил job log (`log not found`). Чтобы получить зелёные badges hosted CI, владелец аккаунта должен восстановить GitHub Actions billing/spending limit, после чего workflows следует rerun. До этого нельзя честно заявлять зелёный hosted CI, хотя эквивалентные локальные gates успешно выполнены.
