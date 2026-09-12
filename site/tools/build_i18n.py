#!/usr/bin/env python3
"""Сборка локализованных страниц сайта.

Источник — мастер-страницы (index.html, 404.html) с разметкой data-i18n
и словари site/i18n/<код>.json. Результат: site/<код>/index.html и 404.html
(русская версия остаётся в корне — она же язык по умолчанию).

Запуск:  python site/tools/build_i18n.py
"""

from __future__ import annotations

import base64
import hashlib
import html as html_mod
import json
import re
import sys
from pathlib import Path

SITE = Path(__file__).resolve().parents[1]
I18N = SITE / "i18n"
BASE = "https://fitnesbuster.ru"
sys.path.insert(0, str(Path(__file__).resolve().parent))
from extract_i18n import walk  # noqa: E402  (общий разбор разметки)

# код, самоназвание, og:locale, направление
LOCALES = [
    ("ru", "Русский", "ru_RU", "ltr"),
    ("en", "English", "en_US", "ltr"),
    ("de", "Deutsch", "de_DE", "ltr"),
    ("es", "Español", "es_ES", "ltr"),
    ("fr", "Français", "fr_FR", "ltr"),
    ("it", "Italiano", "it_IT", "ltr"),
    ("pt", "Português", "pt_PT", "ltr"),
    ("tr", "Türkçe", "tr_TR", "ltr"),
    ("uk", "Українська", "uk_UA", "ltr"),
    ("be", "Беларуская", "be_BY", "ltr"),
    ("ar", "العربية", "ar_AR", "rtl"),
    ("hi", "हिन्दी", "hi_IN", "ltr"),
    ("ja", "日本語", "ja_JP", "ltr"),
    ("ko", "한국어", "ko_KR", "ltr"),
    ("zh", "中文", "zh_CN", "ltr"),
]
CODES = [c for c, *_ in LOCALES]
NAMES = {c: n for c, n, *_ in LOCALES}
DIRS = {c: d for c, _, _, d in LOCALES}
OG = {c: o for c, _, o, _ in LOCALES}

# как называются страницы в URL: у русского — корень
def url_for(code: str, page: str) -> str:
    if code == "ru":
        return f"{BASE}/" if page == "index.html" else f"{BASE}/{page}"
    return f"{BASE}/{code}/" if page == "index.html" else f"{BASE}/{code}/{page}"


def esc_text(value: str) -> str:
    return html_mod.escape(value, quote=False)


def esc_attr(value: str) -> str:
    return html_mod.escape(value, quote=True)


def render(html: str, dic: dict, slots: dict) -> str:
    """Подставляет переводы в размеченную страницу."""
    root, nodes, _ = walk(html)
    edits = []
    for n in nodes:
        key = n.attr("data-i18n")
        if key and key in dic:
            edits.append((n.inner_start, n.inner_end, esc_text(dic[key])))
            continue
        key = n.attr("data-i18n-html")
        if key and key in dic:
            value = dic[key]
            for i, snippet in enumerate(slots.get(key, [])):
                value = value.replace("{{%d}}" % i, snippet)
            edits.append((n.inner_start, n.inner_end, value))
        pairs = n.attr("data-i18n-attr")
        if pairs:
            tag = html[n.tag_start:n.tag_end]
            changed = False
            for item in pairs.split(","):
                attr, _, akey = item.strip().partition(":")
                if akey in dic:
                    tag = re.sub(r'(?<![\w-])' + re.escape(attr) + r'\s*=\s*"[^"]*"',
                                 f'{attr}="{esc_attr(dic[akey])}"', tag, count=1)
                    changed = True
            if changed:
                edits.append((n.tag_start, n.tag_end, tag))
    edits.sort(key=lambda e: e[0], reverse=True)
    out = html
    for start, end, piece in edits:
        out = out[:start] + piece + out[end:]
    return out


IMG_META = {"og:image", "og:image:url", "og:image:secure_url", "twitter:image",
            "twitter:image:src"}


def _abs(value: str) -> str:
    if value.startswith(("#", "/", "http", "mailto:", "data:", "tel:")):
        return value
    return "/" + value


def root_paths(html: str) -> str:
    """Пути от корня: страницы лежат и в /en/, и в корне.

    Внимание: content у мета-тегов трогаем только у картинок для соцсетей —
    у viewport, og:type, twitter:card и описаний это не путь.
    """
    def fix_meta(m):
        tag = m.group(0)
        prop = re.search(r'(?:property|name)="([^"]+)"', tag)
        if not prop or prop.group(1) not in IMG_META:
            return tag
        return re.sub(r'content="([^"]+)"', lambda c: f'content="{_abs(c.group(1))}"', tag, count=1)

    html = re.sub(r'<meta[^>]*>', fix_meta, html)

    def fix_attr(m):
        attr, value = m.group(1), m.group(2)
        if attr == "srcset":
            items = []
            for item in value.split(","):
                item = item.strip()
                if not item:
                    continue
                bits = item.split(None, 1)
                bits[0] = _abs(bits[0])
                items.append(" ".join(bits))
            return f'{attr}="{", ".join(items)}"'
        return f'{attr}="{_abs(value)}"'

    html = re.sub(r'(href|src|srcset|poster|data-full|data-full-jpg|data-src)="([^"]+)"', fix_attr, html)
    html = html.replace('href="/index.html', 'href="/')
    return html


def head_tags(code: str, page: str, html: str) -> str:
    """Canonical + hreflang на все 15 языков + og:locale/og:url."""
    alts = "\n".join(
        f'    <link rel="alternate" hreflang="{c}" href="{url_for(c, page)}" />'
        for c in CODES)
    alts += f'\n    <link rel="alternate" hreflang="x-default" href="{url_for("ru", page)}" />'
    return alts


def apply_head(html: str, code: str, page: str) -> str:
    url = url_for(code, page)
    html = re.sub(r'<link rel="canonical" href="[^"]*" />',
                  f'<link rel="canonical" href="{url}" />\n{head_tags(code, page, html)}', html, count=1)
    if 'property="og:locale"' in html:
        html = re.sub(r'(<meta property="og:locale" content=")[^"]*(")',
                      rf'\g<1>{OG[code]}\g<2>', html, count=1)
    else:
        html = html.replace('<meta property="og:type"',
                            f'<meta property="og:locale" content="{OG[code]}" />\n    <meta property="og:type"', 1)
    if 'property="og:url"' in html:
        html = re.sub(r'(<meta property="og:url" content=")[^"]*(")', rf'\g<1>{url}\g<2>', html, count=1)
    else:
        html = html.replace('<meta property="og:locale"',
                            f'<meta property="og:url" content="{url}" />\n    <meta property="og:locale"', 1)
    return html


def apply_lang(html: str, code: str) -> str:
    direction = DIRS[code]
    html = re.sub(r'<html lang="[^"]*"', f'<html lang="{code}"', html, count=1)
    if direction == "rtl" and 'dir="rtl"' not in html:
        html = html.replace(f'<html lang="{code}"', f'<html lang="{code}" dir="rtl"', 1)
    return html


def apply_switcher(html: str, code: str) -> str:
    html = re.sub(r'(class="lang__link)( is-current)?(")', r'\1\3', html)
    target = 'class="lang__link" href="/"' if code == "ru" else f'class="lang__link" href="/{code}/"'
    if target in html:
        html = html.replace(target, target.replace('class="lang__link"', 'class="lang__link is-current"'), 1)
    html = re.sub(r'(<span class="lang__code">)[^<]*(</span>)',
                  rf'\g<1>{code.upper()}\g<2>', html, count=1)
    return html


def apply_jsonld(html: str, code: str, dic: dict) -> str:
    html = html.replace('"inLanguage": "ru"', f'"inLanguage": "{code}"')
    for field, key in [("applicationSubCategory", "jsonld-subcategory"),
                       ("description", "jsonld-description")]:
        if key in dic:
            html = re.sub(rf'("{field}":\s*")[^"]*(")', lambda m: m.group(1) + dic[key].replace('\\', r'\\').replace('"', r'\"') + m.group(2), html, count=1)
    return html


def main() -> None:
    masters = {}
    for page in ["index.html", "404.html"]:
        masters[page] = (SITE / page).read_text(encoding="utf-8")
    slots = json.loads((I18N / "_slots.json").read_text(encoding="utf-8"))
    hashes = []
    written = 0
    for code in CODES:
        dict_path = I18N / f"{code}.json"
        if not dict_path.exists():
            print(f"  {code}: нет словаря — пропуск")
            continue
        dic = json.loads(dict_path.read_text(encoding="utf-8"))
        for page, master in masters.items():
            html = render(master, dic, slots)
            html = root_paths(html)
            html = apply_lang(html, code)
            html = apply_head(html, code, page)
            html = apply_switcher(html, code)
            html = apply_jsonld(html, code, dic)
            out_dir = SITE if code == "ru" else SITE / code
            out_dir.mkdir(parents=True, exist_ok=True)
            (out_dir / page).write_text(html, encoding="utf-8")
            written += 1
            m = re.search(r'<script type="application/ld\+json">(.*?)</script>', html, re.S)
            if m:
                digest = base64.b64encode(hashlib.sha256(m.group(1).encode("utf-8")).digest()).decode()
                hashes.append(digest)
    print(f"страниц записано: {written}, хешей JSON-LD: {len(set(hashes))}")
    write_csp(sorted(set(hashes)))
    write_sitemap()


def write_csp(hashes: list) -> None:
    inc = SITE / "deploy" / "nginx" / "fitnesbuster-headers.inc"
    if not inc.exists():
        return
    text = inc.read_text(encoding="utf-8")
    scripts = " ".join(f"'sha256-{h}'" for h in hashes)
    new = re.sub(r"script-src 'self'[^;]*;",
                 f"script-src 'self' {scripts};", text, count=1)
    if new != text:
        inc.write_text(new, encoding="utf-8")
        print(f"CSP обновлена: хешей {len(hashes)}")


def write_sitemap() -> None:
    rows = []
    for page in ["index.html", "404.html"]:
        if page == "404.html":
            continue
        rows.append(f"  <url>\n    <loc>{url_for('ru', page)}</loc>\n"
                    + "\n".join(f'    <xhtml:link rel="alternate" hreflang="{c}" href="{url_for(c, page)}" />' for c in CODES)
                    + "\n  </url>")
        for c in CODES:
            if c == "ru":
                continue
            rows.append(f"  <url>\n    <loc>{url_for(c, page)}</loc>\n"
                        + "\n".join(f'    <xhtml:link rel="alternate" hreflang="{a}" href="{url_for(a, page)}" />' for a in CODES)
                        + "\n  </url>")
    for legal in ["privacy.html", "terms.html"]:
        rows.append(f"  <url>\n    <loc>{BASE}/{legal}</loc>\n  </url>")
    xml = ('<?xml version="1.0" encoding="UTF-8"?>\n'
           '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" '
           'xmlns:xhtml="http://www.w3.org/1999/xhtml">\n'
           + "\n".join(rows) + "\n</urlset>\n")
    (SITE / "sitemap.xml").write_text(xml, encoding="utf-8")
    print(f"sitemap: {len(rows)} адресов")


if __name__ == "__main__":
    main()
