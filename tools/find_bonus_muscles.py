"""Get all muscles from Bonus collection to find body-filling options."""
import json

with open('tools/blender_scan.json', encoding='utf-8') as f:
    data = json.load(f)

def get_coll_meshes(node, target_name):
    if not isinstance(node, dict):
        return []
    if node.get('name','') == target_name:
        return node.get('meshes', [])
    for child in node.get('children', []):
        result = get_coll_meshes(child, target_name)
        if result is not None and len(result) > 0:
            return result
    return []

# Get all meshes from Bonus collection > Muscular system'
bonus_muscles = []
for c in data['collections']:
    if c.get('name','') == 'Bonus collection':
        for child in c.get('children',[]):
            if child.get('name','') == "Muscular system'":
                bonus_muscles = child.get('meshes',[])
                # Also get from subcollections
                def collect_all(node):
                    result = list(node.get('meshes',[]))
                    for ch in node.get('children',[]):
                        result.extend(collect_all(ch))
                    return result
                bonus_muscles = collect_all(child)

print(f'Total bonus muscles: {len(bonus_muscles)}')
print()

# Categorize by common patterns
face = [n for n in bonus_muscles if any(k in n for k in ['Frontalis','Occipitalis','Orbicularis','Zygomaticus','Corrugator','Depressor','Levator','Nasalis','Procerus','Risorius','Mentalis','Bucinator','Bucinator','Masseter','Temporalis','Platysma','Digastric','sternocleid','Sternocleid','mylohyoid','Mylohyoid','Pterygoid','Buccin'])]
neck = [n for n in bonus_muscles if any(k.lower() in n.lower() for k in ['splenius','scalene','longus colli','longus capitis','scalenus','omohyoid','sternohyoid','sternothyroid','levator scapulae'])]
forearm_ext = [n for n in bonus_muscles if any(k.lower() in n.lower() for k in ['extensor carpi','extensor digit','pronator','supinator','brachioradialis','anconeus','abductor pollicis'])]
leg_ext = [n for n in bonus_muscles if any(k.lower() in n.lower() for k in ['peroneus','fibular','tibialis posterior','popliteus','plantaris','flexor hallucis','flexor digitorum longus','extensor hallucis','extensor digitorum longus'])]
shoulder = [n for n in bonus_muscles if any(k.lower() in n.lower() for k in ['coracobrachialis','teres minor','supraspinatus','infraspinatus','subscapularis','rhomboid','levator scapulae'])]
deep_chest = [n for n in bonus_muscles if any(k.lower() in n.lower() for k in ['intercostal','subcostal','serratus posterior','pectoralis minor'])]

print('FACE muscles:', len(face))
for n in face[:30]: print(' ', n)
print()
print('NECK muscles:', len(neck))
for n in neck[:20]: print(' ', n)
print()
print('FOREARM extensors:', len(forearm_ext))
for n in forearm_ext[:20]: print(' ', n)
print()
print('LEG extras:', len(leg_ext))
for n in leg_ext[:20]: print(' ', n)
print()
print('SHOULDER extras:', len(shoulder))
for n in shoulder[:20]: print(' ', n)
print()
print('DEEP CHEST:', len(deep_chest))
for n in deep_chest[:20]: print(' ', n)
print()

# All remaining bonus muscles not in categories above
known = set(face+neck+forearm_ext+leg_ext+shoulder+deep_chest)
other = [n for n in bonus_muscles if n not in known]
print(f'Other ({len(other)}):')
for n in other[:50]: print(' ', n)
