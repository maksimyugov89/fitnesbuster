"""Find correct parameters for the /image endpoint (returns 400 = exists but wrong params)."""
import urllib.request
import urllib.error
import json

KEY  = "a0d3640fd8msh64d7013fddb4f72p167625jsn99a5e6960d83"
HOST = "exercisedb.p.rapidapi.com"

HEADERS = {
    "X-RapidAPI-Key": KEY,
    "X-RapidAPI-Host": HOST,
    "User-Agent": "Mozilla/5.0",
}

def test(url, label):
    try:
        r = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(r, timeout=15) as resp:
            body = resp.read()
            ct = resp.headers.get("content-type", "?")
            print("OK   " + label)
            print("     ct=" + ct)
            if "json" in ct:
                print("     " + str(json.loads(body))[:300])
            else:
                print("     [binary " + str(len(body)) + " bytes]")
    except urllib.error.HTTPError as e:
        body = ""
        try: body = e.read().decode()[:200]
        except: pass
        print(str(e.code) + "  " + label + " -> " + body)
    except Exception as e:
        print("ERR  " + label + " -> " + str(e))

BASE = "https://" + HOST

# 400 means endpoint exists — try different param names and values
print("=== Testing /image with different params ===\n")

# Different param names
test(BASE + "/image?name=push+up",              "name=push+up")
test(BASE + "/image?exerciseName=push+up",      "exerciseName=push+up")
test(BASE + "/image?exercise=push+up",          "exercise=push+up")
test(BASE + "/image?q=push+up",                 "q=push+up")
test(BASE + "/image?id=1",                      "id=1 (not padded)")
test(BASE + "/image?id=0001",                   "id=0001")
test(BASE + "/image?exerciseId=0001",           "exerciseId=0001")
test(BASE + "/image?limit=1",                   "limit=1 (list)")
test(BASE + "/image?offset=0&limit=1",          "offset+limit")

# Maybe it's /image/{name} not {id}
test(BASE + "/image/push%20up",                 "image/push up (name)")
test(BASE + "/image/push_up",                   "image/push_up")
test(BASE + "/image/push-up",                   "image/push-up")

# Check what error message 400 returns
print("\n=== Reading 400 error body ===")
test(BASE + "/image",                           "bare /image")
