"""Check which bones exist on left side vs only right."""
import bpy, json

OUTPUT = r"C:\Users\Despa\fitnesbuster\tools\left_bone_check.json"

CHECK_BASES = [
    'Scapula', 'Clavicle', 'Radius', 'Ulna', 'Humerus',
    'Scaphoid bone', 'Lunate bone', 'Triquetrum bone',
    'Pisiform bone', 'Trapezium bone', 'Trapezoid bone',
    'Capitate bone', 'Hamate bone',
    '1st metacarpal bone', '2d metacarpal bone', '3d metacarpal bone',
    '4th metacarpal bone', '5th metacarpal bone',
    'Proximal phalanx of 2d finger', 'Proximal phalanx of 3rd finger',
    'Proximal phalanx of 4th finger', 'Proximal phalanx of 5th finger',
    'Middle phalanx of 2d finger', 'Middle phalanx of 3rd finger',
    'Middle phalanx of 4th finger', 'Middle phalanx of 5th finger',
    'Distal phalanx of 2d finger', 'Distal phalanx of 3d finger',
    'Distal phalanx of 4th finger', 'Distal phalanx of 5th finger',
]

all_names = {o.name for o in bpy.data.objects if o.type == 'MESH'}
results = {}
for base in CHECK_BASES:
    r_exists = any(n.startswith(base + '.r') or n == base + '.r' for n in all_names)
    l_exists = any(n.startswith(base + '.l') or n == base + '.l' for n in all_names)
    results[base] = {'r': r_exists, 'l': l_exists, 'needs_mirror': r_exists and not l_exists}
    print("[check] " + base + "  .r=" + str(r_exists) + "  .l=" + str(l_exists) + ("  → NEEDS MIRROR" if (r_exists and not l_exists) else ""))

with open(OUTPUT, 'w') as f:
    json.dump(results, f, indent=2)
print("[check] Done → " + OUTPUT)
