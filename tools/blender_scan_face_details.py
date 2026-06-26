"""Scan Z-Anatomy for eyes, teeth, lips, and one-sided face muscles."""
import bpy, json

OUTPUT = r"C:\Users\Despa\fitnesbuster\tools\face_details_scan.json"

all_meshes = {o.name for o in bpy.data.objects if o.type == 'MESH'}

EYE_KW  = ['eye', 'globe', 'sclera', 'cornea', 'iris', 'lens', 'pupil',
            'vitreous', 'retina', 'ocular', 'lacrimal', 'conjunctiva',
            'palpebrae', 'orbicularis oculi', 'orbital']
TOOTH_KW = ['tooth', 'teeth', 'incisor', 'molar', 'premolar', 'canine',
             'wisdom', 'dental', 'dentis', 'enamel', 'dentin',
             'upper jaw', 'lower jaw', 'gingiva']
LIP_KW  = ['lip', 'labii', 'labial', 'labium', 'orbicularis oris',
           'philtrum', 'vermilion', 'cupids', 'tubercle of upper']

eyes, teeth, lips = [], [], []
for name in sorted(all_meshes):
    nl = name.lower()
    if any(k in nl for k in EYE_KW):
        eyes.append(name)
    if any(k in nl for k in TOOTH_KW):
        teeth.append(name)
    if any(k in nl for k in LIP_KW):
        lips.append(name)

# Find one-sided face muscles: has .r but no corresponding .l
FACE_MUSCLES = [
    'Frontalis', 'Occipitalis', 'Temporalis muscle',
    'Superficial part of masseter', 'Deep part of masseter',
    'Corrugator supercilii', 'Procerus', 'Nasalis muscle',
    'Depressor septi nasi', 'Depressor anguli oris', 'Depressor labii superioris',
    'Levator labii superioris', 'Levator nasolabialis', 'Levator anguli oris',
    'Zygomaticus major muscle', 'Zygomaticus minor muscle',
    'Mentalis muscle', 'Risorius', 'Orbicularis oris',
    'Orbital part of orbicularis oculi', 'Palpebral part of orbicularis oculi',
    'Levator palpebrae superioris', 'Platysma',
    'Anterior belly of digastric muscle', 'Posterior belly of digastric muscle',
    'Mylohyoid muscle', 'Geniohyoid muscle', 'Sternohyoid muscle', 'Omohyoid muscle',
    'Medial pterygoid muscle', 'Inferior head of lateral pterygoid muscle',
    'Superior head of lateral pterygoid muscle',
    'Scalene anterior muscle',
]

one_sided = {}
for base in FACE_MUSCLES:
    r = base + '.r'
    l = base + '.l'
    r_exists = r in all_meshes
    l_exists = l in all_meshes
    if r_exists and not l_exists:
        one_sided[base] = {'has': r, 'missing': l}
    elif l_exists and not r_exists:
        one_sided[base] = {'has': l, 'missing': r}

result = {
    'eyes': eyes,
    'teeth': teeth,
    'lips': lips,
    'one_sided_face_muscles': one_sided,
}

with open(OUTPUT, 'w', encoding='utf-8') as f:
    json.dump(result, f, indent=2, ensure_ascii=False)

print("[scan] Eyes: " + str(len(eyes)))
for n in eyes: print("  " + n)
print("[scan] Teeth: " + str(len(teeth)))
for n in teeth[:10]: print("  " + n)
print("[scan] Lips: " + str(len(lips)))
for n in lips: print("  " + n)
print("[scan] One-sided face muscles: " + str(len(one_sided)))
for base, v in one_sided.items():
    print("  " + base + " → has " + v['has'] + ", missing " + v['missing'])
print("[scan] Done → " + OUTPUT)
