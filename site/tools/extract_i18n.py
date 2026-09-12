#!/usr/bin/env python3
"""Разметка мастер-страниц ключами i18n и сборка словаря.

Читает site/index.html и site/404.html (русские мастер-страницы), находит
переводимый текст и атрибуты, проставляет data-i18n / data-i18n-attr и
собирает site/i18n/ru.json + _context.json.

Запуск:  python site/tools/extract_i18n.py
"""

from __future__ import annotations

import json
import re
from pathlib import Path

SITE = Path(__file__).resolve().parents[1]
I18N = SITE / "i18n"
PAGES = ["index.html", "404.html"]

VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link",
        "meta", "param", "source", "track", "wbr"}
SKIP_TEXT = {"script", "style", "code", "pre", "noscript", "svg"}
ATTRS = ["alt", "aria-label", "title", "content", "data-caption"]

TAG_RE = re.compile(
    r"<!--.*?-->"
    r"|<!DOCTYPE[^>]*>"
    r"|</\s*([a-zA-Z][\w:-]*)\s*>"
    r"|<([a-zA-Z][\w:-]*)((?:\"[^\"]*\"|'[^']*'|[^>\"'])*?)(/?)>",
    re.S,
)
CYR = re.compile(r"[\u0400-\u04FF]")


def has_cyr(s):
    return bool(CYR.search(s))


def slug(text, limit=28):
    t = re.sub(r"[^0-9A-Za-z\u0400-\u04FF]+", "-", text.strip().lower()).strip("-")
    return t[:limit] or "text"


class Node:
    __slots__ = ("tag", "attrs", "tag_start", "tag_end", "inner_start", "inner_end", "outer_end", "parent", "key")

    def __init__(self, tag, attrs, tag_start, tag_end, parent):
        self.tag = tag
        self.attrs = attrs
        self.tag_start = tag_start
        self.tag_end = tag_end
        self.inner_start = tag_end
        self.inner_end = None
        self.outer_end = tag_end
        self.parent = parent
        self.key = None

    def attr(self, name):
        m = re.search(r'(?<![\w-])' + re.escape(name) + r'\s*=\s*"([^"]*)"', self.attrs)
        return m.group(1) if m else None

    def set_attr(self, name, value):
        if re.search(r'(?<![\w-])' + re.escape(name) + r'\s*=\s*"[^"]*"', self.attrs):
            self.attrs = re.sub(r'(?<![\w-])' + re.escape(name) + r'\s*=\s*"[^"]*"',
                                f'{name}="{value}"', self.attrs, count=1)
        else:
            self.attrs = self.attrs.rstrip() + f' {name}="{value}"'


def walk(html):
    """Разбор разметки: список (узел, текст) для текстовых узлов верхнего уровня."""
    root = Node("#document", "", 0, 0, None)
    stack = [root]
    pos = 0
    nodes = []            # все элементы
    texts = []            # (текст, родитель, позиция)
    for m in TAG_RE.finditer(html):
        if m.start() > pos:
            chunk = html[pos:m.start()]
            if chunk.strip():
                texts.append((chunk, stack[-1], pos))
        pos = m.end()
        if m.group(0).startswith("<!--") or m.group(0).startswith("<!DOCTYPE"):
            continue
        if m.group(1):                      # закрывающий тег
            tag = m.group(1).lower()
            for i in range(len(stack) - 1, 0, -1):
                if stack[i].tag == tag:
                    stack[i].inner_end = m.start()
                    stack[i].outer_end = m.end()
                    del stack[i:]
                    break
            continue
        tag = (m.group(2) or "").lower()
        attrs = m.group(3) or ""
        self_closing = m.group(4) == "/"
        node = Node(tag, attrs, m.start(), m.end(), stack[-1])
        nodes.append(node)
        if node.parent is not None and node.parent is not root:
            pass
        if tag in VOID or self_closing:
            node.inner_end = m.end()
            continue
        stack.append(node)
    if html[pos:].strip():
        texts.append((html[pos:], stack[-1], pos))
    return root, nodes, texts


def norm(s):
    """Схлопываем переносы и отступы разметки, чтобы строки были удобны переводчику."""
    s = re.sub(r"\s*\n\s*", " ", s)
    s = re.sub(r"[ \t]{2,}", " ", s)
    return s.strip()


def section_of(node):
    """Человекочитаемый префикс ключа: ближайший id/класс + теги по пути."""
    parts = []
    cur = node
    while cur is not None and cur.tag != "#document":
        ident = cur.attr("id") or (cur.attr("class") or "").split(" ")[0]
        if ident:
            parts.append(slug(ident))
            break
        parts.append(cur.tag)
        cur = cur.parent
    return "-".join(reversed(parts)) or "page"


def extract_page(name, html):
    root, nodes, texts = walk(html)
    by_parent = {}
    for n in nodes:
        by_parent.setdefault(id(n.parent), []).append(n)

    d, ctx, edits, index_map, slots_out = {}, {}, [], {}, {}

    existing = {}
    for n in nodes:
        for a in ("data-i18n", "data-i18n-html"):
            v = n.attr(a)
            if v:
                existing[id(n)] = v

    def make_key(node, suffix=""):
        base = section_of(node) + "-" + node.tag + (("-" + suffix) if suffix else "")
        base = slug(base, 44)
        n = index_map.get(base, 0) + 1
        index_map[base] = n
        return f"{base}-{n}"

    def handle(node):
        inner = html[node.inner_start:node.inner_end] if node.inner_end else ""
        kids = [k for k in by_parent.get(id(node), [])]
        own_text = inner
        for k in kids:
            own_text = own_text.replace(html[k.tag_start:k.inner_end or k.tag_end], " ")
        cur = node
        while cur is not None:
            if "data-i18n-skip" in cur.attrs or cur.tag in SKIP_TEXT:
                return
            cur = cur.parent
        if not kids and has_cyr(inner):
            key = existing.get(id(node)) or make_key(node, "text")
            d[key] = norm(inner)
            ctx[key] = f"<{node.tag}> {section_of(node)}"
            node.set_attr("data-i18n", key)
            edits.append(node)
            return
        if kids and has_cyr(own_text) and len(inner) < 500 and len(kids) <= 4:
            key = existing.get(id(node)) or make_key(node, "html")
            value, slots = inner, []
            for k in kids:
                child = html[k.tag_start:k.outer_end]
                if has_cyr(child):
                    continue
                marker = "{{%d}}" % len(slots)
                slots.append(child)
                value = value.replace(child, marker)
            d[key] = norm(value)
            if slots:
                slots_out[key] = slots
            ctx[key] = f"<{node.tag} class=\"{node.attr('class') or ''}\"> (содержит разметку)"
            node.set_attr("data-i18n-html", key)
            edits.append(node)
            return
        for k in kids:
            handle(k)

    for n in by_parent.get(id(root), []):
        handle(n)

    # атрибуты
    for node in nodes:
        if node.tag in SKIP_TEXT:
            continue
        anc, skip = node, False
        while anc is not None:
            if "data-i18n-skip" in anc.attrs:
                skip = True
                break
            anc = anc.parent
        if skip:
            continue
        pairs = []
        for a in ATTRS:
            v = node.attr(a)
            if v and has_cyr(v) and a != "content":
                key = existing.get(id(node)) if False else make_key(node, a)
                d[key] = norm(v)
                ctx[key] = f"атрибут {a} у <{node.tag} class=\"{node.attr('class') or ''}\">"
                pairs.append(f"{a}:{key}")
            elif v and has_cyr(v) and a == "content":
                name_attr = node.attr("name") or node.attr("property") or ""
                key = make_key(node, slug(name_attr) or "content")
                d[key] = norm(v)
                ctx[key] = f"содержимое meta {name_attr}"
                pairs.append(f"content:{key}")
        if pairs:
            node.set_attr("data-i18n-attr", ", ".join(pairs))
            edits.append(node)

    # применяем правки атрибутов (разметку меняем одним проходом)
    edits.sort(key=lambda n: n.tag_start, reverse=True)
    out = html
    for node in edits:
        if node.inner_end is not None and node.inner_end < node.tag_start:
            continue
        open_tag = out[node.tag_start:node.tag_end]
        if node.attrs:
            closer = "/>" if open_tag.rstrip().endswith("/>") else ">"
            rebuilt = "<" + node.tag + node.attrs + closer
        else:
            rebuilt = open_tag
        out = out[:node.tag_start] + rebuilt + out[node.tag_end:]
    return out, d, ctx, slots_out


def main():
    I18N.mkdir(exist_ok=True)
    all_ru, all_ctx, all_slots = {}, {}, {}
    for page in PAGES:
        path = SITE / page
        html = path.read_text(encoding="utf-8")
        new_html, d, ctx, slots = extract_page(page, html)
        all_slots.update(slots)
        if new_html != html:
            path.write_text(new_html, encoding="utf-8")
        for k, v in d.items():
            if k in all_ru and all_ru[k] != v:
                k2 = f"{page.split('.')[0]}-{k}"
                d[k] = k2 if k2 not in all_ru else k2
                k = k2
            all_ru[k] = v
        all_ctx.update(ctx)
        print(f"{page}: ключей {len(d)}")
    # поля JSON-LD (лежат внутри <script>, разметкой не помечаются)
    idx = (SITE / "index.html").read_text(encoding="utf-8")
    ld = re.search(r'<script type="application/ld\+json">(.*?)</script>', idx, re.S)
    if ld:
        block = ld.group(1)
        m = re.search(r'"applicationSubCategory":\s*"([^"]*)"', block)
        if m:
            all_ru["jsonld-subcategory"] = m.group(1)
        m = re.search(r'"description":\s*"([^"]*)"', block)
        if m:
            all_ru["jsonld-description"] = m.group(1)
    (I18N / "ru.json").write_text(json.dumps(all_ru, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (I18N / "_context.json").write_text(json.dumps(all_ctx, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (I18N / "_slots.json").write_text(json.dumps(all_slots, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    words = sum(len(v.split()) for v in all_ru.values())
    print(f"всего ключей: {len(all_ru)}, слов: {words}")
    print("сохранено:", I18N / "ru.json")


if __name__ == "__main__":
    main()
