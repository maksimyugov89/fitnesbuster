"""Try Firebase Storage Management API to initialize the storage bucket."""
import urllib.request
import urllib.error
import json

with open(r"C:\Users\Despa\.config\configstore\firebase-tools.json") as f:
    ACCESS_TOKEN = json.load(f)["tokens"]["access_token"]

PROJECT = "fitnesbuster"

def req(method, url, data=None, ct="application/json"):
    headers = {"Authorization": f"Bearer {ACCESS_TOKEN}", "User-Agent": "python"}
    body = None
    if data is not None:
        body = json.dumps(data).encode() if isinstance(data, dict) else data
        headers["Content-Type"] = ct
    r = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(r, timeout=20) as resp:
            body_text = resp.read().decode(errors="replace")
            print(f"OK   {method} {url[-60:]}")
            print(f"     {body_text[:300]}")
            return json.loads(body_text) if body_text.strip() else {}
    except urllib.error.HTTPError as e:
        bt = e.read().decode(errors="replace")[:400]
        print(f"{e.code}  {method} {url[-60:]}")
        print(f"     {bt}")
        return None

# Try Firebase Storage Management API v1beta endpoints
base = "https://firebasestorage.googleapis.com"

print("=== Firebase Storage v1beta API ===")
# List buckets
req("GET",  f"{base}/v1beta/projects/{PROJECT}/buckets")
# Get default bucket
req("GET",  f"{base}/v1beta/projects/{PROJECT}/buckets/fitnesbuster.appspot.com")
req("GET",  f"{base}/v1beta/projects/{PROJECT}/buckets/fitnesbuster.firebasestorage.app")

# Try to add default storage bucket via Firebase API
print("\n=== Firebase Management API add default bucket ===")
req("POST", f"https://firebase.googleapis.com/v1beta1/projects/{PROJECT}/defaultBucket", {})
req("POST", f"https://firebase.googleapis.com/v1beta1/projects/{PROJECT}:addGoogleAnalytics", None)
req("GET",  f"https://firebase.googleapis.com/v1beta1/projects/{PROJECT}/availableLocations")
