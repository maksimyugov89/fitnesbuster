"""Check which thumb bone objects actually exist in Z-Anatomy."""
import bpy, json

OUTPUT = r"C:\Users\Despa\fitnesbuster\tools\thumb_scan.json"

CHECK = [
    '1st metacarpal bone.r', '1st metacarpal bone.l',
    'Proximal phalanx of 1st finger.r', 'Proximal phalanx of 1st finger.l',
    'Distal phalanx of 1st finger.r', 'Distal phalanx of 1st finger.l',
    'Proximal phalanx of hand-1st finger.r', 'Proximal phalanx of hand-1st finger.l',
    'Distal phalanx of hand-1st finger.r', 'Distal phalanx of hand-1st finger.l',
    'Middle phalanx of 1st finger.r', 'Middle phalanx of 1st finger.l',
]

all_mesh = {o.name for o in bpy.data.objects if o.type == 'MESH'}

result = {}
for name in CHECK:
    result[name] = name in all_mesh
    print(("[YES]" if result[name] else "[NO ]") + " " + name)

# Also search for any object with 'thumb' or '1st finger' in name
similar = [n for n in all_mesh if 'thumb' in n.lower() or ('1st' in n.lower() and 'finger' in n.lower() and 'foot' not in n.lower())]
similar.sort()
print("\nAll objects with 'thumb' or '1st finger' (not foot):")
for s in similar:
    print("  " + s)

with open(OUTPUT, 'w', encoding='utf-8') as f:
    json.dump({'check': result, 'similar': similar}, f, indent=2, ensure_ascii=False)
print("[scan] Done -> " + OUTPUT)
