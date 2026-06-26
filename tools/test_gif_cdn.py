import urllib.request
import urllib.error

KEY = "a0d3640fd8msh64d7013fddb4f72p167625jsn99a5e6960d83"

tests = [
    ("with key",         "https://v2.exercisedb.io/image/0009.gif",
     {"X-RapidAPI-Key": KEY, "User-Agent": "Mozilla/5.0"}),
    ("no auth",          "https://v2.exercisedb.io/image/0009.gif",
     {"User-Agent": "Mozilla/5.0"}),
    ("with host header", "https://v2.exercisedb.io/image/0009.gif",
     {"X-RapidAPI-Key": KEY, "X-RapidAPI-Host": "exercisedb.p.rapidapi.com", "User-Agent": "Mozilla/5.0"}),
    # Try alternate URL patterns
    ("alt pattern v3",   "https://v3.exercisedb.io/image/0009.gif",
     {"X-RapidAPI-Key": KEY, "User-Agent": "Mozilla/5.0"}),
]

for label, url, headers in tests:
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=10) as r:
            data = r.read()
            ct = r.headers.get("content-type", "?")
            print(label, "-> OK", len(data), "bytes, content-type:", ct)
    except urllib.error.HTTPError as e:
        print(label, "-> HTTP", e.code, e.reason)
    except Exception as e:
        print(label, "-> Error:", e)
