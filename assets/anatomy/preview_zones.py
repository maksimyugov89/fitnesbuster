"""
Visual preview: render muscle zones as colored overlays over the body images.
Useful for verifying zone accuracy before shipping to Flutter.
"""
from PIL import Image, ImageDraw, ImageFont
import json
import re
import sys

BASE = r"c:\Users\Despa\fitnesbuster\assets\anatomy"

# Scale factor: SVG zones are defined at 1024x1536, preview PNGs are 512x768
SCALE = 512 / 1024

# Color palette per zone (for visual distinction)
COLORS = [
    (255, 80,  80,  120),  # red
    (80,  160, 255, 120),  # blue
    (80,  220, 80,  120),  # green
    (255, 200, 0,   120),  # yellow
    (220, 80,  220, 120),  # purple
    (0,   200, 200, 120),  # cyan
    (255, 140, 0,   120),  # orange
    (180, 255, 100, 120),  # lime
]

def load_zones_from_svg(svg_path: str) -> dict:
    """Extract muscle id → polygon coords from interactive SVG."""
    svg = open(svg_path, 'r', encoding='utf-8').read()
    zones = {}
    # Find each <g id="..."> and its path d="..."
    for gm in re.finditer(r'<g id="([^"]+)"[^>]*>.*?<path d="([^"]+)"', svg, re.DOTALL):
        muscle_id = gm.group(1)
        path_d = gm.group(2)
        # Parse M x,y L x,y ... Z
        pts = [(float(m.group(1)), float(m.group(2)))
               for m in re.finditer(r'[ML]\s*([\d.]+),([\d.]+)', path_d)]
        if pts:
            zones[muscle_id] = pts
    return zones


def render_preview(svg_path: str, body_png: str, out_path: str):
    img = Image.open(body_png).convert("RGBA")
    W, H = img.size

    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    zones = load_zones_from_svg(svg_path)

    for i, (muscle_id, pts) in enumerate(zones.items()):
        # Scale from 1024x1536 → 512x768
        scaled = [(x * SCALE, y * SCALE) for x, y in pts]
        color = COLORS[i % len(COLORS)]

        # Filled polygon
        draw.polygon(scaled, fill=color)

        # Outline
        outline_color = (color[0], color[1], color[2], 220)
        draw.line(scaled + [scaled[0]], fill=outline_color, width=2)

        # Label at centroid
        cx = sum(p[0] for p in scaled) / len(scaled)
        cy = sum(p[1] for p in scaled) / len(scaled)
        label = muscle_id.replace("_right", "_R").replace("_left", "_L")
        label = label.replace("anterior_deltoid", "ant_delt")
        label = label.replace("lateral_deltoid", "lat_delt")
        label = label.replace("pectoralis_upper", "pec_up")
        label = label.replace("pectoralis_lower", "pec_lo")
        label = label.replace("forearm_flexors", "forearm")
        label = label.replace("external_oblique", "oblique")
        label = label.replace("hip_flexors", "hip_fl")
        label = label.replace("tibialis_anterior", "tib_ant")
        label = label.replace("posterior_deltoid", "post_delt")
        label = label.replace("middle_trapezius", "mid_trap")
        label = label.replace("lower_trapezius", "low_trap")
        label = label.replace("gluteus_maximus", "glut_max")
        label = label.replace("gluteus_medius", "glut_med")
        label = label.replace("gastrocnemius", "gastro")
        label = label.replace("erector_spinae", "erector")
        label = label.replace("rectus_abdominis", "rectus")
        label = label.replace("upper_trapezius", "up_trap")
        label = label.replace("adductors", "adduct")
        label = label.replace("quadriceps", "quads")
        label = label.replace("hamstrings", "hams")
        label = label.replace("latissimus", "lats")
        label = label.replace("teres_major", "teres")
        label = label.replace("triceps", "tri")
        label = label.replace("biceps", "bi")
        label = label.replace("soleus", "sol")
        label = label.replace("_", " ")

        try:
            draw.text((cx - 2, cy - 4), label, fill=(0, 0, 0, 220), font=None)
        except Exception:
            pass

    composite = Image.alpha_composite(img, overlay)
    composite.save(out_path, "PNG")
    print(f"  Saved: {out_path}")


print("Rendering front zone preview...")
render_preview(
    f"{BASE}/front_interactive.svg",
    f"{BASE}/front_body.png",
    f"{BASE}/front_zones_preview.png"
)

print("Rendering back zone preview...")
render_preview(
    f"{BASE}/back_interactive.svg",
    f"{BASE}/back_body.png",
    f"{BASE}/back_zones_preview.png"
)
print("Done.")
