"""Scan objects in mouth/nasolabial area (Z center 1.44-1.57, not exported)."""
import bpy, json, mathutils

OUTPUT = r"C:\Users\Despa\fitnesbuster\tools\mouth_area_scan.json"

MUSCLE_NAMES_JSON = r"C:\Users\Despa\fitnesbuster\tools\all_muscle_names.json"
with open(MUSCLE_NAMES_JSON, encoding='utf-8') as f:
    ALL_MUSCLES = set(json.load(f))

SKULL_SURFACE = {
    'Frontal bone', 'Left parietal bone', 'Parietal bone.r', 'Occipital bone',
    'Parietal region.l', 'Parietal region.r', 'Frontal region.l', 'Frontal region.r',
    'Occipital region.l', 'Occipital region.r', 'Mandible', 'Maxilla.l', 'Maxilla.r',
}

NOT_EXPORTED = []
EXPORTED = []

for obj in bpy.data.objects:
    if obj.type != 'MESH':
        continue
    bb = obj.bound_box
    wc = [obj.matrix_world @ mathutils.Vector(c) for c in bb]
    min_z = min(c.z for c in wc)
    max_z = max(c.z for c in wc)
    cx = sum(c.x for c in wc) / 8
    cy = sum(c.y for c in wc) / 8
    cz = (min_z + max_z) / 2

    if not (1.44 <= cz <= 1.57):
        continue

    exported = obj.name in ALL_MUSCLES or obj.name in SKULL_SURFACE
    entry = {
        'name': obj.name,
        'center_z': round(cz, 3),
        'center_x': round(cx, 3),
        'min_z': round(min_z, 3),
        'max_z': round(max_z, 3),
    }
    if exported:
        EXPORTED.append(entry)
    else:
        NOT_EXPORTED.append(entry)

NOT_EXPORTED.sort(key=lambda x: -x['center_z'])
EXPORTED.sort(key=lambda x: -x['center_z'])

with open(OUTPUT, 'w', encoding='utf-8') as f:
    json.dump({'not_exported': NOT_EXPORTED, 'exported': EXPORTED}, f, indent=2, ensure_ascii=False)

print("[scan] NOT exported in mouth area: " + str(len(NOT_EXPORTED)))
for o in NOT_EXPORTED[:60]:
    print("  Z=" + str(o['center_z']) + " X=" + str(o['center_x']) + " | " + o['name'])
print("[scan] Done -> " + OUTPUT)
