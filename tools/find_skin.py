import json

with open('tools/blender_scan.json', encoding='utf-8') as f:
    data = json.load(f)

all_names = data['all_mesh_names']

def find_coll(node, keywords, depth=0):
    if not isinstance(node, dict):
        return
    name = node.get('name', '')
    if any(k.lower() in name.lower() for k in keywords):
        meshes = node.get('meshes', [])
        print('  ' * depth + '[COLL] ' + name + ' meshes=' + str(len(meshes)))
        for m in meshes[:15]:
            print('  ' * (depth+1) + m)
    for child in node.get('children', []):
        find_coll(child, keywords, depth+1)

kw = ['integument', 'skin', 'dermis', 'subcutan', 'superfic', 'body surface', 'Integument', 'Skin', 'surface layer', 'nude']
print('=== Collections ===')
for c in data['collections']:
    find_coll(c, kw)

print()
print('=== Mesh names containing body/skin ===')
body_kw = ['nude', 'torso', 'mannequin', 'human body', 'body surface', 'skin']
for n in all_names:
    if any(k.lower() in n.lower() for k in body_kw):
        print(n)

print()
print('=== All top-level collections ===')
for c in data['collections']:
    print(c.get('name','') + ' (children=' + str(len(c.get('children',[]))) + ', meshes=' + str(len(c.get('meshes',[]))) + ')')
