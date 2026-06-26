"""
Scan all mesh objects at skull top (world Z > 1.45) and jaw area (Z 1.3-1.6).
For each: show name, Z range, whether exported in current setup.
Also look for asymmetric objects (has .r but no .l or vice versa).
"""
import bpy
import json
import mathutils

OUTPUT = r"C:\Users\Despa\fitnesbuster\tools\skull_top_scan.json"

# Current SKULL_SURFACE_NAMES (copy from export script)
SKULL_SURFACE = {
    'Frontal bone', 'Left parietal bone', 'Parietal bone.r', 'Occipital bone',
    'Nasal cartilages.l', 'Nasal cartilages.r',
    'Nasal cartilages.001', 'Nasal cartilages.l.001', 'Nasal cartilages.r.001',
    'Vertex.l', 'Vertex.r',
    'Sclera.r.001',
    'Labial commissure.l', 'Labial commissure.r',
    'Philtrum.l', 'Philtrum.r',
    'Tubercle of upper lip.l', 'Tubercle of upper lip.r',
}

MUSCLE_NAMES_JSON = r"C:\Users\Despa\fitnesbuster\tools\all_muscle_names.json"
with open(MUSCLE_NAMES_JSON, encoding='utf-8') as f:
    ALL_MUSCLES = set(json.load(f))

skull_top = []   # Z_center > 1.45
jaw_area = []    # Z_center 1.30-1.60 (around mouth/jaw)

for obj in bpy.data.objects:
    if obj.type != 'MESH':
        continue
    bb = obj.bound_box
    world_corners = [obj.matrix_world @ mathutils.Vector(c) for c in bb]
    min_z = min(c.z for c in world_corners)
    max_z = max(c.z for c in world_corners)
    center_z = (min_z + max_z) / 2

    exported_as = None
    if obj.name in ALL_MUSCLES:
        exported_as = 'body_fill (muscle)'
    elif obj.name in SKULL_SURFACE:
        exported_as = 'body_fill (skull_surface)'
    # Could also be in BONE_FILL but we don't check all of that here

    if center_z > 1.45:
        skull_top.append({
            'name': obj.name,
            'center_z': round(center_z, 3),
            'min_z': round(min_z, 3),
            'max_z': round(max_z, 3),
            'exported_as': exported_as,
        })

# Sort by center_z descending
skull_top.sort(key=lambda x: -x['center_z'])

# Find asymmetric pairs at skull top
all_skull_top_names = {o['name'] for o in skull_top}
asymmetric = []
for name in all_skull_top_names:
    if name.endswith('.r') or name.endswith('.R'):
        base = name[:-2]
        l_name = base + '.l'
        if l_name not in all_skull_top_names:
            asymmetric.append({'only': name, 'missing_mirror': l_name})
    elif name.endswith('.l') or name.endswith('.L'):
        base = name[:-2]
        r_name = base + '.r'
        if r_name not in all_skull_top_names:
            asymmetric.append({'only': name, 'missing_mirror': r_name})

result = {
    'skull_top_objects': skull_top,
    'skull_top_count': len(skull_top),
    'asymmetric_at_skull_top': asymmetric,
}

with open(OUTPUT, 'w', encoding='utf-8') as f:
    json.dump(result, f, indent=2, ensure_ascii=False)

print("[scan] Skull top objects (Z > 1.45): " + str(len(skull_top)))
print("[scan] Asymmetric pairs: " + str(len(asymmetric)))
for o in skull_top:
    status = o['exported_as'] or '** NOT EXPORTED **'
    print("  Z=" + str(o['center_z']) + " | " + o['name'] + " | " + status)
print("[scan] Asymmetric:")
for a in asymmetric:
    print("  ONLY: " + a['only'] + "  MISSING: " + a['missing_mirror'])
print("[scan] Done → " + OUTPUT)
