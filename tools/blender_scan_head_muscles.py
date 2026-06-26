"""Check existence of head/scalp/face muscles and identify missing ones."""
import bpy, json

OUTPUT = r"C:\Users\Despa\fitnesbuster\tools\head_muscles_scan.json"

all_meshes = {o.name for o in bpy.data.objects if o.type == 'MESH'}

CHECK = [
    # Scalp coverage
    'Epicranial aponeurosis',
    'Temporoparietalis muscle.r', 'Temporoparietalis muscle.l',
    'Frontalis.r', 'Frontalis.l',
    'Occipitalis.r', 'Occipitalis.l',
    # Mouth / lips
    'Orbicularis oris',
    'Depressor anguli oris.r', 'Depressor anguli oris.l',
    'Depressor labii superioris.r', 'Depressor labii superioris.l',
    'Levator labii superioris.r', 'Levator labii superioris.l',
    'Levator anguli oris.r', 'Levator anguli oris.l',
    'Zygomaticus major muscle.r', 'Zygomaticus major muscle.l',
    'Zygomaticus minor muscle.r', 'Zygomaticus minor muscle.l',
    'Buccinator muscle.r', 'Buccinator muscle.l',
    'Mentalis muscle.r', 'Mentalis muscle.l',
    'Risorius.r', 'Risorius.l',
    # Eye area
    'Levator palpebrae superioris.r', 'Levator palpebrae superioris.l',
    'Corrugator supercilii.r', 'Corrugator supercilii.l',
    'Procerus',
    'Orbital part of orbicularis oculi.r', 'Orbital part of orbicularis oculi.l',
    'Palpebral part of orbicularis oculi.r', 'Palpebral part of orbicularis oculi.l',
    # Eyebrows (we want to know if they're floating)
    'Eyebrow.l', 'Eyebrow.r',
    'Eyebrow(hair).l', 'Eyebrow(hair).r',
    # Temporal
    'Temporalis muscle.r', 'Temporalis muscle.l',
    'Masseter.r', 'Masseter.l',
    'Superficial part of masseter.r', 'Superficial part of masseter.l',
    'Deep part of masseter.r', 'Deep part of masseter.l',
    # Nose
    'Nasalis muscle.r', 'Nasalis muscle.l',
    'Procerus',
    'Depressor septi nasi.r', 'Depressor septi nasi.l',
]

result = {'exists': [], 'missing': []}
for name in CHECK:
    if name in all_meshes:
        result['exists'].append(name)
    else:
        result['missing'].append(name)

# Also get bounding box info for Eyebrow meshes to check if they're floating
eyebrow_info = {}
for ename in ['Eyebrow.l', 'Eyebrow.r', 'Eyebrow(hair).l', 'Eyebrow(hair).r']:
    obj = bpy.data.objects.get(ename)
    if obj and obj.type == 'MESH':
        bb = obj.bound_box
        world_corners = [obj.matrix_world @ __import__('mathutils').Vector(c) for c in bb]
        min_z = min(c.z for c in world_corners)
        max_z = max(c.z for c in world_corners)
        eyebrow_info[ename] = {'min_z': round(min_z, 3), 'max_z': round(max_z, 3),
                                'center_z': round((min_z + max_z) / 2, 3)}

with open(OUTPUT, 'w', encoding='utf-8') as f:
    json.dump({**result, 'eyebrow_positions': eyebrow_info}, f, indent=2, ensure_ascii=False)

print("[scan] EXISTS: " + str(len(result['exists'])))
print("[scan] MISSING from Blender: " + str(len(result['missing'])))
for n in result['missing']:
    print("  MISSING: " + n)
print("[scan] Eyebrow positions:")
for k, v in eyebrow_info.items():
    print("  " + k + " Z: " + str(v['min_z']) + " → " + str(v['max_z']))
print("[scan] Done → " + OUTPUT)
