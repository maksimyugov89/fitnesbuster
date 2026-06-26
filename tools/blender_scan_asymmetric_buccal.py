"""Find one-sided objects in buccal/nasolabial zone (Z=1.47-1.58, X=0.008-0.09)."""
import bpy, json, mathutils

OUTPUT = r"C:\Users\Despa\fitnesbuster\tools\asymmetric_buccal.json"

MUSCLE_NAMES_JSON = r"C:\Users\Despa\fitnesbuster\tools\all_muscle_names.json"
with open(MUSCLE_NAMES_JSON, encoding='utf-8') as f:
    ALL_MUSCLES = set(json.load(f))

zone_names = set()
zone_objects = {}

for obj in bpy.data.objects:
    if obj.type != 'MESH':
        continue
    bb = obj.bound_box
    wc = [obj.matrix_world @ mathutils.Vector(c) for c in bb]
    min_z = min(c.z for c in wc)
    max_z = max(c.z for c in wc)
    abs_x = abs(sum(c.x for c in wc) / 8)
    cz = (min_z + max_z) / 2

    if not (1.47 <= cz <= 1.58):
        continue
    if not (0.005 <= abs_x <= 0.09):
        continue

    zone_names.add(obj.name)
    zone_objects[obj.name] = {
        'center_z': round(cz, 3),
        'abs_x': round(abs_x, 3),
        'in_all_muscles': obj.name in ALL_MUSCLES,
    }

# Find asymmetric: has .l but no .r or vice versa
asymmetric = []
for name in sorted(zone_names):
    if name.endswith('.l'):
        base = name[:-2]
        r_name = base + '.r'
        if r_name not in zone_names:
            asymmetric.append({'has': name, 'missing': r_name, **zone_objects[name]})
    elif name.endswith('.r'):
        base = name[:-2]
        l_name = base + '.l'
        if l_name not in zone_names:
            asymmetric.append({'has': name, 'missing': l_name, **zone_objects[name]})

with open(OUTPUT, 'w', encoding='utf-8') as f:
    json.dump({'asymmetric': asymmetric, 'total_zone': len(zone_names)}, f, indent=2, ensure_ascii=False)

print("[scan] Asymmetric objects in buccal zone: " + str(len(asymmetric)))
for o in asymmetric:
    exp = "(in muscles)" if o['in_all_muscles'] else "(NOT exported)"
    print("  HAS: " + o['has'] + " | MISSING: " + o['missing'] + " | " + exp + " Z=" + str(o['center_z']))
print("[scan] Done -> " + OUTPUT)
