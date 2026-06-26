"""Test upload to Firebase Storage using Firebase CLI access token."""
import urllib.request
import urllib.error
import urllib.parse
import json
import time

# Firebase CLI stored tokens
ACCESS_TOKEN = "ya29.a0AT3oNZ84xAJI86pTL6OmmU0ccuCHrMZrkx4yiM-IYSAZw9eK-6ftkLGqKxV7rmlYgP42nxWnsraS8aS--cgLXSWcGjPYmnND9-1Q6CxleYPnZaZ97k69PsmQCjIx_efufCz4S5Y-HVdyaW0eGvMYiG4mXIZfNf9lmELgph6Tz2g1b3MBTR274vqfJ1Qa7i29mtWjw_HdEvKtEAaCgYKAfsSARMSFQHGX2MiSgnC5hSKKJGLaX2M1uzoAQ0213"
REFRESH_TOKEN = "1//0caTCdQoyf9xuCgYIARAAGAwSNwF-L9Irs8Do3QV3IaZVVhMkU7H8nLXB5e8_WqN-NN3aNNMxfV_clYomgZr6O0gyNH-tKK8uWI8"

BUCKET_FIREBASE = "fitnesbuster.firebasestorage.app"
BUCKET_LEGACY   = "fitnesbuster.appspot.com"

def refresh_access_token():
    """Try to refresh the Firebase CLI access token."""
    # Firebase CLI client ID (public, from source)
    CLIENT_ID = "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com"
    # Firebase CLI is a web client — try without secret first
    body = urllib.parse.urlencode({
        "grant_type": "refresh_token",
        "refresh_token": REFRESH_TOKEN,
        "client_id": CLIENT_ID,
    }).encode()
    req = urllib.request.Request(
        "https://oauth2.googleapis.com/token",
        data=body,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            r = json.loads(resp.read())
            return r.get("access_token")
    except urllib.error.HTTPError as e:
        print(f"  Refresh failed {e.code}: {e.read().decode()[:200]}")
        return None

def try_upload(bucket, token, label):
    test_content = b"Hello Firebase Storage"
    name = urllib.parse.quote("test/hello.txt", safe="")
    url = f"https://firebasestorage.googleapis.com/v0/b/{bucket}/o?name={name}"
    req = urllib.request.Request(
        url,
        data=test_content,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "text/plain",
        },
        method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            r = json.loads(resp.read())
            print(f"  {label}: OK - {r.get('name')}")
            token_str = r.get('downloadTokens', '')
            encoded = urllib.parse.quote(r["name"], safe="")
            print(f"  URL: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{encoded}?alt=media&token={token_str}")
            return True
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")[:300]
        print(f"  {label}: {e.code} - {body}")
        return False
    except Exception as e:
        print(f"  {label}: ERROR - {e}")
        return False

# Try with current access token
print("=== Testing with current access token ===")
try_upload(BUCKET_FIREBASE, ACCESS_TOKEN, f"bucket={BUCKET_FIREBASE}")
try_upload(BUCKET_LEGACY, ACCESS_TOKEN, f"bucket={BUCKET_LEGACY}")

# Try to refresh token
print("\n=== Refreshing token ===")
new_token = refresh_access_token()
if new_token:
    print(f"  Got new token: {new_token[:30]}...")
    print("\n=== Testing with refreshed token ===")
    try_upload(BUCKET_FIREBASE, new_token, f"bucket={BUCKET_FIREBASE}")
    try_upload(BUCKET_LEGACY, new_token, f"bucket={BUCKET_LEGACY}")
else:
    print("  Could not refresh - need client_secret")
