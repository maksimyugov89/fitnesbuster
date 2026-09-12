#!/usr/bin/env python3
"""Собирает глоссарий терминов из переводов приложения.

Берёт lib/core/localization/translations/<язык>.dart и выписывает короткие
строки интерфейса, чтобы переводы сайта совпадали с приложением.

Результат: site/i18n/_glossary.json (генерируется, в репозитории не хранится).

Запуск:  python site/tools/build_glossary.py
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TR = ROOT / "lib" / "core" / "localization" / "translations"
OUT = ROOT / "site" / "i18n" / "_glossary.json"
LANGS = ["ru", "en", "de", "es", "fr", "it", "pt", "tr", "uk", "be", "ar", "hi", "ja", "ko", "zh"]
PAT = re.compile(
    r"(nav|workout|training|nutrition|calorie|progress|recover|sleep|water|step|goal|friend|"
    r"challeng|achiev|plan|coach|health|muscle|exercise|purchase|shopping|streak|level|theme|"
    r"onboard|backup|privacy|terms|export|reminder|welcome|statistic|chart|measure|weight|"
    r"profile|feed|avatar|language|notification)", re.I)


def parse(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    return {m.group(1): m.group(2).replace("\\'", "'").replace('\\"', '"')
            for m in re.finditer(r"'([A-Za-z0-9_.]+)'\s*:\s*'((?:[^'\\]|\\.)*)'", text)}


def main() -> None:
    data = {lg: parse(TR / f"{lg}.dart") for lg in LANGS}
    glossary = {}
    for key in data["ru"]:
        if not PAT.search(key):
            continue
        row = {lg: data[lg].get(key) for lg in LANGS}
        if all(row.values()) and all(len(v) < 70 and "{" not in v for v in row.values()):
            glossary[key] = row
    OUT.write_text(json.dumps(glossary, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"терминов: {len(glossary)} -> {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
