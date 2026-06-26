"""Test ExerciseDB v2.2 Images endpoints."""
import urllib.request
import urllib.error
import json

KEY  = "a0d3640fd8msh64d7013fddb4f72p167625jsn99a5e6960d83"
HOST = "exercisedb.p.rapidapi.com"

def req(path, label):
    url = "https://" + HOST + path
    headers = {
        "X-RapidAPI-Key": KEY,
        "X-RapidAPI-Host": HOST,
        "User-Agent": "Mozilla/5.0",
    }
    try:
        r = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(r, timeout=15) as resp:
            body = resp.read()
            ct = resp.headers.get("content-type", "?")
            # If JSON, show structure
            if "json" in ct:
                parsed = json.loads(body)
                preview = str(parsed)[:200]
            else:
                preview = f"[binary {len(body)} bytes]"
            print(f"[OK]  {label}")
            print(f"      content-type: {ct}")
            print(f"      body: {preview}")
    except urllib.error.HTTPError as e:
        print(f"[{e.code}] {label} -> {e.reason}")
    except Exception as e:
        print(f"[ERR] {label} -> {e}")
    print()

# Exercise ID 0009 — "assisted chest dip (kneeling)"
EX_ID = "0009"

print("=== Images endpoints ===\n")
req(f"/exercises/images",                              "GET /exercises/images")
req(f"/exercises/images/{EX_ID}",                     "GET /exercises/images/{id}")
req(f"/image/{EX_ID}",                                "GET /image/{id}")
req(f"/images/{EX_ID}",                               "GET /images/{id}")
req(f"/images/{EX_ID}.gif",                           "GET /images/{id}.gif")
req(f"/exercises/exercise/{EX_ID}/images",            "GET /exercises/exercise/{id}/images")
req(f"/exercises/{EX_ID}/images",                     "GET /exercises/{id}/images")
req(f"/exercises/exercise/{EX_ID}",                   "GET /exercises/exercise/{id} (full)")
