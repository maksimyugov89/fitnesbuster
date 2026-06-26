"""Initialize Firebase Storage bucket and test upload using refreshed CLI token."""
import urllib.request
import urllib.error
import urllib.parse
import json

# Read fresh token from Firebase CLI config
with open(r"C:\Users\Despa\.config\configstore\firebase-tools.json") as f:
    cli = json.load(f)
ACCESS_TOKEN = cli["tokens"]["access_token"]

BUCKET = "fitnesbuster.firebasestorage.app"
PROJECT = "fitnesbuster"

def get(url, token=None, label=""):
    headers = {"User-Agent": "python"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            body = resp.read().decode(errors="replace")
            print(f"OK   {label}: {body[:300]}")
            return json.loads(body)
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        print(f"{e.code}  {label}: {body[:300]}")
        return None

def post(url, data, token=None, content_type="application/json"):
    if isinstance(data, dict):
        body = json.dumps(data).encode()
    elif isinstance(data, str):
        body = data.encode()
    else:
        body = data
    headers = {"Content-Type": content_type, "User-Agent": "python"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=body, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            body = resp.read().decode(errors="replace")
            print(f"OK   POST {url[:60]}: {body[:300]}")
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        print(f"{e.code}  POST {url[:60]}: {body[:300]}")
        return None

print("Using access_token:", ACCESS_TOKEN[:40], "...")
print()

# 1. Check if Firebase Storage API is accessible
print("=== 1. Check Firebase Storage management API ===")
get(
    f"https://firebase.googleapis.com/v1beta1/projects/{PROJECT}",
    ACCESS_TOKEN, "firebase project info"
)

# 2. Try to create default bucket via Firebase API
print("\n=== 2. Try to add Firebase Storage via API ===")
post(
    f"https://firebase.googleapis.com/v1beta1/projects/{PROJECT}/defaultBucket",
    {}, ACCESS_TOKEN
)

# 3. Try GCS JSON API to create bucket
print("\n=== 3. Try GCS JSON API to create bucket ===")
post(
    f"https://storage.googleapis.com/storage/v1/b?project={PROJECT}",
    {"name": BUCKET, "location": "EU"},
    ACCESS_TOKEN
)

# 4. Try upload with refreshed token
print("\n=== 4. Try upload with refreshed token ===")
name_enc = urllib.parse.quote("test/hello.txt", safe="")
post(
    f"https://firebasestorage.googleapis.com/v0/b/{BUCKET}/o?name={name_enc}",
    b"Hello Firebase!",
    ACCESS_TOKEN,
    "text/plain"
)
