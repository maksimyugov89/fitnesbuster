"""Test Firebase Storage REST API with anonymous auth."""
import urllib.request
import urllib.error
import urllib.parse
import json

FIREBASE_API_KEY = "AIzaSyDXV3wyJ0FApfqUATvvTpuc0kw2Hnt5TI8"
BUCKET = "fitnesbuster.firebasestorage.app"

def post_json(url, data):
    body = json.dumps(data).encode()
    req = urllib.request.Request(
        url, data=body,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read())

# Step 1: Anonymous sign-in
print("1. Signing in anonymously...")
try:
    result = post_json(
        f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={FIREBASE_API_KEY}",
        {"returnSecureToken": True}
    )
    id_token = result["idToken"]
    uid = result["localId"]
    print(f"   OK - uid={uid}")
except Exception as e:
    print(f"   FAILED: {e}")
    exit(1)

# Step 2: Try upload a tiny test file
print("\n2. Uploading test.txt to Firebase Storage...")
test_content = b"Hello from Python upload test!"
name = urllib.parse.quote("test/hello.txt", safe="")
upload_url = f"https://firebasestorage.googleapis.com/v0/b/{BUCKET}/o?name={name}"

req = urllib.request.Request(
    upload_url,
    data=test_content,
    headers={
        "Authorization": f"Bearer {id_token}",
        "Content-Type": "text/plain",
    },
    method="POST"
)
try:
    with urllib.request.urlopen(req, timeout=15) as resp:
        result = json.loads(resp.read())
        print(f"   OK - name={result.get('name')}")
        print(f"   download token: {result.get('downloadTokens', 'none')}")
        # Build public download URL
        encoded_name = urllib.parse.quote(result["name"], safe="")
        dl_url = f"https://firebasestorage.googleapis.com/v0/b/{BUCKET}/o/{encoded_name}?alt=media&token={result.get('downloadTokens','')}"
        print(f"   URL: {dl_url}")
except urllib.error.HTTPError as e:
    body = e.read().decode(errors="replace")
    print(f"   FAILED {e.code}: {body[:500]}")
except Exception as e:
    print(f"   FAILED: {e}")
