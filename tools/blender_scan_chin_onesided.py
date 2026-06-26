"""Find one-sided objects in chin/lower-jaw area Z=1.44-1.54."""
import bpy, json, mathutils

OUTPUT = r"C:\Users\Despa\fitnesbuster\tools\chin_onesided.json"
MUSCLE_NAMES_JSON = r"C:\Users\Despa\fitnesbuster\tools\all_muscle_names.json"
with open(MUSCLE_NAMES_JSON, encoding='utf-8') as f:
    ALL_MUSCLES = set(json.load(f))

all_blender = {o.name for o in bpy.data.objects if o.type == 'MESH'}

zone = {}
for obj in bpy.data.objects:
    if obj.type != 'MESH': continue
    bb = obj.bound_box
    wc = [obj.matrix_world @ mathutils.Vector(c) for c in bb]
    cz = (min(c.z for c in wc) + max(c.z for c in wc)) / 2
    if 1.44 <= cz <= 1.54:
        abs_x = abs(sum(c.x for c in wc) / 8)
        zone[obj.name] = {'cz': round(cz,3), 'abs_x': round(abs_x,3),
                          'in_muscles': obj.name in ALL_MUSCLES}

# Find asymmetric (has .r but no .l or vice versa)
asym = []
for name in sorted(zone):
    if name.endswith('.r'):
        l = name[:-2] + '.l'
        if l not in all_blender:
            asym.append({'has': name, 'missing': l, **zone[name]})
    elif name.endswith('.l'):
        r = name[:-2] + '.r'
        if r not in all_blender:
            asym.append({'has': name, 'missing': r, **zone[name]})

asym.sort(key=lambda x: -x['cz'])
with open(OUTPUT,'w',encoding='utf-8') as f:
    json.dump({'asymmetric': asym, 'total': len(zone)}, f, indent=2, ensure_ascii=False)

print("[scan] Asymmetric in chin zone: " + str(len(asym)))
for o in asym:
    exp = "(in muscles)" if o['in_muscles'] else "(NOT exported)"
    print("  HAS: " + o['has'] + " | MISSING: " + o['missing'] + " " + exp + " Z=" + str(o['cz']) + " X=" + str(o['abs_x']))
print("[scan] Done")
