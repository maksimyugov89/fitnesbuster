"""Find skull-top coverage objects in Z-Anatomy."""
import bpy, json

OUTPUT = r"C:\Users\Despa\fitnesbuster\tools\skull_coverage_scan.json"

# Keywords for structures that might cover the skull top
COVER_KW = [
    'scalp', 'galea', 'calvaria', 'skull', 'cranium', 'vertex',
    'epicranial', 'temporal fascia', 'aponeurosis', 'skin',
    'integument', 'tegument', 'pericranium', 'temporal line',
]

all_meshes = [(o.name, o.type) for o in bpy.data.objects]
mesh_names = [n for n, t in all_meshes if t == 'MESH']

results = []
for name in sorted(mesh_names):
    nl = name.lower()
    if any(k in nl for k in COVER_KW):
        results.append(name)

with open(OUTPUT, 'w', encoding='utf-8') as f:
    json.dump(results, f, indent=2, ensure_ascii=False)

print("[skull] Found: " + str(len(results)))
for n in results:
    print("  " + n)
