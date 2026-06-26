"""
add_gif_urls.py
Fetches gifUrl for all exercises from ExerciseDB API and adds to exercises.json.
Preserves all existing fields (nameRu, description, etc.).

Uses ~144 API requests — within Basic 690/month budget.
Run: python tools/add_gif_urls.py
"""
import json
import time
import urllib.request
import urllib.error
import urllib.parse
import re
from pathlib import Path

API_KEY  = "a0d3640fd8msh64d7013fddb4f72p167625jsn99a5e6960d83"
API_HOST = "exercisedb.p.rapidapi.com"
BASE_URL = f"https://{API_HOST}"
LIMIT    = 10
EXERCISES = Path(__file__).parent.parent / "assets" / "data" / "exercises.json"

BODY_PARTS = ["back", "cardio", "chest", "lower arms", "lower legs",
              "neck", "shoulders", "upper arms", "upper legs", "waist"]


def api_get(path: str) -> list:
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
                print("  Rate limited, waiting 60s...")
                time.sleep(60)
            else:
                print(f"  HTTP {e.code} on {path}")
                return []
        except Exception as e:
            print(f"  Error: {e}, retry {attempt+1}")
            time.sleep(2)
    return []


def exercise_id(name: str) -> str:
    s = name.lower()
    s = re.sub(r"[^a-z0-9 ]", "", s)
    s = re.sub(r"\s+", "_", s.strip())
    return s


def main():
    print(f"Loading {EXERCISES}...")
    with open(EXERCISES, encoding="utf-8") as f:
        exercises: list[dict] = json.load(f)

    # Build lookup by our generated ID (same formula as migrate_exercises.py)
    by_id = {ex["id"]: ex for ex in exercises}
    print(f"Total exercises: {len(exercises)}")

    gif_found   = 0
    total_reqs  = 0

    for bp in BODY_PARTS:
        print(f"\nBodyPart: {bp}")
        offset = 0
        while True:
            path = f"/exercises/bodyPart/{urllib.parse.quote(bp)}?limit={LIMIT}&offset={offset}"
            batch = api_get(path)
            total_reqs += 1
            time.sleep(0.4)

            if not batch:
                break

            for ex in batch:
                name    = ex.get("name", "").title()
                ex_id   = exercise_id(name)
                gif_url = ex.get("gifUrl")

                if ex_id in by_id and gif_url:
                    by_id[ex_id]["gifUrl"] = gif_url
                    gif_found += 1

            if len(batch) < LIMIT:
                break
            offset += LIMIT

        print(f"  GIFs found so far: {gif_found}")

    # Save updated exercises.json
    with open(EXERCISES, "w", encoding="utf-8") as f:
        json.dump(exercises, f, ensure_ascii=False, indent=2)

    no_gif = [ex["name"] for ex in exercises if not ex.get("gifUrl")]
    print(f"\nDone. API requests: {total_reqs}")
    print(f"GIFs added: {gif_found}/{len(exercises)}")
    print(f"Without gifUrl: {len(no_gif)}")
    if no_gif[:5]:
        print("  Examples:", no_gif[:5])


if __name__ == "__main__":
    main()
