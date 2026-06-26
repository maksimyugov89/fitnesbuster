"""Scan for ribs and other potentially missing bones."""
import bpy, json

OUTPUT = r"C:\Users\Despa\fitnesbuster\tools\rib_scan.json"

keywords = ['costa', 'costal', 'rib', 'intercostal', 'thoracic', 'lumbar', 'cervical', 'vertebr']
results = {}
for kw in keywords:
    found = sorted([o.name for o in bpy.data.objects if o.type == 'MESH' and kw in o.name.lower()])
    results[kw] = found
    print("[scan] '" + kw + "': " + str(len(found)) + " objects")
    for n in found[:8]:
        print("   " + n)

with open(OUTPUT, 'w', encoding='utf-8') as f:
    json.dump(results, f, indent=2, ensure_ascii=False)
print("[scan] Done → " + OUTPUT)
