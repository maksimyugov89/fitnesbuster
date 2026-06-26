"""Enable Firebase Storage API via Service Usage API."""
import urllib.request
import urllib.error
import json

with open(r"C:\Users\Despa\.config\configstore\firebase-tools.json") as f:
    ACCESS_TOKEN = json.load(f)["tokens"]["access_token"]

PROJECT = "fitnesbuster"
PROJECT_NUMBER = "184541768053"

def req(method, url, data=None):
    headers = {"Authorization": f"Bearer {ACCESS_TOKEN}", "User-Agent": "python"}
    body = None
    if data is not None:
        body = json.dumps(data).encode()
        headers["Content-Type"] = "application/json"
    r = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(r, timeout=30) as resp:
            bt = resp.read().decode(errors="replace")
            print(f"OK   {method} {url[-80:]}")
            print(f"     {bt[:300]}")
            return json.loads(bt) if bt.strip() else {}
    except urllib.error.HTTPError as e:
        bt = e.read().decode(errors="replace")[:400]
        print(f"{e.code}  {method} {url[-80:]}")
        print(f"     {bt}")
        return None

# Enable Firebase Storage API
apis = [
    "firebasestorage.googleapis.com",
    "storage.googleapis.com",
]

for api in apis:
    print(f"\n=== Enabling {api} ===")
    req("POST",
        f"https://serviceusage.googleapis.com/v1/projects/{PROJECT}/services/{api}:enable",
        {})

# Also try via project number
for api in apis:
    print(f"\n=== Enabling {api} (by project number) ===")
    req("POST",
        f"https://serviceusage.googleapis.com/v1/projects/{PROJECT_NUMBER}/services/{api}:enable",
        {})
