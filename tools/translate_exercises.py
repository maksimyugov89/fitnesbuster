"""
translate_exercises.py
Batch-translates exercise names to Russian using DeepSeek API.
Reads: assets/data/exercises.json
Writes: assets/data/exercises.json (in-place, incremental)

Run from project root:
  python tools/translate_exercises.py
"""

import json
import os
import time
import urllib.request
import urllib.error
from pathlib import Path

# ── Config ────────────────────────────────────────────────────────────────────

SCRIPT_DIR   = Path(__file__).parent
EXERCISES    = SCRIPT_DIR.parent / "assets" / "data" / "exercises.json"
API_KEY      = os.environ.get("DEEPSEEK_API_KEY", "sk-d7ee8d4cacec4a9b8127f69a7c774d79")
API_URL      = "https://api.deepseek.com/chat/completions"
BATCH_SIZE   = 40   # names per API call
RETRY_LIMIT  = 3
RETRY_DELAY  = 5    # seconds between retries

SYSTEM_PROMPT = (
    "You are a professional fitness translator. "
    "Translate exercise names from English to Russian. "
    "Use standard Russian fitness terminology. "
    "Return ONLY a JSON object: {\"English Name\": \"Russian Name\", ...}. "
    "No explanations, no markdown, just the JSON object."
)

# ── Helpers ───────────────────────────────────────────────────────────────────

def call_deepseek(names: list[str]) -> dict[str, str]:
    """Sends a batch of names to DeepSeek, returns {en: ru} dict."""
    names_list = "\n".join(f"- {n}" for n in names)
    user_msg = (
        f"Translate these exercise names to Russian:\n{names_list}\n\n"
        "Return a JSON object mapping each English name to its Russian translation."
    )
    payload = json.dumps({
        "model": "deepseek-chat",
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user",   "content": user_msg},
        ],
        "max_tokens": 2048,
        "temperature": 0.1,
    }).encode()

    req = urllib.request.Request(
        API_URL,
        data=payload,
        headers={
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = json.loads(resp.read())

    content = data["choices"][0]["message"]["content"].strip()

    # Strip markdown code fences if present
    if content.startswith("```"):
        content = content.split("```")[1]
        if content.startswith("json"):
            content = content[4:]
        content = content.strip()

    return json.loads(content)


def translate_batch(names: list[str]) -> dict[str, str]:
    """Wraps call_deepseek with retries."""
    for attempt in range(1, RETRY_LIMIT + 1):
        try:
            result = call_deepseek(names)
            # Verify all names got translated
            missing = [n for n in names if n not in result]
            if missing:
                print(f"  [warn] {len(missing)} names missing, retrying...")
                # Try a second pass for the missing ones
                if attempt < RETRY_LIMIT:
                    time.sleep(2)
                    extra = call_deepseek(missing)
                    result.update(extra)
            return result
        except json.JSONDecodeError as e:
            print(f"  [err] JSON parse error (attempt {attempt}): {e}")
        except urllib.error.HTTPError as e:
            print(f"  [err] HTTP {e.code} (attempt {attempt}): {e.read().decode()[:200]}")
        except Exception as e:
            print(f"  [err] {type(e).__name__} (attempt {attempt}): {e}")
        if attempt < RETRY_LIMIT:
            time.sleep(RETRY_DELAY)
    return {}


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    print(f"Reading {EXERCISES}...")
    with open(EXERCISES, encoding="utf-8") as f:
        exercises: list[dict] = json.load(f)

    # Exercises still needing translation
    todo = [ex for ex in exercises if not ex.get("nameRu")]
    total = len(todo)
    print(f"Found {total} exercises without Russian name (out of {len(exercises)})")

    if total == 0:
        print("Nothing to do.")
        return

    # Build index for fast lookup
    by_name = {ex["name"]: ex for ex in exercises}

    translated = 0
    failed     = 0
    batches    = [todo[i:i+BATCH_SIZE] for i in range(0, total, BATCH_SIZE)]

    for batch_idx, batch in enumerate(batches, 1):
        names = [ex["name"] for ex in batch]
        pct   = round(translated / total * 100)
        print(f"\nBatch {batch_idx}/{len(batches)}  ({pct}% done)  [{names[0][:40]}...]")

        mapping = translate_batch(names)

        if not mapping:
            print(f"  [skip] batch failed entirely, moving on")
            failed += len(names)
            continue

        for name in names:
            ru = mapping.get(name)
            if ru:
                by_name[name]["nameRu"] = ru
                translated += 1
            else:
                print(f"  [miss] no translation for: {name}")
                failed += 1

        # Save after every batch so progress survives interruption
        with open(EXERCISES, "w", encoding="utf-8") as f:
            json.dump(exercises, f, ensure_ascii=False, indent=2)

        print(f"  Saved. Translated so far: {translated}/{total}")
        time.sleep(0.5)   # small pause to be polite to the API

    print(f"\nDone. Translated: {translated}, failed: {failed}")


if __name__ == "__main__":
    main()
