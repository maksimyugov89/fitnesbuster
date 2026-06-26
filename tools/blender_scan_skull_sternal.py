"""Scan Z-Anatomy for skull muscles and sternal/xiphoid bones."""
import bpy, json

OUTPUT = r"C:\Users\Despa\fitnesbuster\tools\skull_sternal_scan.json"

SKULL_KW = [
    'temporal', 'masseter', 'buccinator', 'orbicular', 'frontalis',
    'occipital', 'zygomatic', 'pterygoid', 'mentalis', 'risorius',
    'digastric', 'mylohyoid', 'geniohyoid', 'platysma', 'sternohyoid',
    'omohyoid', 'levator', 'corrugator', 'procerus', 'nasalis',
    'depressor', 'auricular', 'epicranius', 'buccal', 'nasal',
    'orbicularis', 'scalene', 'zygom', 'face', 'facial', 'lip',
    'mouth', 'chin', 'jaw', 'cheek', 'nose', 'eye', 'eyelid',
    'forehead', 'scalp', 'skull', 'cranial', 'cranium',
]

STERNAL_KW = [
    'xiphoid', 'manubrium', 'sternum', 'sternal', 'jugular notch',
    'clavicular notch', 'costal notch',
]

all_meshes = {o.name for o in bpy.data.objects if o.type == 'MESH'}

skull_found = []
sternal_found = []

for name in sorted(all_meshes):
    nl = name.lower()
    if any(k in nl for k in SKULL_KW):
        skull_found.append(name)
    if any(k in nl for k in STERNAL_KW):
        sternal_found.append(name)

result = {
    'skull_muscles': skull_found,
    'sternal_bones': sternal_found,
}

with open(OUTPUT, 'w', encoding='utf-8') as f:
    json.dump(result, f, indent=2, ensure_ascii=False)

print("[scan] Skull-related objects: " + str(len(skull_found)))
for n in skull_found:
    print("  " + n)
print()
print("[scan] Sternal/xiphoid objects: " + str(len(sternal_found)))
for n in sternal_found:
    print("  " + n)
print("[scan] Done → " + OUTPUT)
