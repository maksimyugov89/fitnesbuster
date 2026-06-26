"""Find ALL mesh objects in buccal/nasolabial zone (Z=1.47-1.57, X=0.01-0.08)
that have muscle-like names or that look like they could be cheek muscles."""
import bpy, json, mathutils

OUTPUT = r"C:\Users\Despa\fitnesbuster\tools\buccal_scan.json"

MUSCLE_NAMES_JSON = r"C:\Users\Despa\fitnesbuster\tools\all_muscle_names.json"
with open(MUSCLE_NAMES_JSON, encoding='utf-8') as f:
    ALL_MUSCLES = set(json.load(f))

# Muscle-related keywords to find anything muscle-like
MUSCLE_KW = ('muscle', 'muscl', 'bucc', 'masseter', 'pterygoid', 'cheek',
             'orbicular', 'depressor', 'levator', 'risor', 'mentalis',
             'platysm', 'zygom', 'nasal', 'labii', 'labial', 'anguli',
             'modiolus', 'facial', 'mimetic')

found = []
all_buccal_zone = []

for obj in bpy.data.objects:
    if obj.type != 'MESH':
        continue
    bb = obj.bound_box
    wc = [obj.matrix_world @ mathutils.Vector(c) for c in bb]
    min_z = min(c.z for c in wc)
    max_z = max(c.z for c in wc)
    abs_x = abs(sum(c.x for c in wc) / 8)
    cz = (min_z + max_z) / 2

    # Buccal/nasolabial zone: Z=1.47-1.57, X=0.01-0.09 (not center, not ear)
    if not (1.47 <= cz <= 1.57):
        continue
    if not (0.01 <= abs_x <= 0.09):
        continue

    name_l = obj.name.lower()
    is_muscle_like = any(k in name_l for k in MUSCLE_KW)
    in_all_muscles = obj.name in ALL_MUSCLES

    entry = {
        'name': obj.name,
        'center_z': round(cz, 3),
        'abs_x': round(abs_x, 3),
        'min_z': round(min_z, 3),
        'max_z': round(max_z, 3),
        'in_all_muscles': in_all_muscles,
        'muscle_like_name': is_muscle_like,
    }
    all_buccal_zone.append(entry)
    if is_muscle_like and not in_all_muscles:
        found.append(entry)

all_buccal_zone.sort(key=lambda x: -x['center_z'])

with open(OUTPUT, 'w', encoding='utf-8') as f:
    json.dump({'not_in_muscles_but_musclelike': found,
               'all_buccal_zone': all_buccal_zone}, f, indent=2, ensure_ascii=False)

print("[scan] Muscle-like objects NOT in all_muscle_names: " + str(len(found)))
for o in found:
    print("  " + o['name'] + " Z=" + str(o['center_z']) + " X=" + str(o['abs_x']))
print("[scan] Total buccal zone objects: " + str(len(all_buccal_zone)))
print("[scan] Done -> " + OUTPUT)
