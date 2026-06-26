"""
Blender background script: scan ALL mesh objects in Z-Anatomy and save
their names grouped by likely type (bone, ligament, other) to JSON.
"""
import bpy
import json

OUTPUT = r"C:\Users\Despa\fitnesbuster\tools\all_object_names.json"

BONE_KEYWORDS = [
    'femur', 'tibia', 'fibula', 'patella',
    'humerus', 'radius', 'ulna', 'clavicle', 'scapula', 'acromion',
    'phalanx', 'phalanges', 'metacarpal', 'metatarsal',
    'carpal', 'tarsal', 'calcaneus', 'talus', 'navicular', 'cuboid', 'cuneiform',
    'vertebra', 'lumbar', 'thoracic', 'cervical', 'sacrum', 'coccyx',
    'sternum', 'rib ', 'ribs', 'costal',
    'skull', 'cranium', 'mandible', 'maxilla', 'occipital', 'temporal bone',
    'parietal', 'frontal bone', 'sphenoid', 'ethmoid', 'vomer',
    'pelvis', 'ilium', 'ischium', 'pubis', 'acetabulum',
    'os ', ' bone', 'bone.', 'epicondyle', 'condyle', 'trochanter',
    'malleolus', 'styloid', 'olecranon', 'coronoid',
]

results = {'bones': [], 'other': []}

for obj in bpy.data.objects:
    if obj.type != 'MESH':
        continue
    name_lower = obj.name.lower()
    is_bone = any(kw in name_lower for kw in BONE_KEYWORDS)
    if is_bone:
        results['bones'].append(obj.name)
    else:
        results['other'].append(obj.name)

results['bones'].sort()
results['other'].sort()

with open(OUTPUT, 'w', encoding='utf-8') as f:
    json.dump(results, f, indent=2, ensure_ascii=False)

print("[scan] Bones found:  " + str(len(results['bones'])))
print("[scan] Other meshes: " + str(len(results['other'])))
print("[scan] Written → " + OUTPUT)
