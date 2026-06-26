import json
import urllib.request

API_KEY  = "a0d3640fd8msh64d7013fddb4f72p167625jsn99a5e6960d83"
API_HOST = "exercisedb.p.rapidapi.com"

req = urllib.request.Request(
    f"https://{API_HOST}/exercises/bodyPart/chest?limit=1&offset=0",
    headers={
        "X-RapidAPI-Key": API_KEY,
        "X-RapidAPI-Host": API_HOST,
        "User-Agent": "Mozilla/5.0",
    }
)
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())

print("Fields in response:")
if data:
    for k, v in data[0].items():
        val = str(v)[:80] if not isinstance(v, list) else f"[list of {len(v)}]"
        print(f"  {k}: {val}")
