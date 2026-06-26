"""Test Firebase Storage REST API - check error details."""
import urllib.request
import urllib.error
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
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return json.loads(resp.read()), None
    except urllib.error.HTTPError as e:
        return None, e.read().decode(errors="replace")
    except Exception as e:
        return None, str(e)

# Anonymous sign-in
print("Trying anonymous sign-in...")
result, err = post_json(
    f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={FIREBASE_API_KEY}",
    {"returnSecureToken": True}
)
if err:
    print(f"Anonymous failed: {err}")
else:
    print(f"Anonymous OK: uid={result['localId']}")

# Try email/password sign-in (if we had credentials)
# Skip for now

# Try public upload (no auth) to see what rules say
print("\nTrying unauthenticated upload...")
import urllib.parse
test_content = b"test"
name = urllib.parse.quote("test/hello.txt", safe="")
upload_url = f"https://firebasestorage.googleapis.com/v0/b/{BUCKET}/o?name={name}"
req = urllib.request.Request(
    upload_url,
    data=test_content,
    headers={"Content-Type": "text/plain"},
    method="POST"
)
try:
    with urllib.request.urlopen(req, timeout=15) as resp:
        result = json.loads(resp.read())
        print(f"Unauthenticated upload OK: {result}")
except urllib.error.HTTPError as e:
    print(f"Unauthenticated upload {e.code}: {e.read().decode(errors='replace')[:300]}")
except Exception as e:
    print(f"Unauthenticated upload error: {e}")

# Check bucket metadata (public)
print(f"\nChecking bucket {BUCKET}...")
meta_url = f"https://firebasestorage.googleapis.com/v0/b/{BUCKET}"
req = urllib.request.Request(meta_url, headers={"User-Agent": "test"})
try:
    with urllib.request.urlopen(req, timeout=15) as resp:
        print("Bucket metadata:", resp.read().decode()[:300])
except urllib.error.HTTPError as e:
    print(f"Bucket meta {e.code}: {e.read().decode()[:200]}")
except Exception as e:
    print(f"Bucket meta error: {e}")
