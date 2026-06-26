"""
Download all exercise GIFs from ExerciseDB API and save to public/gifs/.
Uses concurrent requests for speed. Saves progress so can be restarted.
"""
import urllib.request
import urllib.error
import json
import os
import time
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed

KEY  = "a0d3640fd8msh64d7013fddb4f72p167625jsn99a5e6960d83"
HOST = "exercisedb.p.rapidapi.com"
BASE = "https://" + HOST

OUT_DIR  = os.path.join(os.path.dirname(__file__), "..", "public", "gifs")
JSON_PATH = os.path.join(os.path.dirname(__file__), "..", "assets", "data", "exercises.json")

HEADERS = {
    "X-RapidAPI-Key": KEY,
    "X-RapidAPI-Host": HOST,
    "User-Agent": "Mozilla/5.0",
}

RESOLUTION = "360"
MAX_WORKERS = 2   # stay under per-minute rate limit
REQUEST_DELAY = 1.2  # seconds between requests per worker

os.makedirs(OUT_DIR, exist_ok=True)

# Load exercises
with open(JSON_PATH, encoding="utf-8") as f:
    exercises = json.load(f)

# Filter those with exerciseDbId
to_download = [e for e in exercises if "exerciseDbId" in e]
print(f"Total exercises with exerciseDbId: {len(to_download)}")

# Count already downloaded
already = {f for f in os.listdir(OUT_DIR) if f.endswith(".gif")}
print(f"Already downloaded: {len(already)}")

lock = threading.Lock()
success = [0]
failed = []

def download_one(ex):
    db_id = ex["exerciseDbId"]
    filename = db_id + ".gif"
    dest = os.path.join(OUT_DIR, filename)

    if filename in already:
        with lock:
            success[0] += 1
        return db_id, True, "cached"

    url = f"{BASE}/image?exerciseId={db_id}&resolution={RESOLUTION}"
    # Throttle: always wait between requests, more on retries
    time.sleep(REQUEST_DELAY)
    # Retry up to 3 times with exponential backoff on 429
    for attempt in range(3):
        try:
            if attempt > 0:
                time.sleep(15 * attempt)
            req = urllib.request.Request(url, headers=HEADERS)
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = resp.read()
                if len(data) < 100:
                    return db_id, False, f"too small: {len(data)} bytes"
                with open(dest, "wb") as f:
                    f.write(data)
                with lock:
                    success[0] += 1
                    cnt = success[0]
                if cnt % 50 == 0 or cnt <= 5:
                    print(f"  [{cnt}/{len(to_download)}] {db_id} ({len(data)//1024}KB)")
                return db_id, True, f"{len(data)} bytes"
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < 2:
                continue  # backoff handled at top of loop
            body = ""
            try: body = e.read().decode(errors="replace")[:100]
            except: pass
            return db_id, False, f"HTTP {e.code}: {body}"
        except Exception as e:
            return db_id, False, str(e)
    return db_id, False, "max retries exceeded"

print(f"\nStarting download with {MAX_WORKERS} concurrent workers...")
start = time.time()

with ThreadPoolExecutor(max_workers=MAX_WORKERS) as ex:
    futures = {ex.submit(download_one, e): e for e in to_download}
    for fut in as_completed(futures):
        db_id, ok, msg = fut.result()
        if not ok:
            failed.append((db_id, msg))

elapsed = time.time() - start
print(f"\nDone in {elapsed:.1f}s")
print(f"Success: {success[0]}/{len(to_download)}")
if failed:
    print(f"Failed ({len(failed)}):")
    for db_id, msg in failed[:20]:
        print(f"  {db_id}: {msg}")
    if len(failed) > 20:
        print(f"  ... and {len(failed)-20} more")

# Count downloaded files
gifs = [f for f in os.listdir(OUT_DIR) if f.endswith(".gif")]
total_size = sum(os.path.getsize(os.path.join(OUT_DIR, f)) for f in gifs)
print(f"\nGIFs in {OUT_DIR}: {len(gifs)} files, {total_size/1024/1024:.1f} MB total")
