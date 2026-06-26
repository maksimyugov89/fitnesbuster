"""Find ALL mesh objects in face area (Z=1.47-1.60) that are one-sided.
Check ALL_MUSCLES list: .r exists in JSON but .l object NOT in Blender (or vice versa)."""
import bpy, json, mathutils

OUTPUT = r"C:\Users\Despa\fitnesbuster\tools\face_onesided.json"

MUSCLE_NAMES_JSON = r"C:\Users\Despa\fitnesbuster\tools\all_muscle_names.json"
with open(MUSCLE_NAMES_JSON, encoding='utf-8') as f:
    ALL_MUSCLES = set(json.load(f))

all_blender = {o.name for o in bpy.data.objects if o.type == 'MESH'}

# Find face-area objects with bounding box center Z in 1.47-1.60
face_objects = {}
for obj in bpy.data.objects:
    if obj.type != 'MESH':
        continue
    bb = obj.bound_box
    wc = [obj.matrix_world @ mathutils.Vector(c) for c in bb]
    min_z = min(c.z for c in wc)
    max_z = max(c.z for c in wc)
    cz = (min_z + max_z) / 2
    if 1.47 <= cz <= 1.60:
        abs_x = abs(sum(c.x for c in wc) / 8)
        face_objects[obj.name] = {'cz': round(cz, 3), 'abs_x': round(abs_x, 3),
                                   'in_muscles': obj.name in ALL_MUSCLES}

# Case 1: in all_muscles as .r, but .l doesn't exist in Blender
in_muscles_onesided = []
for name in ALL_MUSCLES:
    if name.endswith('.r'):
        base = name[:-2]
        l_name = base + '.l'
        if l_name not in all_blender and name in all_blender:
            obj = bpy.data.objects.get(name)
            if obj and obj.type == 'MESH':
                bb = obj.bound_box
                wc = [obj.matrix_world @ mathutils.Vector(c) for c in bb]
                cz = (min(c.z for c in wc) + max(c.z for c in wc)) / 2
                if 1.47 <= cz <= 1.62:
                    in_muscles_onesided.append({
                        'has': name,
                        'missing': l_name,
                        'cz': round(cz, 3),
                    })
    elif name.endswith('.l'):
        base = name[:-2]
        r_name = base + '.r'
        if r_name not in all_blender and name in all_blender:
            obj = bpy.data.objects.get(name)
            if obj and obj.type == 'MESH':
                bb = obj.bound_box
                wc = [obj.matrix_world @ mathutils.Vector(c) for c in bb]
                cz = (min(c.z for c in wc) + max(c.z for c in wc)) / 2
                if 1.47 <= cz <= 1.62:
                    in_muscles_onesided.append({
                        'has': name,
                        'missing': r_name,
                        'cz': round(cz, 3),
                    })

in_muscles_onesided.sort(key=lambda x: -x['cz'])

with open(OUTPUT, 'w', encoding='utf-8') as f:
    json.dump({'in_muscles_onesided': in_muscles_onesided,
               'count': len(in_muscles_onesided)}, f, indent=2, ensure_ascii=False)

print("[scan] Muscles with .r in JSON but .l missing in Blender (face area): " + str(len(in_muscles_onesided)))
for o in in_muscles_onesided:
    print("  HAS: " + o['has'] + "  MISSING: " + o['missing'] + "  Z=" + str(o['cz']))
print("[scan] Done -> " + OUTPUT)
