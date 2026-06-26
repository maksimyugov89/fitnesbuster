"""Test /image endpoint with resolution param."""
import urllib.request
import urllib.error
import json

KEY  = "a0d3640fd8msh64d7013fddb4f72p167625jsn99a5e6960d83"
HOST = "exercisedb.p.rapidapi.com"
BASE = "https://" + HOST

HEADERS = {
    "X-RapidAPI-Key": KEY,
    "X-RapidAPI-Host": HOST,
    "User-Agent": "Mozilla/5.0",
}

EX_ID = "0009"

def test(url, label):
    try:
        r = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(r, timeout=15) as resp:
            body = resp.read()
            ct = resp.headers.get("content-type", "?")
            print("OK   " + label)
            print("     ct=" + ct + "  size=" + str(len(body)))
            if "json" in ct:
                print("     " + str(json.loads(body))[:500])
            else:
                # Binary — first bytes
                print("     first 16 bytes: " + str(body[:16]))
    except urllib.error.HTTPError as e:
        body = ""
        try: body = e.read().decode(errors="replace")[:300]
        except: pass
        print(str(e.code) + "  " + label + "  -> " + body)
    except Exception as e:
        print("ERR  " + label + " -> " + str(e))

print("=== /image with resolution param ===\n")

# resolution only (no ID) — see if it wants an exercise ID too
test(BASE + "/image?resolution=360",                            "resolution=360 only")
test(BASE + "/image?resolution=180",                            "resolution=180 only")

# resolution + exercise ID (padded)
test(BASE + "/image?resolution=360&id=" + EX_ID,               "res=360 + id=0009")
test(BASE + "/image?resolution=360&exerciseId=" + EX_ID,       "res=360 + exerciseId=0009")
test(BASE + "/image?resolution=360&exercise_id=" + EX_ID,      "res=360 + exercise_id=0009")

# resolution + unpadded ID
test(BASE + "/image?resolution=360&id=9",                      "res=360 + id=9")

# resolution with path param
test(BASE + "/image/" + EX_ID + "?resolution=360",             "image/{id}?resolution=360")
test(BASE + "/image/9?resolution=360",                          "image/9?resolution=360")

# Maybe it's exercise name?
test(BASE + "/image?resolution=360&name=push+up",              "res=360 + name=push+up")

print("\n=== Done ===")
