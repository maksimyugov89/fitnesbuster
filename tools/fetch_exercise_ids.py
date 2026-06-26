"""
Fetch all exercises from ExerciseDB API to build name->numericId mapping,
then match with our local exercises.json and download GIFs.
"""
import urllib.request
import urllib.error
import json
import os
import time

KEY  = "a0d3640fd8msh64d7013fddb4f72p167625jsn99a5e6960d83"
HOST = "exercisedb.p.rapidapi.com"
BASE = "https://" + HOST

HEADERS = {
    "X-RapidAPI-Key": KEY,
    "X-RapidAPI-Host": HOST,
    "User-Agent": "Mozilla/5.0",
}

LOCAL_JSON = os.path.join(os.path.dirname(__file__), "..", "assets", "data", "exercises.json")

def fetch_json(url):
    r = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(r, timeout=30) as resp:
        return json.loads(resp.read())

def normalize(name):
    return name.lower().strip()

# ── Step 1: fetch total count ─────────────────────────────────────────────────
print("Fetching exercise count...")
try:
    # try limit=1 first to see total header
    r = urllib.request.Request(BASE + "/exercises?limit=1&offset=0", headers=HEADERS)
    with urllib.request.urlopen(r, timeout=30) as resp:
        hdrs = dict(resp.headers)
        body = json.loads(resp.read())
        print("Headers:", {k: v for k, v in hdrs.items() if "total" in k.lower() or "count" in k.lower() or "x-" in k.lower()})
        print("First item:", json.dumps(body[0] if body else {}, indent=2))
except Exception as e:
    print("Error:", e)

# ── Step 2: fetch ALL exercises (try limit=2000) ───────────────────────────────
print("\nFetching all exercises from ExerciseDB...")
try:
    url = BASE + "/exercises?limit=2000&offset=0"
    r = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(r, timeout=60) as resp:
        all_ex = json.loads(resp.read())
    print(f"  Got {len(all_ex)} exercises from ExerciseDB API")
    # Show first few IDs + names
    for ex in all_ex[:5]:
        print(f"  id={ex.get('id')} name={ex.get('name')}")
except Exception as e:
    print("Error:", e)
    all_ex = []

if not all_ex:
    print("No exercises fetched, exiting")
    exit(1)

# ── Step 3: load local exercises.json ─────────────────────────────────────────
print("\nLoading local exercises.json...")
with open(LOCAL_JSON, encoding="utf-8") as f:
    local_exercises = json.load(f)
print(f"  Local exercises: {len(local_exercises)}")

# Build lookup: normalized_name -> ExerciseDB numeric id
api_name_to_id = {}
for ex in all_ex:
    api_name_to_id[normalize(ex["name"])] = ex["id"]

# Match
matched = 0
unmatched = []
for ex in local_exercises:
    norm = normalize(ex["name"])
    if norm in api_name_to_id:
        ex["exerciseDbId"] = api_name_to_id[norm]
        matched += 1
    else:
        unmatched.append(ex["name"])

print(f"\nMatched: {matched}/{len(local_exercises)}")
print(f"Unmatched: {len(unmatched)}")
if unmatched[:10]:
    print("First 10 unmatched:", unmatched[:10])

# ── Step 4: save updated exercises.json ───────────────────────────────────────
print("\nSaving updated exercises.json...")
with open(LOCAL_JSON, "w", encoding="utf-8") as f:
    json.dump(local_exercises, f, ensure_ascii=False, indent=2)
print("Done!")

# Stats
with_id = sum(1 for e in local_exercises if "exerciseDbId" in e)
print(f"Exercises with exerciseDbId: {with_id}/{len(local_exercises)}")
