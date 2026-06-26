"""
Build interactive anatomy SVGs for FitnesBuster.

Strategy:
  1. Optimize front_preview.png / back_preview.png → front_body.png / back_body.png
  2. Build front_interactive.svg and back_interactive.svg:
       - <image> background referencing the optimized PNG
       - transparent <g id="muscle_id"> hit zones per muscle
  3. Generate muscle_manifest.json

Coordinate system: 1024 x 1536
Left/right convention: anatomical (figure's perspective)
  _left  → figure's LEFT  → viewer's RIGHT (x > 512)
  _right → figure's RIGHT → viewer's LEFT  (x < 512)
"""

import json
import numpy as np
from PIL import Image
from pathlib import Path

BASE = Path(r"c:\Users\Despa\fitnesbuster\assets\anatomy")

# ──────────────────────────────────────────────────────────────────────────────
# Step 1 – Optimise PNGs (keep transparency, reduce to 512×768 for lighter SVG)
# ──────────────────────────────────────────────────────────────────────────────

SCALE = 0.5   # 1024×1536 → 512×768  (2× display density on phones = sharp)

def optimise_png(src: str, dst: str):
    img = Image.open(src).convert("RGBA")
    w, h = img.size
    new_w, new_h = int(w * SCALE), int(h * SCALE)
    img = img.resize((new_w, new_h), Image.LANCZOS)
    img.save(dst, "PNG", optimize=True, compress_level=9)
    size_kb = Path(dst).stat().st_size // 1024
    print(f"  {Path(dst).name}: {new_w}x{new_h}, {size_kb} KB")
    return new_w, new_h

print("Step 1: Optimising background PNGs...")
fw, fh = optimise_png(BASE / "front_preview.png", BASE / "front_body.png")
bw, bh = optimise_png(BASE / "back_preview.png",  BASE / "back_body.png")


# ──────────────────────────────────────────────────────────────────────────────
# Step 2 – Define muscle zone polygons (in original 1024×1536 coordinates)
# ──────────────────────────────────────────────────────────────────────────────
#
# Polygons are lists of (x, y) tuples.
# Generated from visual analysis of front_preview.png / back_preview.png.
#
# Naming (anatomical):
#   _right = figure's right = viewer's LEFT  (x < 512)
#   _left  = figure's left  = viewer's RIGHT (x > 512)
#
# ──────────────────────────────────────────────────────────────────────────────

FRONT_ZONES = {

    "neck": [
        (455, 225), (570, 225),
        (578, 298), (448, 298),
    ],

    "upper_trapezius": [
        (448, 215), (572, 215),
        (718, 305), (700, 335),
        (570, 292), (455, 292),
        (325, 335), (307, 305),
    ],

    # ── Deltoids ──────────────────────────────────────────────────────────────

    "anterior_deltoid_right": [   # figure's right = viewer's left
        (295, 300), (390, 300),
        (395, 385), (365, 450),
        (260, 445), (258, 380),
    ],
    "anterior_deltoid_left": [    # figure's left  = viewer's right
        (635, 300), (730, 300),
        (767, 380), (765, 445),
        (630, 450), (608, 385),
    ],

    "lateral_deltoid_right": [
        (200, 295), (300, 295),
        (275, 455), (185, 445),
    ],
    "lateral_deltoid_left": [
        (725, 295), (825, 295),
        (840, 445), (750, 455),
    ],

    # ── Pectorals ─────────────────────────────────────────────────────────────

    "pectoralis_upper_right": [
        (370, 298), (510, 298),
        (508, 445), (352, 435),
    ],
    "pectoralis_upper_left": [
        (515, 298), (655, 298),
        (673, 435), (515, 445),
    ],

    "pectoralis_lower_right": [
        (365, 445), (508, 445),
        (505, 518), (388, 528),
    ],
    "pectoralis_lower_left": [
        (515, 445), (660, 445),
        (637, 528), (518, 518),
    ],

    # ── Upper arm ─────────────────────────────────────────────────────────────

    "biceps_right": [
        (225, 455), (365, 455),
        (368, 630), (218, 625),
    ],
    "biceps_left": [
        (660, 455), (800, 455),
        (808, 625), (658, 630),
    ],

    "forearm_flexors_right": [
        (208, 635), (370, 635),
        (355, 830), (200, 820),
    ],
    "forearm_flexors_left": [
        (655, 635), (820, 635),
        (828, 820), (670, 830),
    ],

    # ── Abdomen ───────────────────────────────────────────────────────────────

    "rectus_abdominis": [
        (452, 518), (572, 518),
        (568, 840), (455, 840),
    ],

    "external_oblique_right": [
        (372, 518), (452, 518),
        (448, 840), (358, 800),
        (355, 680),
    ],
    "external_oblique_left": [
        (572, 518), (652, 518),
        (668, 680), (665, 800),
        (575, 840),
    ],

    # ── Hip / Pelvis ──────────────────────────────────────────────────────────

    "hip_flexors_right": [
        (385, 840), (510, 840),
        (502, 960), (375, 952),
    ],
    "hip_flexors_left": [
        (515, 840), (640, 840),
        (650, 952), (522, 960),
    ],

    # ── Thigh ─────────────────────────────────────────────────────────────────

    "adductors_right": [
        (430, 960), (510, 960),
        (508, 1185), (435, 1182),
    ],
    "adductors_left": [
        (515, 960), (595, 960),
        (590, 1182), (515, 1185),
    ],

    "quadriceps_right": [
        (350, 952), (430, 952),
        (435, 1185), (345, 1178),
    ],
    "quadriceps_left": [
        (595, 952), (675, 952),
        (680, 1178), (568, 1185),
    ],

    # ── Lower leg ─────────────────────────────────────────────────────────────

    "tibialis_anterior_right": [
        (415, 1192), (505, 1192),
        (498, 1390), (420, 1388),
    ],
    "tibialis_anterior_left": [
        (520, 1192), (610, 1192),
        (605, 1388), (525, 1390),
    ],
}


BACK_ZONES = {

    # ── Deltoids ──────────────────────────────────────────────────────────────

    "posterior_deltoid_right": [
        (225, 298), (355, 298),
        (375, 458), (210, 452),
    ],
    "posterior_deltoid_left": [
        (672, 298), (800, 298),
        (815, 452), (650, 458),
    ],

    # ── Trapezius ─────────────────────────────────────────────────────────────

    "middle_trapezius": [
        (355, 298), (672, 298),
        (660, 525), (368, 525),
    ],

    "lower_trapezius": [
        (400, 525), (625, 525),
        (560, 710), (470, 710),
    ],

    # ── Back muscles ──────────────────────────────────────────────────────────

    "latissimus_right": [
        (268, 475), (445, 475),
        (420, 730), (265, 710),
    ],
    "latissimus_left": [
        (580, 475), (758, 475),
        (760, 710), (603, 730),
    ],

    "teres_major_right": [
        (268, 435), (385, 435),
        (408, 530), (270, 528),
    ],
    "teres_major_left": [
        (640, 435), (758, 435),
        (756, 528), (617, 530),
    ],

    # ── Triceps ───────────────────────────────────────────────────────────────

    "triceps_right": [
        (195, 432), (305, 432),
        (318, 678), (188, 665),
    ],
    "triceps_left": [
        (720, 432), (832, 432),
        (840, 665), (708, 678),
    ],

    # ── Spine ─────────────────────────────────────────────────────────────────

    "erector_spinae": [
        (435, 710), (592, 710),
        (580, 940), (445, 940),
    ],

    # ── Glutes ────────────────────────────────────────────────────────────────

    "gluteus_medius_right": [
        (340, 810), (472, 810),
        (480, 912), (342, 910),
    ],
    "gluteus_medius_left": [
        (553, 810), (688, 810),
        (685, 910), (543, 912),
    ],

    "gluteus_maximus_right": [
        (370, 910), (510, 910),
        (505, 1090), (352, 1082),
    ],
    "gluteus_maximus_left": [
        (515, 910), (655, 910),
        (673, 1082), (520, 1090),
    ],

    # ── Hamstrings ────────────────────────────────────────────────────────────

    "hamstrings_right": [
        (358, 1090), (510, 1090),
        (505, 1200), (360, 1196),
    ],
    "hamstrings_left": [
        (515, 1090), (668, 1090),
        (665, 1196), (520, 1200),
    ],

    # ── Calf ──────────────────────────────────────────────────────────────────

    "gastrocnemius_right": [
        (382, 1205), (498, 1205),
        (492, 1345), (388, 1342),
    ],
    "gastrocnemius_left": [
        (527, 1205), (643, 1205),
        (638, 1342), (532, 1345),
    ],

    "soleus_right": [
        (390, 1348), (490, 1348),
        (482, 1448), (395, 1446),
    ],
    "soleus_left": [
        (535, 1348), (635, 1348),
        (630, 1446), (540, 1448),
    ],
}


# ──────────────────────────────────────────────────────────────────────────────
# Step 3 – Clip zones to body silhouette
# ──────────────────────────────────────────────────────────────────────────────

def load_mask(png_path: str, threshold: int = 20) -> np.ndarray:
    """Return boolean mask where body pixels are True (non-white, non-transparent)."""
    img = np.array(Image.open(png_path).convert("RGBA"))
    alpha = img[:, :, 3]
    r, g, b = img[:, :, 0], img[:, :, 1], img[:, :, 2]
    # Body = has alpha OR is not near-white
    body = (alpha > threshold) | (r < 240) | (g < 240) | (b < 240)
    return body  # shape (H, W)


def pts_to_svg_d(pts):
    """Convert list of (x,y) to SVG path data string."""
    parts = [f"M {pts[0][0]},{pts[0][1]}"]
    for x, y in pts[1:]:
        parts.append(f"L {x},{y}")
    parts.append("Z")
    return " ".join(parts)


def polygon_in_mask(pts, mask):
    """Check if at least some part of polygon intersects the mask."""
    H, W = mask.shape
    # Quick bounding-box check
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    x0, x1 = max(0, min(xs)), min(W-1, max(xs))
    y0, y1 = max(0, min(ys)), min(H-1, max(ys))
    region = mask[y0:y1+1, x0:x1+1]
    return region.any()


# ──────────────────────────────────────────────────────────────────────────────
# Step 4 – Generate interactive SVG
# ──────────────────────────────────────────────────────────────────────────────

HIGHLIGHT_COLOR = "#E8453C"   # red highlight used by Flutter when muscle is active

def build_svg(zones: dict, body_png_name: str, svg_width=1024, svg_height=1536) -> str:
    # Flutter resolves asset hrefs relative to the SVG's own asset path.
    # Since both PNG and SVG are in assets/anatomy/, just the filename is enough.
    lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"',
        f'     width="{svg_width}" height="{svg_height}" viewBox="0 0 {svg_width} {svg_height}">',
        '',
        '  <!-- Background anatomical rendering.',
        '       Flutter Stack usage:',
        '         Stack(children: [',
        f'           Image.asset("assets/anatomy/{body_png_name}"),',
        '           SvgPicture.asset("assets/anatomy/...interactive.svg"),',
        '         ])',
        '  -->',
        f'  <image id="body-background" href="{body_png_name}"',
        f'         x="0" y="0" width="{svg_width}" height="{svg_height}"',
        '         preserveAspectRatio="xMidYMid meet"/>',
        '',
        '  <!-- Interactive muscle zones',
        '       Default: fill-opacity="0" (invisible)',
        '       Activated by Flutter: fill-opacity="0.45" to highlight -->',
    ]

    for muscle_id, pts in zones.items():
        d = pts_to_svg_d(pts)
        lines.append(f'  <g id="{muscle_id}" class="muscle-zone">')
        lines.append(f'    <path d="{d}"')
        lines.append(f'          fill="{HIGHLIGHT_COLOR}" fill-opacity="0"')
        lines.append(f'          stroke="{HIGHLIGHT_COLOR}" stroke-opacity="0"')
        lines.append(f'          stroke-width="1.5"/>')
        lines.append(f'  </g>')

    lines.append('')
    lines.append('</svg>')
    return '\n'.join(lines)


# ──────────────────────────────────────────────────────────────────────────────
# Step 5 – Muscle manifest
# ──────────────────────────────────────────────────────────────────────────────

MANIFEST = {
    # FRONT
    "neck":                        {"displayName": "Neck",                         "displayNameRu": "Шея",                              "view": "front"},
    "upper_trapezius":             {"displayName": "Upper Trapezius",              "displayNameRu": "Верхняя трапеция",                  "view": "front"},
    "anterior_deltoid_left":       {"displayName": "Left Anterior Deltoid",        "displayNameRu": "Передняя дельта (левая)",           "view": "front"},
    "anterior_deltoid_right":      {"displayName": "Right Anterior Deltoid",       "displayNameRu": "Передняя дельта (правая)",          "view": "front"},
    "lateral_deltoid_left":        {"displayName": "Left Lateral Deltoid",         "displayNameRu": "Средняя дельта (левая)",            "view": "front"},
    "lateral_deltoid_right":       {"displayName": "Right Lateral Deltoid",        "displayNameRu": "Средняя дельта (правая)",           "view": "front"},
    "pectoralis_upper_left":       {"displayName": "Left Upper Pectoralis",        "displayNameRu": "Верх грудной мышцы (левой)",        "view": "front"},
    "pectoralis_upper_right":      {"displayName": "Right Upper Pectoralis",       "displayNameRu": "Верх грудной мышцы (правой)",       "view": "front"},
    "pectoralis_lower_left":       {"displayName": "Left Lower Pectoralis",        "displayNameRu": "Низ грудной мышцы (левой)",         "view": "front"},
    "pectoralis_lower_right":      {"displayName": "Right Lower Pectoralis",       "displayNameRu": "Низ грудной мышцы (правой)",        "view": "front"},
    "biceps_left":                 {"displayName": "Left Biceps",                  "displayNameRu": "Бицепс (левый)",                    "view": "front"},
    "biceps_right":                {"displayName": "Right Biceps",                 "displayNameRu": "Бицепс (правый)",                   "view": "front"},
    "forearm_flexors_left":        {"displayName": "Left Forearm Flexors",         "displayNameRu": "Сгибатели предплечья (левого)",     "view": "front"},
    "forearm_flexors_right":       {"displayName": "Right Forearm Flexors",        "displayNameRu": "Сгибатели предплечья (правого)",    "view": "front"},
    "rectus_abdominis":            {"displayName": "Rectus Abdominis",             "displayNameRu": "Прямая мышца живота",               "view": "front"},
    "external_oblique_left":       {"displayName": "Left External Oblique",        "displayNameRu": "Косые мышцы (левые)",               "view": "front"},
    "external_oblique_right":      {"displayName": "Right External Oblique",       "displayNameRu": "Косые мышцы (правые)",              "view": "front"},
    "hip_flexors_left":            {"displayName": "Left Hip Flexors",             "displayNameRu": "Сгибатели бедра (левого)",          "view": "front"},
    "hip_flexors_right":           {"displayName": "Right Hip Flexors",            "displayNameRu": "Сгибатели бедра (правого)",         "view": "front"},
    "adductors_left":              {"displayName": "Left Adductors",               "displayNameRu": "Приводящие мышцы (левые)",          "view": "front"},
    "adductors_right":             {"displayName": "Right Adductors",              "displayNameRu": "Приводящие мышцы (правые)",         "view": "front"},
    "quadriceps_left":             {"displayName": "Left Quadriceps",              "displayNameRu": "Квадрицепс (левый)",                "view": "front"},
    "quadriceps_right":            {"displayName": "Right Quadriceps",             "displayNameRu": "Квадрицепс (правый)",               "view": "front"},
    "tibialis_anterior_left":      {"displayName": "Left Tibialis Anterior",       "displayNameRu": "Передняя большеберцовая (левая)",   "view": "front"},
    "tibialis_anterior_right":     {"displayName": "Right Tibialis Anterior",      "displayNameRu": "Передняя большеберцовая (правая)",  "view": "front"},
    # BACK
    "posterior_deltoid_left":      {"displayName": "Left Posterior Deltoid",       "displayNameRu": "Задняя дельта (левая)",             "view": "back"},
    "posterior_deltoid_right":     {"displayName": "Right Posterior Deltoid",      "displayNameRu": "Задняя дельта (правая)",            "view": "back"},
    "middle_trapezius":            {"displayName": "Middle Trapezius",             "displayNameRu": "Средняя трапеция",                  "view": "back"},
    "lower_trapezius":             {"displayName": "Lower Trapezius",              "displayNameRu": "Нижняя трапеция",                   "view": "back"},
    "latissimus_left":             {"displayName": "Left Latissimus Dorsi",        "displayNameRu": "Широчайшая (левая)",                "view": "back"},
    "latissimus_right":            {"displayName": "Right Latissimus Dorsi",       "displayNameRu": "Широчайшая (правая)",               "view": "back"},
    "teres_major_left":            {"displayName": "Left Teres Major",             "displayNameRu": "Большая круглая (левая)",           "view": "back"},
    "teres_major_right":           {"displayName": "Right Teres Major",            "displayNameRu": "Большая круглая (правая)",          "view": "back"},
    "triceps_left":                {"displayName": "Left Triceps",                 "displayNameRu": "Трицепс (левый)",                   "view": "back"},
    "triceps_right":               {"displayName": "Right Triceps",                "displayNameRu": "Трицепс (правый)",                  "view": "back"},
    "erector_spinae":              {"displayName": "Erector Spinae",               "displayNameRu": "Разгибатели позвоночника",          "view": "back"},
    "gluteus_maximus_left":        {"displayName": "Left Gluteus Maximus",         "displayNameRu": "Большая ягодичная (левая)",         "view": "back"},
    "gluteus_maximus_right":       {"displayName": "Right Gluteus Maximus",        "displayNameRu": "Большая ягодичная (правая)",        "view": "back"},
    "gluteus_medius_left":         {"displayName": "Left Gluteus Medius",          "displayNameRu": "Средняя ягодичная (левая)",         "view": "back"},
    "gluteus_medius_right":        {"displayName": "Right Gluteus Medius",         "displayNameRu": "Средняя ягодичная (правая)",        "view": "back"},
    "hamstrings_left":             {"displayName": "Left Hamstrings",              "displayNameRu": "Задняя поверхность бедра (левая)",  "view": "back"},
    "hamstrings_right":            {"displayName": "Right Hamstrings",             "displayNameRu": "Задняя поверхность бедра (правая)", "view": "back"},
    "gastrocnemius_left":          {"displayName": "Left Gastrocnemius",           "displayNameRu": "Икроножная (левая)",                "view": "back"},
    "gastrocnemius_right":         {"displayName": "Right Gastrocnemius",          "displayNameRu": "Икроножная (правая)",               "view": "back"},
    "soleus_left":                 {"displayName": "Left Soleus",                  "displayNameRu": "Камбаловидная (левая)",             "view": "back"},
    "soleus_right":                {"displayName": "Right Soleus",                 "displayNameRu": "Камбаловидная (правая)",            "view": "back"},
}


# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────

print("\nStep 2: Loading body masks for zone validation...")
front_mask = load_mask(BASE / "front_preview.png")
back_mask  = load_mask(BASE / "back_preview.png")
print(f"  Front mask: {front_mask.shape}, body pixels: {front_mask.sum():,}")
print(f"  Back  mask: {back_mask.shape},  body pixels: {back_mask.sum():,}")

# Validate zones intersect body
print("\nStep 3: Validating front zones...")
for zid, pts in FRONT_ZONES.items():
    ok = polygon_in_mask(pts, front_mask)
    status = "OK" if ok else "MISS"
    print(f"  [{status}] {zid}")

print("\nStep 3: Validating back zones...")
for zid, pts in BACK_ZONES.items():
    ok = polygon_in_mask(pts, back_mask)
    status = "OK" if ok else "MISS"
    print(f"  [{status}] {zid}")

print("\nStep 4: Building SVG files...")
front_svg = build_svg(FRONT_ZONES, "front_body.png")
back_svg  = build_svg(BACK_ZONES,  "back_body.png")

front_out = BASE / "front_interactive.svg"
back_out  = BASE / "back_interactive.svg"
manifest_out = BASE / "muscle_manifest.json"

front_out.write_text(front_svg, encoding="utf-8")
print(f"  Written: {front_out.name}  ({front_out.stat().st_size // 1024} KB)")

back_out.write_text(back_svg, encoding="utf-8")
print(f"  Written: {back_out.name}   ({back_out.stat().st_size // 1024} KB)")

manifest_out.write_text(json.dumps(MANIFEST, indent=2, ensure_ascii=False), encoding="utf-8")
print(f"  Written: {manifest_out.name}  ({manifest_out.stat().st_size // 1024} KB)")

print("\nDone. Files ready in assets/anatomy/")
print("\nFlutter usage:")
print("  Add to pubspec.yaml:  - assets/anatomy/")
print("  Use flutter_svg + SvgPicture.asset('assets/anatomy/front_interactive.svg')")
print("  Highlight muscle by changing fill-opacity via SvgTheme or custom parser.")
