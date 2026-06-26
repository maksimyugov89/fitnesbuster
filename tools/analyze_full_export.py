import json, re

with open(r'c:/Users/Despa/fitnesbuster/tools/all_object_names.json') as f:
    data = json.load(f)
with open(r'c:/Users/Despa/fitnesbuster/tools/all_muscle_names.json') as f:
    muscles = set(json.load(f))

SKIP_KW = [
    'artery','arteries','aorta','jugular','carotid','vein','veins',
    'venous','lymph','anastomosis','nerve','plexus','ganglion',
    'heart','lung','kidney','liver','stomach','intestine',
    'bladder','spleen','pancreas','uterus','ovary',
    'cerebral','cerebellum','brain','gyrus',
    'vitreous','retina','cornea',
    'molar','premolar','incisor','wisdom tooth',
    'trachea','larynx','epiglottis','esophagus',
    'region','lobule','articular disc',
]
ATTACH_KW = [
    ' on ',' & ','-radial','-ulnar','-humeral','-tibial','-femoral',
    'on tuberosity','on base ','on neck ','ending on','on lesser trochanter',
    'on greater trochanter','on medial surface','on lateral surface',
    'on anterior ','on posterior ','on dorsal surface','on plantar',
    'on proximal','on distal','-proximal phalanx','-distal phalanx',
    '-middle phalanx',"patte d'",'muscle-pubic','above oblique',
    'on fibula and','on solear','on apex of','on lat. surf',
    'on medial cond','on post. ','od femur',
    'on 1st meta','on 2d meta','on 3rd meta','on 3d meta','on 4th meta','on 5th meta',
    'fasciae on','-insertion','-origin','metatarsal ba',
    'on medial cuneiform','on calcaneus','on tibia','on phalanx',
    'on metatarsal head','on metatarsal base',
]
GENITALIA = {
    'Corpus cavernosum of penis','Corpus cavernosum of penis.001',
    'Corpus spongiosum of penis','Glans penis',"Glans penis'",
    'Male urethra','Urethra','Urogenital region.l','Urogenital region.r',
    'Testis.l','Testis.r','Pubic hair','Scrotum',
    'Ischiocavernosus muscle.r','Ischiocavernosus muscle.l',
    'Bulbospongiosus muscle',
    'Superficial transverse perineal muscle.r',
    'Superficial transverse perineal muscle.l',
    'Deep transverse perineal muscle.r','Deep transverse perineal muscle.l',
    'External anal sphincter.r','External anal sphincter.l',
    'External urethral sphincter','Anal region.r','Anal region.l',
}
BONE_KW = [
    'femur','tibia','fibula','patella','humerus',
    'radius.r','radius.l','ulna.r','ulna.l',
    'scapula.r','scapula.l','clavicle.r','clavicle.l',
    'hip bone','sacrum','body of sternum',
    'metacarpal bone','metatarsal bone','phalanx of ',
    'calcaneus','talus','navicular bone','cuboid bone','cuneiform bone',
    'scaphoid bone','lunate bone','triquetrum bone','pisiform bone',
    'trapezium bone','trapezoid bone','capitate bone','hamate bone',
    'mandible','frontal bone','parietal bone','occipital bone',
    'temporal bone.r','temporal bone.l',
    'nasal bone','zygomatic bone','vomer','palatine bone',
    'inferior nasal concha bone','sesamoid bones of foot',
    'proximal phalanx of hand','distal phalanx of hand',
]

def skip(name):
    if name in GENITALIA: return True
    nl = name.lower()
    return any(k in nl for k in SKIP_KW) or any(k in nl for k in ATTACH_KW)

def is_clean_bone(name):
    nl = name.lower()
    if not any(k in nl for k in BONE_KW): return False
    if skip(name): return False
    return True

muscle_ok = [n for n in muscles if not skip(n)]
bone_candidates = [n for n in data['bones'] if is_clean_bone(n)]
# Keep only primary copies (no .r.001 etc, no trailing .NNN on sideless bones)
bone_primary = []
seen_base = set()
for n in sorted(bone_candidates):
    # strip side suffix (.r or .l) and numeric suffix to get base name
    base = re.sub(r'\.[rl](\.\d+)?$', '', n)
    base = re.sub(r'\.\d+$', '', base)
    key = (base, '.l' in n.lower() or n.endswith('.l'))
    if key not in seen_base:
        seen_base.add(key)
        bone_primary.append(n)

print('MUSCLES (filtered, all_muscle_names.json): ' + str(len(muscle_ok)))
print('BONES  (primary, no duplicates): ' + str(len(bone_primary)))
print()
print('--- BONE LIST ---')
for n in sorted(bone_primary):
    print('  ' + n)
