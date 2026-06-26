import bpy

TARGETS = {
    'neck': ['Sternocleidomastoid muscle.r', 'Sternocleidomastoid muscle.l'],
    'biceps_right': ['Long head of biceps brachii.r', 'Short head of biceps brachii.r'],
    'gluteus_maximus_right': ['Gluteus maximus muscle.r'],
}
NEUTRAL = (0.72, 0.45, 0.38, 1.0)

for mid, names in TARGETS.items():
    mat = bpy.data.materials.new(name=mid)
    mat.use_nodes = True
    for name in names:
        obj = bpy.data.objects.get(name)
        if not obj:
            print(f"NOT FOUND: {name}")
            continue
        print(f"BEFORE [{name}] users={obj.data.users} mats={[m.name if m else 'None' for m in obj.data.materials]}")
        if obj.data.users > 1:
            obj.data = obj.data.copy()
        obj.data.materials.clear()
        obj.data.materials.append(mat)
        print(f"AFTER  [{name}] users={obj.data.users} mats={[m.name if m else 'None' for m in obj.data.materials]}")
        # Also check object-level slots
        print(f"       obj slots: {[s.material.name if s.material else 'None' for s in obj.material_slots]}")
