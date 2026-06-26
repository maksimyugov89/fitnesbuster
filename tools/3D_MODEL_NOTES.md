# 3D Анатомическая модель — Рабочие заметки

## Обзор проекта

Приложение **fitnesbuster** использует 3D анатомическую модель из проекта **Z-Anatomy** (Blender-файл).
Модель экспортируется в формат GLB и отображается через `model-viewer-plus` в WebView.

- **Источник модели:** `C:\Users\Despa\Downloads\Z-Anatomy\Z-Anatomy.blend` (356 MB, Blender 5.1)
- **Выходной файл:** `C:\Users\Despa\fitnesbuster\assets\anatomy\muscles_3d.glb`
- **Экспортный скрипт:** `C:\Users\Despa\fitnesbuster\tools\blender_export_muscles.py`
- **Blender:** `C:\Program Files\Blender Foundation\Blender 5.1\blender.exe`
- **Команда запуска экспорта:**
  ```
  blender -b Z-Anatomy.blend --python blender_export_muscles.py
  ```

---

## Архитектура экспортного скрипта

### Проходы экспорта (Passes)

| Pass | Список | Материал | Описание |
|------|--------|----------|----------|
| 1 | `MUSCLE_MAP` | `muscle_id_l` / `muscle_id_r` | Мышцы с подсветкой по упражнениям (двусторонние) |
| 2 | `all_muscle_names.json` | `body_fill` | Все остальные мышцы (видимые, без подсветки) |
| 3 | `BONE_FILL_NAMES` | `bone_fill` | Кости скелета (слоновая кость) |
| 3.5 | `SKULL_SURFACE_NAMES` | `body_fill` | Поверхности черепа/лица (телесный цвет, без белых пятен) |
| 3.6 | `TEETH_NAMES` | `bone_fill` | Зубы (слоновая кость, обход фильтра моляров) |
| 4 | `MIRROR_TO_LEFT` | `bone_fill` | Зеркало костей: правая сторона → левая |
| 4 | `MIRROR_TO_LEFT_BODY` | `body_fill` | Зеркало мягких тканей: правая → левая |

### Цвета материалов

```python
NEUTRAL = (0.72, 0.45, 0.38, 1.0)  # тёплый телесный / мышечный
BONE    = (0.88, 0.82, 0.66, 1.0)  # слоновая кость для костей
```

### Зеркалирование (BMesh world-space)

Алгоритм: `world_mat @ v.co` → инвертировать X → `bmesh.ops.reverse_faces()` (для правильных нормалей).
Объекты из `MIRROR_TO_LEFT` и `MIRROR_TO_LEFT_BODY` не имеют левой копии в Z-Anatomy — создаются программно.

### Фильтры пропуска

```python
VESSEL_KW   — артерии, вены, лимфа
NERVE_KW    — нервы, сплетения, ганглии
OTHER_SKIP_KW — region, lobule, brain, органы, molar, premolar, incisor...
```

Pass 3.5 (`SKULL_SURFACE_NAMES`) **обходит** `OTHER_SKIP_KW`, что позволяет экспортировать
объекты с ключевыми словами "region" и другими.

---

## Текущее состояние (июнь 2026)

**Статистика последнего экспорта:**
- Объектов: **666**
- Размер GLB: **16.67 MB** (Draco level 10)
- Зеркал: **42**

---

## SKULL_SURFACE_NAMES — текущее содержимое

```python
SKULL_SURFACE_NAMES = [
    'Frontal bone',
    'Left parietal bone', 'Parietal bone.r',
    'Occipital bone',
    'Nasal cartilages.l', 'Nasal cartilages.r',
    'Nasal cartilages.001', 'Nasal cartilages.l.001', 'Nasal cartilages.r.001',
    'Vertex.l', 'Vertex.r',
    'Sclera.r.001',
    'Mandible',
    'Maxilla.l', 'Maxilla.r',
    'Gingiva (inferior)', 'Gingiva (superior)',
    'Gingiva of lower jaw', 'Gingiva of upper jaw',
]
```

---

## MIRROR_TO_LEFT — текущее содержимое (кости)

```
Scapula.r, Clavicle.r
Radius.r, Ulna.r
Scaphoid/Lunate/Triquetrum/Pisiform/Trapezium/Trapezoid/Capitate/Hamate bone.r
1st-5th metacarpal bone.r
Proximal/Distal phalanx of 1st finger.r         ← большой палец (добавлен)
Proximal/Middle/Distal phalanx of 2d-5th finger.r
```

## MIRROR_TO_LEFT_BODY — текущее содержимое (мягкие ткани)

```
Levator palpebrae superioris.r
Sclera.r.001
Medial/Lateral/Superior/Inferior rectus muscle.r
Superior/Inferior oblique muscle.r
Superior/Inferior tarsus.r
Common tendinous ring.r
```

---

## История решённых проблем

### 1. Тёмная зона (gap) на макушке черепа
**Проблема:** Верхняя часть черепа не покрыта мышцами — тёмный просвет.  
**Решение:** `Frontal bone`, `Left parietal bone`, `Parietal bone.r`, `Occipital bone`
добавлены в `SKULL_SURFACE_NAMES` как `body_fill` (телесный) вместо `bone_fill` (белый).
Дополнительно: `Vertex.l`, `Vertex.r` — заплатки на самой макушке.  
**Статус:** Частично решено. Правая сторона покрыта хорошо. Левая — см. открытые вопросы.

### 2. Белый купол черепа (ivory dome)
**Проблема:** При использовании `bone_fill` кости черепа отображались как белый купол.  
**Решение:** Кости черепа перенесены в `SKULL_SURFACE_NAMES` → материал `body_fill`.

### 3. Кожа вместо мышц (region objects)
**Проблема:** `Parietal region.l/.r`, `Frontal region.l/.r`, `Occipital region.l/.r`,
`Buccal region`, `Oral region` — гладкие кожные меши без мышечной текстуры.
Когда добавлялись как `body_fill`, они закрывали настоящие мышцы (Temporoparietalis и др.)
плоской кожей.  
**Решение:** Все `*_region` объекты убраны. Мышцы теперь видны напрямую.

### 4. Белый артефакт на нижней челюсти (ivory jaw)
**Проблема:** `Mandible`, `Maxilla.l/.r` экспортировались как `bone_fill` (слоновая кость)
→ белые пятна при виде сбоку.  
**Решение:** Перенесены в `SKULL_SURFACE_NAMES` → `body_fill` (телесный).

### 5. Артефакты губ
**Проблема:** `Labial commissure.l/.r`, `Philtrum.l/.r`, `Tubercle of upper lip.l/.r`
выглядели как пластиковые выступы, не похожие на мышцы.  
**Решение:** Удалены из `SKULL_SURFACE_NAMES`.

### 6. Nasolabial sulcus — артефакт сбоку
**Проблема:** `Nasolabial sulcus.l/.r` добавлялись для заполнения носогубной зоны,
но при виде сбоку давали заметный выступающий гребень-артефакт.  
**Решение:** Удалены из `SKULL_SURFACE_NAMES`.

### 7. Дёсны (Gingiva) — цвет кости
**Проблема:** `Gingiva (inferior/superior)`, `Gingiva of lower/upper jaw` были в `TEETH_NAMES`
→ материал `bone_fill` (слоновая кость). Дёсны — мягкая ткань, не кость.  
**Решение:** Перенесены в `SKULL_SURFACE_NAMES` → `body_fill` (телесный).

### 8. Асимметрия глаз (левый глаз пустой)
**Проблема:** В Z-Anatomy все глазные мышцы и структуры существуют только как `.r`.
Левый глаз был пустым.  
**Решение:** Добавлены в `MIRROR_TO_LEFT_BODY`: `Levator palpebrae superioris.r`,
`Sclera.r.001`, все 6 прямых/косых мышц, тарзальные пластинки, кольцо Зинна.

### 9. Кости большого пальца левой руки
**Проблема:** В Z-Anatomy кости большого пальца левой руки называются
`Proximal/Distal phalanx of hand-1st finger.l` (другое именование) — они существуют
в Blender файле но расположены неправильно (возможно на позиции правой руки).  
**Решение:** `of hand-1st finger.l` убраны из `BONE_FILL_NAMES`. Вместо них
`Proximal phalanx of 1st finger.r` и `Distal phalanx of 1st finger.r`
добавлены в `MIRROR_TO_LEFT` → зеркалируются корректно.

### 10. Отсутствие Buccinator muscle (щёчная мышца)
**Проблема:** Носогубный треугольник не покрыт мышцами.  
**Исследование:** `Buccinator muscle.l/.r` **полностью отсутствуют** в Z-Anatomy.
Подтверждено несколькими сканами (buccal_scan.json, asymmetric_buccal.json).  
**Статус:** Нерешаемо в рамках Z-Anatomy — фундаментальное ограничение модели.

---

## Именование в Z-Anatomy

| Суффикс в Z-Anatomy | Анатомическая сторона | Вид спереди |
|---|---|---|
| `.r` | Правая сторона пациента | Левая сторона экрана |
| `.l` | Левая сторона пациента | Правая сторона экрана |

**Важно:** При виде **сзади** — наоборот: `.r` = правая сторона экрана.

---

## Инструменты сканирования (в tools/)

| Файл | Описание |
|------|----------|
| `blender_scan_skull_top.py` | Все объекты с Z > 1.45 (верхушка черепа) |
| `blender_scan_mouth_area.py` | Объекты в зоне рта Z=1.44–1.57 |
| `blender_scan_buccal_muscles.py` | Поиск мышц в зоне щеки |
| `blender_scan_asymmetric_buccal.py` | Односторонние объекты в зоне щеки |
| `blender_scan_face_onesided.py` | Все односторонние объекты лица Z=1.47–1.60 |
| `blender_scan_chin_onesided.py` | Односторонние объекты зоны подбородка Z=1.44–1.54 |
| `blender_scan_thumb.py` | Кости большого пальца, проверка именования |

**Результаты сканов:**
- `skull_top_scan.json` — 517 объектов, 15 асимметричных (все глазные мышцы)
- `face_onesided.json` — 11 односторонних (все глазные, Z=1.584–1.607)
- `buccal_scan.json` — 0 настоящих мышц в щёчной зоне
- `chin_onesided.json` — 0 асимметричных в зоне подбородка
- `thumb_scan.json` — `of hand-1st finger.l` существуют, но расположены неверно

---

## Открытые вопросы / Текущие дефекты

### 1. Асимметрия теменной зоны (скриншот 22.06.2026)
**Описание:** При виде **сзади сверху**, левая сторона теменной области (правая сторона
экрана при виде сзади = **левая** сторона модели) выглядит темнее/менее покрытой,
чем правая.  
**Вероятная причина:** В SKULL_SURFACE_NAMES используются:
- `'Left parietal bone'` (модельная левая = viewer's right сзади)
- `'Parietal bone.r'` (модельная правая = viewer's left сзади)

Геометрия этих двух объектов в Z-Anatomy может быть разной — `Left parietal bone`
(без суффикса `.l`) может иметь другую форму или покрывать меньшую площадь.  
**Возможное решение:** Проверить геометрию обоих теменных костей в Blender.
Возможно добавить `Temporal region.l` только для темпоральной зоны без закрытия мышц.

### 2. Носогубный треугольник (gap)
**Описание:** Зона между носом и уголками рта визуально пустая.  
**Причина:** Buccinator muscle отсутствует в Z-Anatomy. Nasolabial sulcus убран
из-за артефактного вида сбоку. Buccal/Oral region объекты дают "кожу", не мышцы.  
**Статус:** Принято как ограничение Z-Anatomy.

### 3. Лицевые мышцы нижней челюсти (предыдущий скриншот)
**Описание:** Пользователь указал на мышцу в зоне нижней челюсти, которую хотел
зеркалировать. Скан показал 0 асимметричных объектов в Z=1.44–1.54 — все мышцы
подбородка двусторонние. Возможно визуальный дефект рендеринга или покрытия, а не
реальное отсутствие объекта.  
**Статус:** Требует повторного исследования при следующей сессии.

---

## Конфигурация model-viewer (Flutter)

**Файл виджета:** `lib/presentation/widgets/muscle_map_3d_widget.dart`

**Параметры:**
- `camera-orbit="0deg 80deg 115%"` — стартовая позиция камеры (фронт)
- `auto-rotate` — вращение через 3 сек
- `rotation-per-second="15deg"`
- `shadow-intensity="0"` — без теней

**JavaScript:**
- `MUSCLE_CAM` — словарь позиций камеры по muscle_id для автозума
- `applyColors()` — применяет подсветку выбранных мышц (красный / синий)
- `bone_fill` при наличии подсветки становится полупрозрачным (alpha=0.40, BLEND)
- Polling каждые 250ms до 10 сек — ждёт загрузки материалов модели

---

## Команды сборки и установки

```powershell
# Экспорт GLB из Blender
& "C:\Program Files\Blender Foundation\Blender 5.1\blender.exe" `
  "C:\Users\Despa\Downloads\Z-Anatomy\Z-Anatomy.blend" `
  --background --python `
  "C:\Users\Despa\fitnesbuster\tools\blender_export_muscles.py"

# Flutter сборка APK
flutter build apk --release --target-platform android-arm64

# Установка на устройство
adb install -r "build\app\outputs\flutter-apk\app-release.apk"

# Запуск приложения
adb shell monkey -p com.example.fitnesbuster -c android.intent.category.LAUNCHER 1

# Логи Flutter
adb logcat -v time flutter:V *:S
```
