"""Deep test of ExerciseDB v2.2 image endpoints."""
import urllib.request
import urllib.error
import json

KEY  = "a0d3640fd8msh64d7013fddb4f72p167625jsn99a5e6960d83"
HOST = "exercisedb.p.rapidapi.com"
EX_ID = "0009"  # assisted chest dip (kneeling)

HEADERS = {
    "X-RapidAPI-Key": KEY,
    "X-RapidAPI-Host": HOST,
    "User-Agent": "Mozilla/5.0",
}

def test(path):
    url = "https://" + HOST + path
    try:
        r = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(r, timeout=15) as resp:
            body = resp.read()
            ct = resp.headers.get("content-type", "?")
            if "json" in ct:
                parsed = json.loads(body)
                preview = str(parsed)[:300]
            else:
                preview = "[binary " + str(len(body)) + " bytes]"
            print("OK   " + path)
            print("     ct=" + ct + "  body=" + preview[:120])
    except urllib.error.HTTPError as e:
        print(str(e.code) + "  " + path)
    except Exception as e:
        print("ERR  " + path + " -> " + str(e))

paths = [
    # Images section guesses
    "/image/" + EX_ID,
    "/image/exercise/" + EX_ID,
    "/exercises/image/" + EX_ID,
    "/exercises/exercise/" + EX_ID + "/image",
    "/exercises/exercise/" + EX_ID + "/gif",
    "/gif/" + EX_ID,
    "/gif/exercise/" + EX_ID,

    # With query params
    "/image?id=" + EX_ID,
    "/image?exerciseId=" + EX_ID,

    # List all images
    "/image",
    "/images",
    "/gif",

    # Different ID formats
    "/image/9",
    "/image/" + EX_ID + ".gif",
    "/image/" + EX_ID + ".jpg",

    # Check what /exercises returns at root
    "/exercises",
    "/exercises?limit=1",
    "/exercises/bodyPart/chest?limit=1",
]

for p in paths:
    test(p)
