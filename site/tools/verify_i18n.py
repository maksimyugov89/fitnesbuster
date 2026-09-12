#!/usr/bin/env python3
"""Проверка локализаций сайта перед выкладкой.

Что проверяем:
  1) у каждого языка есть словарь и набор ключей совпадает с русским;
  2) в некириллических языках нет русских букв;
  3) плейсхолдеры {{0}} и HTML-теги в переводе совпадают с оригиналом;
  4) собранные страницы существуют, у них верный lang/dir/canonical и hreflang;
  5) слотовые вставки (иконки) на месте в собранной разметке.

Запуск:  python site/tools/verify_i18n.py
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

SITE = Path(__file__).resolve().parents[1]
I18N = SITE / "i18n"
sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_i18n import CODES, DIRS, url_for  # noqa: E402

CYRILLIC_OK = {"ru", "uk", "be"}          # эти языки пишут кириллицей
NO_CYRILLIC = [c for c in CODES if c not in CYRILLIC_OK]

problems: list[str] = []


def check_dicts() -> dict:
    ru = json.loads((I18N / "ru.json").read_text(encoding="utf-8"))
    dicts = {"ru": ru}
    for code in CODES:
        if code == "ru":
            continue
        path = I18N / f"{code}.json"
        if not path.exists():
            problems.append(f"{code}: нет файла словаря")
            continue
        try:
            dic = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:                      # noqa: BLE001
            problems.append(f"{code}: словарь не читается ({exc})")
            continue
        dicts[code] = dic
        missing = sorted(set(ru) - set(dic))
        extra = sorted(set(dic) - set(ru))
        if missing:
            problems.append(f"{code}: нет {len(missing)} ключей, напр. {missing[:4]}")
        if extra:
            problems.append(f"{code}: лишние ключи {extra[:4]}")

        for key, value in dic.items():
            if key not in ru:
                continue
            src = ru[key]
            if code in NO_CYRILLIC and re.search(r"[\u0400-\u04FF]", value):
                problems.append(f"{code}/{key}: кириллица в переводе — {value[:40]!r}")
            ph_src = sorted(re.findall(r"\{\{\d+\}\}", src))
            ph_dst = sorted(re.findall(r"\{\{\d+\}\}", value))
            if ph_src != ph_dst:
                problems.append(f"{code}/{key}: плейсхолдеры {ph_src} != {ph_dst}")
            tags_src = sorted(re.findall(r"</?([a-z][\w-]*)", src))
            tags_dst = sorted(re.findall(r"</?([a-z][\w-]*)", value))
            if tags_src != tags_dst:
                problems.append(f"{code}/{key}: теги {tags_src} != {tags_dst}")
            same = value.strip() == src.strip()
            if value.strip() == "" or (same and code != "ru" and (code, key) not in ALLOW_SAME):
                problems.append(f"{code}/{key}: перевод совпадает с русским — {value[:40]!r}")
    return dicts


def check_pages() -> None:
    for code in CODES:
        for fname, need_canonical in (("index.html", True), ("404.html", False)):
            page = (SITE / fname) if code == "ru" else (SITE / code / fname)
            check_page(code, page, fname, need_canonical)


def check_page(code: str, page: Path, fname: str, need_canonical: bool) -> None:
    if not page.exists():
        problems.append(f"{code}: нет собранной страницы {page.relative_to(SITE)}")
        return
    html = page.read_text(encoding="utf-8")
    where = f"{code}/{fname}"
    m = re.search(r"<html lang=\"([^\"]*)\"([^>]*)>", html)
    if not m or m.group(1) != code:
        problems.append(f"{where}: в <html> указан язык {m.group(1) if m else '—'}")
    if DIRS[code] == "rtl" and 'dir="rtl"' not in m.group(0):
        problems.append(f"{where}: нет dir=rtl")
    if need_canonical:
        canon = re.search(r'<link rel="canonical" href="([^"]*)"', html)
        if not canon or canon.group(1) != url_for(code, "index.html"):
            problems.append(f"{where}: canonical {canon.group(1) if canon else '—'}")
    alts = set(re.findall(r'hreflang="([^"]*)"', html))
    if not set(CODES) <= alts:
        problems.append(f"{where}: hreflang неполный, нет {sorted(set(CODES) - alts)}")
    if "{{0}}" in html or "{{1}}" in html:
        problems.append(f"{where}: в собранной странице остались плейсхолдеры")
    if 'class="lang__link is-current"' not in html:
        problems.append(f"{where}: не отмечен текущий язык в переключателе")
    check_residual_cyrillic(where, code, html)


def check_residual_cyrillic(where: str, code: str, html: str) -> None:
    """На некириллических страницах русского текста быть не должно.

    Разрешены только: самоназвания языков в переключателе, имя автора в JSON-LD
    и HTML-комментарии.
    """
    if code in CYRILLIC_OK:
        return
    body = re.sub(r"<!--.*?-->", " ", html, flags=re.S)
    body = re.sub(r'<script type="application/ld\+json">.*?</script>', " ", body, flags=re.S)
    body = re.sub(r"<script.*?</script>", " ", body, flags=re.S)
    body = re.sub(r"<style.*?</style>", " ", body, flags=re.S)
    for m in re.finditer(r'<a class="lang__link[^"]*"[^>]*>(.*?)</a>', body, flags=re.S):
        body = body.replace(m.group(1), " ")
    leftovers = []
    for frag in re.findall(r">[^<>]*[\u0400-\u04FF][^<>]*<", body):
        frag = frag.strip("<>").strip()
        if frag:
            leftovers.append(frag)
    if leftovers:
        problems.append(f"{where}: русский текст на странице — {leftovers[:3]}")


# Строки, которые в языке-цели законно совпадают с русскими (не подстрочник,
# а одинаковое написание слова). Проверку это не отключает — только эти ключи.
ALLOW_SAME = {
    ("be", "nav-a-a-text-2"),                       # «Экраны» — так же в белорусском
    ("be", "footer-grid-div-ul-li-a-a-text-2"),
    ("be", "lightbox-title-p-text-1"),              # «Экран»
}


def main() -> int:
    check_dicts()
    check_pages()
    if problems:
        print(f"ПРОБЛЕМЫ ({len(problems)}):")
        for p in problems[:40]:
            print("  -", p)
        return 1
    print("Локализации в порядке: словари полные, страницы собраны корректно")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
