"""Try correct Firebase Storage defaultBucket creation format."""
import urllib.request
import urllib.error
import json
import time

with open(r"C:\Users\Despa\.config\configstore\firebase-tools.json") as f:
    ACCESS_TOKEN = json.load(f)["tokens"]["access_token"]

PROJECT = "fitnesbuster"

def post(url, data=None):
    headers = {"Authorization": f"Bearer {ACCESS_TOKEN}", "User-Agent": "python"}
    body = None
    if data is not None:
        body = json.dumps(data).encode()
        headers["Content-Type"] = "application/json"
    r = urllib.request.Request(url, data=body, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(r, timeout=30) as resp:
            bt = resp.read().decode(errors="replace")
            print(f"OK  : {bt[:500]}")
            return json.loads(bt) if bt.strip() else {}
    except urllib.error.HTTPError as e:
        bt = e.read().decode(errors="replace")[:600]
        print(f"{e.code}: {bt}")
        return None

BASE = f"https://firebasestorage.googleapis.com/v1beta/projects/{PROJECT}"

# Try empty body
print("=== Empty body ===")
post(f"{BASE}/defaultBucket", None)

# Try with storageBucket object
print("\n=== With storageBucket object ===")
post(f"{BASE}/defaultBucket", {"storageBucket": {}})

# Try with bucket name only
print("\n=== With bucket field ===")
post(f"{BASE}/defaultBucket", {"bucket": {}})

# Try with name field
print("\n=== With name field ===")
post(f"{BASE}/defaultBucket", {"name": "fitnesbuster.firebasestorage.app"})

# Try bucket resource
print("\n=== bucket resource ===")
post(f"{BASE}/buckets", {"name": "fitnesbuster.firebasestorage.app"})
