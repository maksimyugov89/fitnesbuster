"""Find muscles to fill body gaps: head/face, forearm extensors, leg/foot, etc."""
import json

with open('tools/blender_scan.json', encoding='utf-8') as f:
    data = json.load(f)

all_names = data['all_mesh_names']

def find_coll_by_name(node, targets, depth=0):
    if not isinstance(node, dict):
        return
    name = node.get('name', '')
    if any(t.lower() in name.lower() for t in targets):
        meshes = node.get('meshes', [])
        print('  ' * depth + '[COLL] ' + name + ' meshes=' + str(len(meshes)))
        for m in meshes:
            print('  ' * (depth+1) + m)
    for child in node.get('children', []):
        find_coll_by_name(child, targets, depth+1)

print('=== GENERAL / BONUS collections (may contain body mesh) ===')
for c in data['collections']:
    if c.get('name','') in ('8:General', 'Bonus collection', '9:Special effects'):
        print('[TOP] ' + c.get('name',''))
        for child in c.get('children',[]):
            meshes = child.get('meshes',[])
            print('  ' + child.get('name','') + ' meshes=' + str(len(meshes)))
            for m in meshes[:30]:
                print('    ' + m)
        for m in c.get('meshes',[]):
            print('  ' + m)

print()
print('=== Face / Head muscles ===')
for c in data['collections']:
    find_coll_by_name(c, ['head', 'face', 'facial', 'masset', 'temporalis', 'scalp', 'cranial', 'scalene', 'splenius', 'buccin'])

print()
print('=== Forearm extensors ===')
for c in data['collections']:
    find_coll_by_name(c, ['posterior compartment of forearm', 'extensor carpi', 'extensor digit', 'anconeus'])

print()
print('=== Leg / foot ===')
for c in data['collections']:
    find_coll_by_name(c, ['peroneal', 'fibular', 'tibialis posterior', 'plantar', 'popliteus', 'foot', 'toes', 'ankle'])

print()
print('=== Intercostals / chest depth ===')
for c in data['collections']:
    find_coll_by_name(c, ['intercostal', 'serratus posterior', 'subcostal', 'diaphragm'])

print()
print('=== Skin-eraser and special objects ===')
for n in all_names:
    if 'skin' in n.lower() or 'eraser' in n.lower() or 'ghost' in n.lower() or 'silhouette' in n.lower() or 'shell' in n.lower():
        print(n)
