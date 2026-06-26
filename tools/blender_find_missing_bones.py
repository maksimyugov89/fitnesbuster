"""
Scan Z-Anatomy for missing bones: spine, left scapula, left radius/ulna, ribs.
Dumps exact names to JSON so we know what to add.
"""
import bpy
import json

OUTPUT = r"C:\Users\Despa\fitnesbuster\tools\missing_bone_scan.json"

SEARCH_GROUPS = {
    'vertebra':  'vertebra',
    'scapula':   'scapula',
    'clavicle':  'clavicle',
    'radius':    'radius',
    'ulna':      'ulna',
    'rib':       'rib ',
    'sternum':   'sternum',
    'maxilla':   'maxilla',
    'hyoid':     'hyoid',
    'metacarpal_l': '1st metacarpal',
}

results = {}
for group, keyword in SEARCH_GROUPS.items():
    found = []
    for obj in bpy.data.objects:
        if obj.type == 'MESH' and keyword.lower() in obj.name.lower():
            found.append(obj.name)
    found.sort()
    results[group] = found

with open(OUTPUT, 'w', encoding='utf-8') as f:
    json.dump(results, f, indent=2, ensure_ascii=False)

for group, names in results.items():
    print("[scan] " + group + ": " + str(len(names)) + " objects")
    for n in names[:10]:
        print("   " + n)
    if len(names) > 10:
        print("   ... (" + str(len(names)-10) + " more)")

print("[scan] Done → " + OUTPUT)
