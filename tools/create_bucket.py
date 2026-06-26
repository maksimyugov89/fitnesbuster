"""Create Firebase Storage default bucket and test upload."""
import urllib.request
import urllib.error
import urllib.parse
import json
import time

with open(r"C:\Users\Despa\.config\configstore\firebase-tools.json") as f:
    ACCESS_TOKEN = json.load(f)["tokens"]["access_token"]

PROJECT = "fitnesbuster"
PROJECT_NUMBER = "184541768053"

def req(method, url, data=None, raw=None, ct="application/json"):
    headers = {"Authorization": f"Bearer {ACCESS_TOKEN}", "User-Agent": "python"}
    body = None
    if data is not None:
        body = json.dumps(data).encode()
        headers["Content-Type"] = ct
    elif raw is not None:
        body = raw
        headers["Content-Type"] = ct
    r = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(r, timeout=30) as resp:
            bt = resp.read().decode(errors="replace")
            print(f"OK   {method} ...{url[-70:]}")
            print(f"     {bt[:400]}")
            return json.loads(bt) if bt.strip() else {}
    except urllib.error.HTTPError as e:
        bt = e.read().decode(errors="replace")[:500]
        print(f"{e.code}  {method} ...{url[-70:]}")
        print(f"     {bt}")
        return None

# Wait for API enablement
print("Waiting 3s for API propagation...")
time.sleep(3)

# 1. List buckets via Firebase Storage API
print("\n=== 1. List Firebase Storage buckets ===")
req("GET", f"https://firebasestorage.googleapis.com/v1beta/projects/{PROJECT}/buckets")
req("GET", f"https://firebasestorage.googleapis.com/v1beta/projects/{PROJECT_NUMBER}/buckets")

# 2. Try to get/create default bucket via Firebase CLI method
# Firebase uses this endpoint to create the default storage bucket:
print("\n=== 2. Create default bucket ===")
req("POST",
    f"https://firebasestorage.googleapis.com/v1beta/projects/{PROJECT}/defaultBucket",
    {"bucket": {"location": "europe-west3"}})

# 3. Try firebase init storage approach - POST to firebase management
req("POST",
    f"https://firebase.googleapis.com/v1beta1/projects/{PROJECT}:addFirebase",
    {})

# 4. Check if any bucket was created
print("\n=== 3. Check bucket status ===")
time.sleep(2)
req("GET", f"https://firebasestorage.googleapis.com/v1beta/projects/{PROJECT}/buckets")
