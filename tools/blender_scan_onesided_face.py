"""Find ALL face/neck objects with .r but no .l counterpart."""
import bpy, json

OUTPUT = r"C:\Users\Despa\fitnesbuster\tools\onesided_face_scan.json"

all_meshes = {o.name for o in bpy.data.objects if o.type == 'MESH'}

FACE_KW = [
    'nasal', 'nasolabi', 'labii', 'labial', 'labium', 'lip', 'philtrum',
    'zygomati', 'zygomatic', 'menti', 'mentol', 'corrugat', 'procerus',
    'frontal', 'masseter', 'temporal', 'buccin', 'risor', 'platysm',
    'mentalis', 'levator', 'depressor', 'orbicular', 'occipital',
    'chin', 'cheek', 'naso', 'nostril', 'mimetic', 'digastric',
    'pterygoid', 'scalene', 'sternocleid', 'omohyoid', 'mylohyoid',
    'geniohyoid', 'hyoglossus', 'genioglossu', 'stylohyoid',
    'thyrohyoid', 'sternothyroid', 'sternohyoid', 'palatoglossus',
    'facial', 'expression', 'auricular', 'nasalis', 'depressor septi',
    'levator naso', 'levator labii', 'levator anguli',
]

one_sided = []
for name in sorted(all_meshes):
    if not (name.endswith('.r') or
            name.endswith('.r.001') or name.endswith('.r.002')):
        continue
    nl = name.lower()
    if not any(k in nl for k in FACE_KW):
        continue
    # Find .l equivalent
    if name.endswith('.r'):
        l_name = name[:-2] + '.l'
    elif name.endswith('.r.001'):
        l_name = name.replace('.r.001', '.l.001')
        if l_name not in all_meshes:
            l_name = name[:-6] + '.l'
    elif name.endswith('.r.002'):
        l_name = name.replace('.r.002', '.l.002')
        if l_name not in all_meshes:
            l_name = name[:-6] + '.l'
    else:
        continue

    if l_name not in all_meshes:
        one_sided.append({'r': name, 'l_missing': l_name})

with open(OUTPUT, 'w', encoding='utf-8') as f:
    json.dump({'one_sided': one_sided, 'count': len(one_sided)}, f, indent=2, ensure_ascii=False)

print("[scan] One-sided face objects: " + str(len(one_sided)))
for item in one_sided:
    print("  " + item['r'] + " → no " + item['l_missing'])
print("[scan] Done → " + OUTPUT)
