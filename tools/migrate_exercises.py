"""
ExerciseDB Migration Script
Fetches all exercises from ExerciseDB RapidAPI and generates a clean exercises.json
with correct ExMuscle enum names (critical for 3D muscle viewer).

Run: python tools/migrate_exercises.py
Output: assets/data/exercises.json (replaces existing)
API cost: ~100-150 requests total (well within 690/month free tier)
"""
import json
import time
import urllib.request
import urllib.error
import os
import re

API_KEY = "a0d3640fd8msh64d7013fddb4f72p167625jsn99a5e6960d83"
API_HOST = "exercisedb.p.rapidapi.com"
BASE_URL = f"https://{API_HOST}"
LIMIT = 10  # free tier cap per request

# ─── ExerciseDB muscle → ExMuscle enum name ──────────────────────────────────
# CRITICAL: these values must exactly match ExMuscle enum names in Dart
MUSCLE_MAP = {
    # target / secondaryMuscles values from API
    "pectorals": "pectoralisMajor",
    "pectoralis major": "pectoralisMajor",
    "pectoralis minor": "pectoralisMinor",
    "serratus anterior": "serratusAnterior",
    "lats": "latissimusDorsi",
    "latissimus dorsi": "latissimusDorsi",
    "upper back": "rhomboids",
    "rhomboids": "rhomboids",
    "traps": "trapezius",
    "trapezius": "trapezius",
    "delts": "lateralDeltoid",
    "front delts": "anteriorDeltoid",
    "anterior deltoid": "anteriorDeltoid",
    "lateral deltoid": "lateralDeltoid",
    "side delts": "lateralDeltoid",
    "rear delts": "posteriorDeltoid",
    "posterior deltoid": "posteriorDeltoid",
    "rotator cuff": "rotatorCuff",
    "biceps": "biceps",
    "brachialis": "brachialis",
    "triceps": "triceps",
    "forearms": "forearmFlexors",
    "forearm flexors": "forearmFlexors",
    "levator scapulae": "levatorScapulae",
    "quads": "quadriceps",
    "quadriceps": "quadriceps",
    "hamstrings": "hamstrings",
    "glutes": "gluteusMaximus",
    "gluteus maximus": "gluteusMaximus",
    "glute medius": "gluteusMedius",
    "gluteus medius": "gluteusMedius",
    "calves": "calves",
    "gastrocnemius": "calves",
    "soleus": "calves",
    "abs": "rectusAbdominis",
    "abdominals": "rectusAbdominis",
    "obliques": "obliques",
    "erector spinae": "erectorSpinae",
    "spine": "erectorSpinae",
    "lower back": "erectorSpinae",
    "transverse abdominis": "transverseAbdominis",
    "hip flexors": "hipFlexors",
    "adductors": "adductors",
    "hip adductors": "adductors",
    "inner thighs": "adductors",
    "shoulders": "lateralDeltoid",  # generic → lateral
    # skip these (no matching muscle in our enum)
    "cardiovascular system": None,
    "cardiovascular": None,
    "neck": None,
    "tibialis anterior": None,
    "wrist extensors": None,
    "wrist flexors": None,
}

# ─── ExerciseDB equipment → ExEquipment enum name ────────────────────────────
EQUIPMENT_MAP = {
    "barbell": "barbell",
    "olympic barbell": "barbell",
    "ez barbell": "barbell",
    "trap bar": "barbell",
    "dumbbell": "dumbbell",
    "body weight": "bodyweight",
    "assisted": "bodyweight",
    "resistance band": "bodyweight",
    "band": "bodyweight",
    "bosu ball": "bodyweight",
    "stability ball": "bodyweight",
    "roller": "bodyweight",
    "tire": "bodyweight",
    "rope": "bodyweight",
    "weighted": "dumbbell",
    "cable": "cables",
    "kettlebell": "kettlebell",
    "machine": "machine",
    "leverage machine": "machine",
    "smith machine": "machine",
    "sled machine": "machine",
    "skierg machine": "machine",
    "upper body ergometer": "machine",
    "hammer": "dumbbell",
}

# ─── bodyPart + target → movementType ────────────────────────────────────────
MOVEMENT_MAP = {
    ("chest", "pectorals"): "push",
    ("chest", "pectoralis minor"): "push",
    ("back", "lats"): "pull",
    ("back", "upper back"): "pull",
    ("back", "traps"): "pull",
    ("back", "erector spinae"): "hinge",
    ("shoulders", "delts"): "push",
    ("shoulders", "front delts"): "push",
    ("shoulders", "lateral deltoid"): "push",
    ("shoulders", "rear delts"): "pull",
    ("shoulders", "rotator cuff"): "isolation",
    ("upper arms", "biceps"): "isolation",
    ("upper arms", "brachialis"): "isolation",
    ("upper arms", "triceps"): "isolation",
    ("lower arms", "forearms"): "isolation",
    ("upper legs", "quads"): "squat",
    ("upper legs", "hamstrings"): "hinge",
    ("upper legs", "glutes"): "squat",
    ("upper legs", "adductors"): "isolation",
    ("lower legs", "calves"): "isolation",
    ("waist", "abs"): "isolation",
    ("waist", "obliques"): "rotation",
    ("waist", "serratus anterior"): "isolation",
    ("neck", "traps"): "isolation",
    ("cardio", "cardiovascular system"): "isolation",
}

# ─── Existing Russian translations (from current Dart codebase) ───────────────
RU_NAMES = {
    "Abdominal Twist Machine": "Скручивание в тренажёре",
    "Alternating Dumbbell Curl": "Поочерёдное сгибание с гантелями",
    "Arch Push-Up": "Дугообразное отжимание",
    "Archery Pull-Up": "Подтягивание «Лучник»",
    "Barbell Back Squat": "Приседание со штангой",
    "Barbell Bench Press": "Жим штанги лёжа",
    "Barbell Bent-Over Row": "Тяга штанги в наклоне",
    "Barbell Biceps Curl": "Сгибание рук со штангой",
    "Barbell Deadlift": "Становая тяга",
    "Barbell Hip Thrust": "Ягодичный мостик со штангой",
    "Barbell Overhead Press": "Жим штанги над головой",
    "Barbell Romanian Deadlift": "Румынская тяга со штангой",
    "Barbell Row": "Тяга штанги в наклоне",
    "Barbell Squat": "Приседания со штангой",
    "Barbell Sumo Deadlift": "Становая тяга сумо",
    "Bicycle Crunch": "Велосипедное скручивание",
    "Bodyweight Squat": "Приседание без отягощения",
    "Cable Bicep Curl": "Сгибание бицепса в блоке",
    "Cable Crossover": "Кроссовер в блоке",
    "Cable Crunch": "Скручивание в блоке",
    "Cable Face Pull": "Тяга к лицу в блоке",
    "Cable Lat Pulldown": "Тяга блока к груди",
    "Cable Lateral Raise": "Подъём в сторону в блоке",
    "Cable Tricep Pushdown": "Жим трицепса вниз в блоке",
    "Chin-Up": "Подтягивание обратным хватом",
    "Concentration Curl": "Концентрированное сгибание",
    "Crunches": "Скручивания",
    "Dead Bug": "Мёртвый жук",
    "Deadlift": "Становая тяга",
    "Decline Push Up": "Отжимание с ногами на возвышении",
    "Diamond Push Up": "Алмазное отжимание",
    "Donkey Kick": "Удар ослика",
    "Dumbbell Arnold Press": "Жим Арнольда",
    "Dumbbell Bench Press": "Жим гантелей лёжа",
    "Dumbbell Bent-Over Row": "Тяга гантелей в наклоне",
    "Dumbbell Bicep Curl": "Сгибание рук с гантелями",
    "Dumbbell Chest Fly": "Разведение гантелей лёжа",
    "Dumbbell Curl": "Сгибание рук с гантелями",
    "Dumbbell Deadlift": "Становая тяга с гантелями",
    "Dumbbell Fly": "Разведение гантелей",
    "Dumbbell Front Raise": "Подъём гантелей перед собой",
    "Dumbbell Hammer Curl": "Молотковые сгибания с гантелями",
    "Dumbbell Hip Thrust": "Ягодичный мостик с гантелью",
    "Dumbbell Lateral Raise": "Подъём гантелей в стороны",
    "Dumbbell Lunge": "Выпад с гантелями",
    "Dumbbell Lunges": "Выпады с гантелями",
    "Dumbbell Overhead Press": "Жим гантелей над головой",
    "Dumbbell Romanian Deadlift": "Румынская тяга с гантелями",
    "Dumbbell Row": "Тяга гантели в наклоне",
    "Dumbbell Shoulder Press": "Жим гантелей на плечи",
    "Dumbbell Shrug": "Шраги с гантелями",
    "Dumbbell Side Bend": "Наклоны в стороны с гантелью",
    "Dumbbell Single-Leg Deadlift": "Становая тяга на одной ноге",
    "Dumbbell Squat": "Приседание с гантелями",
    "Dumbbell Tricep Extension": "Разгибание трицепса с гантелями",
    "Face Pull": "Тяга к лицу",
    "Glute Bridge": "Ягодичный мостик",
    "Goblet Squat": "Кубковое приседание",
    "Hack Squat": "Гакк-приседание",
    "Hammer Curl": "Молотковое сгибание",
    "Hanging Leg Raise": "Подъём ног в висе",
    "Hip Thrust": "Ягодичный мостик",
    "Incline Dumbbell Press": "Жим гантелей в наклоне",
    "Incline Push Up": "Отжимание с упором",
    "Inverted Rows": "Горизонтальные подтягивания",
    "Jump Squats": "Прыжковые приседания",
    "Kettlebell Goblet Squat": "Кубковое приседание с гирей",
    "Kettlebell Swing": "Махи с гирей",
    "Lat Pulldown": "Тяга блока к груди",
    "Lateral Raise": "Подъём в стороны",
    "Leg Curl Machine": "Сгибание ног в тренажёре",
    "Leg Extension": "Разгибание ног",
    "Leg Press": "Жим ногами",
    "Leg Raise": "Подъём ног",
    "Lunge": "Выпад",
    "Machine Chest Press": "Жим в тренажёре",
    "Machine Row": "Тяга в тренажёре",
    "Mountain Climber": "Скалолаз",
    "Overhead Press": "Жим над головой",
    "Plank": "Планка",
    "Preacher Curl": "Сгибание Скотта",
    "Pull Up": "Подтягивание",
    "Push Up": "Отжимание",
    "Reverse Fly": "Обратное разведение",
    "Reverse Lunge": "Обратный выпад",
    "Romanian Deadlift": "Румынская тяга",
    "Russian Twist": "Русский твист",
    "Seated Cable Row": "Горизонтальная тяга сидя",
    "Shoulder Press": "Жим на плечи",
    "Shrug": "Шраги",
    "Side Lateral Raise": "Подъём в стороны",
    "Side Plank": "Боковая планка",
    "Squat": "Приседание",
    "Step-Up": "Зашагивание",
    "Sumo Deadlift": "Становая тяга сумо",
    "Tricep Dip": "Отжимание на брусьях",
    "Tricep Pushdown": "Жим трицепса вниз",
    "Triceps Extension": "Разгибание трицепса",
    "Wide Grip Pull-Up": "Подтягивание широким хватом",
}


def api_get(path: str) -> list:
    """Make a RapidAPI call with retry."""
    url = f"{BASE_URL}{path}"
    req = urllib.request.Request(url, headers={
        "X-RapidAPI-Key": API_KEY,
        "X-RapidAPI-Host": API_HOST,
        "User-Agent": "Mozilla/5.0",
    })
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                return json.loads(resp.read())
        except urllib.error.HTTPError as e:
            if e.code == 429:
                print(f"  Rate limited, waiting 60s...")
                time.sleep(60)
            else:
                print(f"  HTTP {e.code} for {path}")
                return []
        except Exception as e:
            print(f"  Error: {e}, retry {attempt+1}")
            time.sleep(2)
    return []


def map_muscle(name: str):
    """Convert ExerciseDB muscle name to ExMuscle enum name. Returns None to skip."""
    return MUSCLE_MAP.get(name.lower().strip())


def map_muscles(names: list) -> list:
    """Map a list, deduplicate, drop Nones."""
    result = []
    seen = set()
    for n in names:
        mapped = map_muscle(n)
        if mapped and mapped not in seen:
            result.append(mapped)
            seen.add(mapped)
    return result


def map_equipment(eq: str) -> str:
    return EQUIPMENT_MAP.get(eq.lower().strip(), "none")


def exercise_id(name: str) -> str:
    """Derive a snake_case ID from exercise name."""
    s = name.lower()
    s = re.sub(r"[^a-z0-9 ]", "", s)
    s = re.sub(r"\s+", "_", s.strip())
    return s


def get_movement_type(body_part: str, target: str) -> str:
    key = (body_part.lower(), target.lower())
    return MOVEMENT_MAP.get(key, "isolation")


def get_difficulty(api_diff: str) -> str:
    mapping = {"beginner": "beginner", "intermediate": "intermediate", "advanced": "advanced"}
    return mapping.get(api_diff.lower(), "intermediate")


def get_tags(body_part: str, target: str, equipment: str) -> list:
    tags = set()
    tags.add(body_part.lower())
    tags.add(target.lower())
    if equipment != "none":
        tags.add(equipment)
    return sorted(tags)


def fetch_all_exercises() -> list:
    """Fetch all exercises by iterating each bodyPart with pagination."""
    body_parts = ["back", "cardio", "chest", "lower arms", "lower legs",
                  "neck", "shoulders", "upper arms", "upper legs", "waist"]

    all_exercises = {}  # id → exercise (dedup by our generated ID)
    total_requests = 0

    for bp in body_parts:
        print(f"\nFetching bodyPart: {bp}")
        offset = 0
        bp_count = 0
        while True:
            path = f"/exercises/bodyPart/{urllib.parse.quote(bp)}?limit={LIMIT}&offset={offset}"
            batch = api_get(path)
            total_requests += 1
            time.sleep(0.5)  # be gentle with rate limits

            if not batch:
                break

            for ex in batch:
                target = ex.get("target", "")
                secondary = ex.get("secondaryMuscles", [])
                bp_val = ex.get("bodyPart", "")
                equipment_raw = ex.get("equipment", "")
                name = ex.get("name", "").title()
                ex_id = exercise_id(name)

                if ex_id in all_exercises:
                    continue  # skip duplicate

                primary_muscles = map_muscles([target])
                secondary_muscles = map_muscles(secondary)

                # Skip cardio-only exercises (no muscle mapping)
                if not primary_muscles and bp_val == "cardio":
                    continue

                equipment = map_equipment(equipment_raw)
                movement = get_movement_type(bp_val, target)
                difficulty = get_difficulty(ex.get("difficulty", "intermediate"))
                tags = get_tags(bp_val, target, equipment)
                name_title = name

                # Try to find existing Russian translation
                name_ru = RU_NAMES.get(name_title)

                transformed = {
                    "id": ex_id,
                    "name": name_title,
                    "nameRu": name_ru,
                    "difficulty": difficulty,
                    "equipment": [equipment] if equipment != "none" else ["bodyweight"],
                    "primaryMuscles": primary_muscles,
                    "secondaryMuscles": secondary_muscles,
                    "instructions": ex.get("instructions", []),
                    "description": ex.get("description", ""),
                    "movementType": movement,
                    "tags": tags,
                }
                all_exercises[ex_id] = transformed
                bp_count += 1

            if len(batch) < LIMIT:
                break  # no more pages
            offset += LIMIT

        print(f"  {bp}: {bp_count} exercises (total requests so far: {total_requests})")

    print(f"\nTotal API requests used: {total_requests}")
    return list(all_exercises.values())


if __name__ == "__main__":
    import urllib.parse

    print("=== ExerciseDB Migration ===")
    print(f"API Key: {API_KEY[:12]}...")

    exercises = fetch_all_exercises()

    print(f"\nFetched {len(exercises)} unique exercises")

    # Validate muscle mapping (critical for 3D viewer)
    valid_muscles = {
        "pectoralisMajor", "pectoralisMinor", "latissimusDorsi", "rhomboids",
        "trapezius", "anteriorDeltoid", "lateralDeltoid", "posteriorDeltoid",
        "biceps", "triceps", "quadriceps", "hamstrings", "gluteusMaximus",
        "calves", "rectusAbdominis", "obliques", "erectorSpinae",
        "transverseAbdominis", "brachialis", "hipFlexors", "forearmFlexors",
        "adductors", "rotatorCuff", "serratusAnterior", "levatorScapulae",
        "gluteusMedius",
    }

    broken = []
    for ex in exercises:
        all_m = ex["primaryMuscles"] + ex["secondaryMuscles"]
        bad = [m for m in all_m if m not in valid_muscles]
        if bad:
            broken.append((ex["name"], bad))

    if broken:
        print(f"\nWARNING: MUSCLE MAPPING ERRORS ({len(broken)}):")
        for name, bad in broken[:10]:
            print(f"  {name}: {bad}")
    else:
        print(f"OK: All muscle names valid (3D viewer safe)")

    no_primary = [ex["name"] for ex in exercises if not ex["primaryMuscles"]]
    print(f"OK: Exercises without primaryMuscles: {len(no_primary)}")
    if no_primary:
        print(f"  (no 3D highlighting): {no_primary[:5]}")

    # Write output
    out_path = os.path.join(os.path.dirname(__file__), "..", "assets", "data", "exercises.json")
    out_path = os.path.normpath(out_path)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(exercises, f, ensure_ascii=False, indent=2)

    print(f"\nWritten to {out_path}")
    print(f"Migration complete: {len(exercises)} exercises")
