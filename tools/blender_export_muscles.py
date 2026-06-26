"""
Blender background script: exports ALL muscles + full skeleton from Z-Anatomy.blend.

Muscle strategy:
  - Muscles listed in MUSCLE_MAP  → bilateral materials (muscle_id_l / muscle_id_r)
    so the JS can highlight them per exercise.
  - Every other muscle in all_muscle_names.json → 'body_fill' (visible, not highlightable).
  - No vessels, no nerves, no genitalia.

Bone strategy:
  - BONE_FILL_NAMES contains every primary bone body (no insertion markers, no duplicates).
  - MIRROR_TO_LEFT: right-side bones that have no left counterpart in Z-Anatomy are
    mirrored via BMesh (flip X axis + reverse face normals).
  - All bones → 'bone_fill' (ivory material, stays semi-visible in x-ray mode).

Run with:
  blender -b Z-Anatomy.blend --python blender_export_muscles.py
"""
import bpy
import bmesh
import os
import re
import json

OUTPUT_PATH = r"C:\Users\Despa\fitnesbuster\assets\anatomy\muscles_3d.glb"
MUSCLE_NAMES_JSON = r"C:\Users\Despa\fitnesbuster\tools\all_muscle_names.json"

# ── Exercise muscles: bilateral materials for JS highlighting ─────────────────
MUSCLE_MAP = {
    # ── Neck / Traps ──────────────────────────────────────────────────────────
    'neck': [
        'Sternocleidomastoid muscle.r', 'Sternocleidomastoid muscle.l',
    ],
    'upper_trapezius': [
        'Descending part of trapezius muscle.r',
        'Descending part of trapezius muscle.l',
    ],
    'middle_trapezius': [
        'Transverse part of trapezius muscle.r',
        'Transverse part of trapezius muscle.l',
    ],
    'lower_trapezius': [
        'Ascending part of trapezius muscle.r',
        'Ascending part of trapezius muscle.l',
    ],
    # ── Shoulders ─────────────────────────────────────────────────────────────
    'anterior_deltoid': [
        'Clavicular part of deltoid muscle.r',
        'Clavicular part of deltoid muscle.l',
    ],
    'lateral_deltoid': [
        'Acromial part of deltoid muscle.r',
        'Acromial part of deltoid muscle.l',
    ],
    'posterior_deltoid': [
        'Scapular part of deltoid uscle.r',
        'Scapular part of deltoid uscle.l',
    ],
    'rotator_cuff': [
        'Supraspinatus muscle.r', 'Infraspinatus muscle.r', 'Teres minor muscle.r',
        'Supraspinatus muscle.l', 'Infraspinatus muscle.l', 'Teres minor muscle.l',
    ],
    # ── Chest ─────────────────────────────────────────────────────────────────
    'pectoralis_upper': [
        'Clavicular head of pectoralis major muscle.r',
        'Clavicular head of pectoralis major muscle.l',
    ],
    'pectoralis_lower': [
        'Sternocostal head of pectoralis major muscle.r',
        'Abdominal part of pectoralis major muscle.r',
        'Sternocostal head of pectoralis major muscle.l',
        'Abdominal part of pectoralis major muscle.l',
    ],
    'pectoralis_minor': [
        'Pectoralis minor muscle.r', 'Pectoralis minor muscle.r.001',
        'Pectoralis minor muscle.l',
    ],
    'serratus_anterior': [
        'Serratus anterior muscle.r', 'Serratus anterior muscle.l',
    ],
    # ── Arms ──────────────────────────────────────────────────────────────────
    'biceps': [
        'Long head of biceps brachii.r', 'Short head of biceps brachii.r',
        'Long head of biceps brachii.l', 'Short head of biceps brachii.l',
    ],
    'brachialis': [
        'Brachialis muscle.r', 'Brachialis muscle.l',
    ],
    'triceps': [
        'Medial head of triceps brachii muscle.r',
        'Lateral head of triceps brachii muscle.r',
        'Long head of triceps brachii muscle.r',
        'Medial head of triceps brachii muscle.l',
        'Lateral head of triceps brachii muscle.l',
        'Long head of triceps brachii muscle.l',
    ],
    'forearm_flexors': [
        'Flexor carpi radialis.r', 'Flexor digitorum superficialis.r',
        'Humeral head of flexor carpi ulnaris.r',
        'Flexor carpi radialis.l', 'Flexor digitorum superficialis.l',
        'Humeral head of flexor carpi ulnaris.l',
    ],
    # ── Core ──────────────────────────────────────────────────────────────────
    'rectus_abdominis': [
        'Rectus abdominis muscle.r', 'Rectus abdominis muscle.l',
    ],
    'external_oblique': [
        'External abdominal oblique.r',
        'External abdominal oblique.r.001',
        'External Abdominal Oblique',
        'External Abdominal Oblique.001',
        'Internal abdominal oblique.l',
    ],
    'transverse_abdominis': [
        'Transversus abdominis muscle.r', 'Transversus abdominis muscle.l',
    ],
    # ── Back ──────────────────────────────────────────────────────────────────
    'latissimus': [
        'Latissimus dorsi muscle.r', 'Latissimus dorsi muscle.l',
        "Latissimus dorsi muscle'.r", "Latissimus dorsi muscle'.l",
        'Latissimus dorsi muscle.r.004', 'Latissimus dorsi muscle.l.001',
    ],
    'teres_major': [
        'Teres major muscle.r', 'Teres major muscle.l',
    ],
    'erector_spinae': [
        'Iliocostalis lumborum muscle.r', 'Iliocostalis lumborum muscle.l',
        'Longissimus thoracis muscle.r', 'Longissimus thoracis muscle.l',
        'Multifidus lumborum.r', 'Multifidus lumborum.l',
    ],
    # ── Hips / Glutes ─────────────────────────────────────────────────────────
    'hip_flexors': [
        'Iliacus muscle.r', 'Psoas muscle.r',
        'Iliacus muscle.l', 'Psoas muscle.l',
    ],
    'adductors': [
        'Adductor magnus.r', 'Adductor longus.r', 'Adductor brevis.r',
        'Adductor magnus.l', 'Adductor longus.l', 'Adductor brevis.l',
    ],
    'gluteus_medius': [
        'Gluteus medius muscle.r', 'Gluteus medius muscle.l',
    ],
    'gluteus_maximus': [
        'Gluteus maximus muscle.r', 'Gluteus maximus muscle.l',
    ],
    # ── Legs ──────────────────────────────────────────────────────────────────
    'quadriceps': [
        'Rectus femoris muscle.r', 'Vastus lateralis muscle.r',
        'Vastus medialis muscle.r', 'Vastus intermedius muscle.r',
        'Rectus femoris muscle.l', 'Vastus lateralis muscle.l',
        'Vastus medialis muscle.l', 'Vastus intermedius muscle.l',
    ],
    'hamstrings': [
        'Semimembranosus muscle.r', 'Semitendinosus muscle.r',
        'Long head of biceps femoris muscle.r', 'Short head of biceps femoris muscle.r',
        'Semimembranosus muscle.l', 'Semitendinosus muscle.l',
        'Long head of biceps femoris muscle.l', 'Short head of biceps femoris muscle.l',
    ],
    'gastrocnemius': [
        'Lateral head of gastrocnemius.r', 'Medial head of gastrocnemius.r',
        'Lateral head of gastrocnemius.l', 'Medial head of gastrocnemius.l',
    ],
    'soleus': [
        'Soleus muscle.r', 'Soleus muscle.l',
    ],
    'tibialis_anterior': [
        'Tibialis anterior muscle.r', 'Tibialis anterior muscle.l',
    ],
}

# ── Objects NEVER to export ───────────────────────────────────────────────────
BLACKLIST = {
    'Corpus cavernosum of penis', 'Corpus cavernosum of penis.001',
    'Corpus spongiosum of penis', 'Glans penis', "Glans penis'",
    'Male urethra', 'Urethra', 'Urogenital region.l', 'Urogenital region.r',
    'Testis.l', 'Testis.r', 'Pubic hair', 'Scrotum',
    'Ischiocavernosus muscle.r', 'Ischiocavernosus muscle.l',
    'Bulbospongiosus muscle',
    'Superficial transverse perineal muscle.r',
    'Superficial transverse perineal muscle.l',
    'Deep transverse perineal muscle.r', 'Deep transverse perineal muscle.l',
    'External anal sphincter.r', 'External anal sphincter.l',
    'External urethral sphincter',
    'Anal region.r', 'Anal region.l',
}

# Keywords that identify objects to SKIP even if they appear in muscle scan
VESSEL_KW = ('artery', 'arteries', 'aorta', 'jugular', 'vein', 'veins',
             'venous', 'lymph', 'anastomosis', 'capillar')
NERVE_KW  = ('nerve', 'plexus', 'ganglion', 'fascicle')
OTHER_SKIP_KW = ('region', 'lobule', 'articular disc', 'brain', 'gyrus',
                 'cerebral', 'lobe.l.', 'lobe.r.', 'heart', 'lung',
                 'kidney', 'liver', 'stomach', 'intestin', 'colon',
                 'bladder', 'spleen', 'pancreas', 'trachea', 'larynx',
                 'epiglottis', 'esophagus', 'molar', 'premolar',
                 'incisor', 'wisdom tooth', 'vitreous', 'retina', 'cornea')

# Teeth/gingiva: bypasses OTHER_SKIP_KW (molar/premolar/incisor filtered there).
# Exported as bone_fill (ivory) — tooth enamel reads naturally as hard tissue.
TEETH_NAMES = [
    '11-Upper medial incisor.l', '11-Upper medial incisor.r',
    '12-Upper lateral incisor.l', '12-Upper lateral incisor.r',
    '13-Upper canine.l', '13-Upper canine.r',
    '14-Upper first premolar.l', '14-Upper first premolar.r',
    '15-Upper second premolar.l', '15-Upper second premolar.r',
    '16-Upper first molar.l', '16-Upper first molar.r',
    '17-Upper second molar.l', '17-Upper second molar.r',
    '31-Lower medial incisor.l', '31-Lower medial incisor.r',
    '32-Lower lateral incisor.l', '32-Lower lateral incisor.r',
    '33-Lower canine.l', '33-Lower canine.r',
    '34-Lower first premolar.l', '34-Lower first premolar.r',
    '35-Lower second premolar.l', '35-Lower second premolar.r',
    '36-Upper first molar.l', '36-Upper first molar.r',
    '37-Upper second molar.l', '37-Upper second molar.r',
    # Gingiva moved to SKULL_SURFACE_NAMES (soft tissue = body_fill flesh tone, not ivory)
]

# Soft-tissue mirrors: objects that only exist on the right side in Z-Anatomy.
# Mirrored as body_fill (flesh tone), unlike MIRROR_TO_LEFT which uses bone_fill.
MIRROR_TO_LEFT_BODY = [
    'Levator palpebrae superioris.r',  # eyelid elevator, no .l in Z-Anatomy
    'Sclera.r.001',                    # eyeball white, no .l in Z-Anatomy
    # Orbital muscles — only .r exists in Z-Anatomy; mirror to fill left eye
    'Medial rectus muscle.r',
    'Lateral rectus muscle.r',
    'Superior rectus muscle.r',
    'Inferior rectus muscle.r',
    'Superior oblique muscle.r',
    'Inferior oblique muscle.r',
    'Superior tarsus.r',
    'Inferior tarsus.r',
    'Common tendinous ring.r',
]

def _should_skip_by_name(name):
    if name in BLACKLIST:
        return True
    nl = name.lower()
    return (any(k in nl for k in VESSEL_KW) or
            any(k in nl for k in NERVE_KW) or
            any(k in nl for k in OTHER_SKIP_KW))

# ── Skeletal bones: every primary bone body ───────────────────────────────────
BONE_FILL_NAMES = [
    # ── UPPER LIMB ────────────────────────────────────────────────────────────
    'Humerus.r', 'Humerus.l',
    'Radius.r',
    'Ulna.r',
    # ── SHOULDER GIRDLE ───────────────────────────────────────────────────────
    'Clavicle.r',
    'Scapula.r',
    # ── LOWER LIMB ────────────────────────────────────────────────────────────
    'Femur.r', 'Femur.l',
    'Tibia.r', 'Tibia.l',
    'Fibula.r', 'Fibula.l',
    'Patella.r', 'Patella.l',
    # ── PELVIS ────────────────────────────────────────────────────────────────
    'Hip bone.r', 'Hip bone.l',
    'Sacrum',
    # ── SPINE: intervertebral discs (vertebral bodies not in Z-Anatomy) ───────
    'Intervertebral disc C2-C3', 'Intervertebral disc C3-C4',
    'Intervertebral disc C4-C5', 'Intervertebral disc C5-C6',
    'Intervertebral disc C6-C7', 'Intervertebral disc C7-T1',
    'Intervertebral disc T1-T2', 'Intervertebral disc T2-T3',
    'Intervertebral disc T3-T4', 'Intervertebral disc T4-T5',
    'Intervertebral disc T5-T6', 'Intervertebral disc T6-T7',
    'Intervertebral disc T7-T8', 'Intervertebral disc T8-T9',
    'Intervertebral disc T9-T10', 'Intervertebral disc T10-T11',
    'Intervertebral disc T11-T12', 'Intervertebral disc T12-L1',
    'Intervertebral disc L1-L2', 'Intervertebral disc L2-L3',
    'Intervertebral disc L3-L4', 'Intervertebral disc L4-L5',
    'Intervertebral disc L5-S1',
    # ── THORAX: sternum + ribs ────────────────────────────────────────────────
    'Manubrium',
    'Body of sternum',
    'Xiphoid process',
    '1st rib.r', '1st rib.l',
    '2d rib.r', '2d rib.l',
    '3rd rib.r', '3rd rib.l',
    '4th rib.r', '4th rib.l',
    '5th rib.r', '5th rib.l',
    '6th rib.r', '6th rib.l',
    '7th rib.r', '7th rib.l',
    '8th rib.r', '8th rib.l',
    '9th rib.r', '9th rib.l',
    '10th rib.r', '10th rib.l',
    '11th rib.r', '11th rib.l',
    '12th rib.r', '12th rib.l',
    # ── COSTAL CARTILAGES (connect ribs to sternum) ───────────────────────────
    '1st costal cartilage.r', '1st costal cartilage.l',
    '2d costal cartilage.r', '2d costal cartilage.l',
    '3d costal cartilage.r', '3d costal cartilage.l',
    '4th costal cartilage.r', '4th costal cartilage.l',
    '5th costal cartilage.r', '5th costal cartilage.l',
    '6th costal cartilage.r', '6th costal cartilage.l',
    '7th costal cartilage.r', '7th costal cartilage.l',
    # Nasal cartilages moved to SKULL_SURFACE_NAMES (body_fill flesh color)
    # so they blend into the nose instead of protruding as white ivory.
    # ── SKULL ─────────────────────────────────────────────────────────────────
    # Frontal, Parietal, Occipital bones → SKULL_SURFACE_NAMES (body_fill flesh)
    # so they fill the skull top/back without a white ivory dome/patch.
    # LAcrimal bone removed — too small, appeared as white artifact near medial orbit.
    'Temporal bone.r', 'Temporal bone.l',
    'Zygomatic bone.r', 'Zygomatic bone.l',
    'Nasal bone.r', 'Nasal bone.l',
    # Mandible + Maxilla moved to SKULL_SURFACE_NAMES (flesh tone = no ivory jaw artifact)
    'Vomer',
    'Inferior nasal concha bone.r', 'Inferior nasal concha bone.l',
    'Palatine bone.r', 'Palatine bone.l',
    'Hyoid bone',
    # ── CARPAL BONES (right wrist — left will be mirrored) ────────────────────
    'Scaphoid bone.r', 'Lunate bone.r', 'Triquetrum bone.r',
    'Pisiform bone.r', 'Trapezium bone.r', 'Trapezoid bone.r',
    'Capitate bone.r', 'Hamate bone.r',
    # ── METACARPALS (right palm — left will be mirrored) ──────────────────────
    '1st metacarpal bone.r', '2d metacarpal bone.r', '3d metacarpal bone.r',
    '4th metacarpal bone.r', '5th metacarpal bone.r',
    # ── HAND PHALANGES — right ────────────────────────────────────────────────
    'Proximal phalanx of 1st finger.r', 'Proximal phalanx of 2d finger.r',
    'Proximal phalanx of 3rd finger.r', 'Proximal phalanx of 4th finger.r',
    'Proximal phalanx of 5th finger.r',
    'Middle phalanx of 2d finger.r', 'Middle phalanx of 3rd finger.r',
    'Middle phalanx of 4th finger.r', 'Middle phalanx of 5th finger.r',
    'Distal phalanx of 1st finger.r', 'Distal phalanx of 2d finger.r',
    'Distal phalanx of 3d finger.r', 'Distal phalanx of 4th finger.r',
    'Distal phalanx of 5th finger.r',
    # ── TARSAL BONES (ankle / heel) ───────────────────────────────────────────
    'Calcaneus.r', 'Calcaneus.l',
    'Talus.r', 'Talus.l',
    'Navicular bone.r', 'Navicular bone.l',
    'Cuboid bone.r', 'Cuboid bone.l',
    'Medial cuneiform bone.r', 'Medial cuneiform bone.l',
    'Intermediate cuneiform bone.r', 'Intermediate cuneiform bone.l',
    'Lateral cuneiform bone.r', 'Lateral cuneiform bone.l',
    # ── METATARSALS (foot arch) ───────────────────────────────────────────────
    '1st metatarsal bone.r', '1st metatarsal bone.l',
    '2d metatarsal bone.r', '2d metatarsal bone.l',
    '3rd metatarsal bone.r', '3rd metatarsal bone.l',
    '4th metatarsal bone.r', '4th metatarsal bone.l',
    '5th metatarsal bone.r', '5th metatarsal bone.l',
    # ── FOOT PHALANGES ────────────────────────────────────────────────────────
    'Proximal phalanx of 1st finger of foot.r', 'Proximal phalanx of 1st finger of foot.l',
    'Proximal phalanx of 2d finger of foot.r',  'Proximal phalanx of 2d finger of foot.l',
    'Proximal phalanx of 3rd finger of foot.r', 'Proximal phalanx of 3rd finger of foot.l',
    'Proximal phalanx of 4th finger of foot.r', 'Proximal phalanx of 4th finger of foot.l',
    'Proximal phalanx of 5th finger of foot.r', 'Proximal phalanx of 5th finger of foot.l',
    'Middle phalanx of 2d finger of foot.r',    'Middle phalanx of 2d finger of foot.l',
    'Middle phalanx of 3rd finger of foot.r',   'Middle phalanx of 3rd finger of foot.l',
    'Middle phalanx of 4th finger of foot.r',   'Middle phalanx of 4th finger of foot.l',
    'Middle phalanx of 5th finger of foot.r',   'Middle phalanx of 5th finger of foot.l',
    'Distal phalanx of 1st finger of foot.r', 'Distal phalanx of 1st finger of foot.l',
    'Distal phalanx of 2d finger of foot.r',  'Distal phalanx of 2d finger of foot.l',
    'Distal phalanx of 3rd finger of foot.r', 'Distal phalanx of 3rd finger of foot.l',
    'Distal phalanx of 4th finger of foot.r', 'Distal phalanx of 4th finger of foot.l',
    'Distal phalanx of 5th finger of foot.r', 'Distal phalanx of 5th finger of foot.l',
    # ── SESAMOIDS ─────────────────────────────────────────────────────────────
    'Sesamoid bones of foot.r',
]

# Right-side bones that have no left counterpart in Z-Anatomy.
# We mirror them (flip X + reverse normals) to fill the left side.
MIRROR_TO_LEFT = [
    # shoulder girdle
    'Scapula.r', 'Clavicle.r',
    # forearm
    'Radius.r', 'Ulna.r',
    # wrist carpals
    'Scaphoid bone.r', 'Lunate bone.r', 'Triquetrum bone.r',
    'Pisiform bone.r', 'Trapezium bone.r', 'Trapezoid bone.r',
    'Capitate bone.r', 'Hamate bone.r',
    # palm metacarpals
    '1st metacarpal bone.r', '2d metacarpal bone.r', '3d metacarpal bone.r',
    '4th metacarpal bone.r', '5th metacarpal bone.r',
    # thumb + fingers 2-5
    'Proximal phalanx of 1st finger.r', 'Distal phalanx of 1st finger.r',
    'Proximal phalanx of 2d finger.r', 'Proximal phalanx of 3rd finger.r',
    'Proximal phalanx of 4th finger.r', 'Proximal phalanx of 5th finger.r',
    'Middle phalanx of 2d finger.r', 'Middle phalanx of 3rd finger.r',
    'Middle phalanx of 4th finger.r', 'Middle phalanx of 5th finger.r',
    'Distal phalanx of 2d finger.r', 'Distal phalanx of 3d finger.r',
    'Distal phalanx of 4th finger.r', 'Distal phalanx of 5th finger.r',
]

# Bones / surfaces exported as body_fill (flesh tone) so they close visual gaps
# without producing white ivory domes or patches.
SKULL_SURFACE_NAMES = [
    # Skull cap — fill top of head without white dome
    'Frontal bone',
    'Left parietal bone', 'Parietal bone.r',
    # Skull region objects removed — they covered Temporoparietalis muscles with flat skin.
    # The actual muscles (Temporoparietalis.l/.r, Epicranial aponeurosis, Occipitalis.l/.r)
    # plus skull bones below provide adequate coverage without the skin-like overlay.
    # Occipital bone — fill back of skull (prevents white patch at occiput)
    'Occipital bone',
    # Nasal cartilages — flesh tone so they blend into nose instead of protruding white
    'Nasal cartilages.l', 'Nasal cartilages.r',
    'Nasal cartilages.001', 'Nasal cartilages.l.001', 'Nasal cartilages.r.001',
    # Vertex patches — top of skull (Z≈1.71), fill the crown gap visible in x-ray
    'Vertex.l', 'Vertex.r',
    # Eye structures — eyeball white (right; left created via MIRROR_TO_LEFT_BODY)
    # Eyebrow.l/.r removed — they looked like disconnected flesh patches on the model
    'Sclera.r.001',
    # Jaw bones — flesh tone to match surrounding muscles, avoids ivory artifact at chin
    'Mandible',
    'Maxilla.l', 'Maxilla.r',
    # Gingiva — soft tissue, flesh tone better than ivory bone color
    'Gingiva (inferior)', 'Gingiva (superior)',
    'Gingiva of lower jaw', 'Gingiva of upper jaw',
    # Lip surface structures removed — user confirmed they look like artifacts
]

NEUTRAL = (0.72, 0.45, 0.38, 1.0)   # warm muscle/skin tone
BONE    = (0.88, 0.82, 0.66, 1.0)   # ivory/cream for skeletal bones


def get_side_suffix(obj_name):
    if re.search(r'\.[lL](\.\d+)?$', obj_name):
        return '_l'
    if re.search(r'\.[rR](\.\d+)?$', obj_name):
        return '_r'
    return '_r'


def make_material(name):
    base_color = BONE if name == 'bone_fill' else NEUTRAL
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get('Principled BSDF')
    if bsdf:
        bsdf.inputs['Base Color'].default_value = base_color
        bsdf.inputs['Roughness'].default_value = 0.5 if name == 'bone_fill' else 0.65
        for spec_key in ('Specular IOR Level', 'Specular', 'IOR'):
            if spec_key in bsdf.inputs:
                bsdf.inputs[spec_key].default_value = 0.5 if name == 'bone_fill' else 0.25
                break
    # Keep OPAQUE (default). Three.js sets depthWrite=true for OPAQUE materials,
    # which gives correct depth occlusion in the default (no-highlight) view.
    # model-viewer's setBaseColorFactor() dynamically enables transparency when
    # alpha < 1, so x-ray mode still works at runtime.
    return mat


def create_mirror_obj(src_name, mat, export_col):
    """Mirror a mesh on the world X axis to create the left-side counterpart.

    Applies the source object's matrix_world to vertices before mirroring so the
    mirrored bone appears at the anatomically correct position on the left side.
    """
    src = bpy.data.objects.get(src_name)
    if not src or src.type != 'MESH':
        print("[mirror] NOT FOUND: " + src_name)
        return None
    new_mesh = src.data.copy()
    new_mesh.name = '_mr_data_' + src_name[:44]
    bm = bmesh.new()
    bm.from_mesh(new_mesh)
    world_mat = src.matrix_world
    for v in bm.verts:
        world_co = world_mat @ v.co   # local → world space
        world_co.x = -world_co.x     # mirror across world YZ plane
        v.co = world_co              # store as world-space coords
    bmesh.ops.reverse_faces(bm, faces=bm.faces)
    bm.to_mesh(new_mesh)
    bm.free()
    new_mesh.update()
    # Object placed at world origin — vertices already carry world-space positions
    new_obj = bpy.data.objects.new('_mrr_' + src_name[:48], new_mesh)
    new_obj.data.materials.clear()
    new_obj.data.materials.append(mat)
    export_col.objects.link(new_obj)
    print("[mirror] Created left mirror of: " + src_name)
    return new_obj


def patch_glb_doublesided(filepath):
    """Set doubleSided=true and keep alphaMode=OPAQUE for correct Three.js depth testing."""
    import struct
    import json as _json
    with open(filepath, 'rb') as f:
        raw = bytearray(f.read())
    assert raw[:4] == b'glTF', "Not a GLB file"
    json_len = struct.unpack_from('<I', raw, 12)[0]
    gltf = _json.loads(raw[20:20 + json_len].decode('utf-8'))
    changed = 0
    for m in gltf.get('materials', []):
        # Force OPAQUE so Three.js keeps depthWrite=true (no depth-sort artifacts)
        if m.get('alphaMode', 'OPAQUE') != 'OPAQUE':
            m['alphaMode'] = 'OPAQUE'
            changed += 1
        if not m.get('doubleSided', False):
            m['doubleSided'] = True
            changed += 1
    if not changed:
        print("[patch] Nothing to patch")
        return
    new_json = _json.dumps(gltf, separators=(',', ':')).encode('utf-8')
    pad = (-len(new_json)) % 4
    new_json += b' ' * pad
    bin_rest = raw[20 + json_len:]
    json_chunk = struct.pack('<II', len(new_json), 0x4E4F534A) + new_json
    total = 12 + len(json_chunk) + len(bin_rest)
    new_glb = b'glTF' + struct.pack('<II', 2, total) + json_chunk + bin_rest
    with open(filepath, 'wb') as f:
        f.write(new_glb)
    print("[patch] OPAQUE+doubleSided set on " + str(changed) + " materials")


def main():
    print("[export] Loading all_muscle_names.json ...")
    with open(MUSCLE_NAMES_JSON, encoding='utf-8') as f:
        all_muscle_names = json.load(f)

    print("[export] Building material assignments...")

    all_mat_ids = []
    for mid in MUSCLE_MAP:
        all_mat_ids.append(mid + '_l')
        all_mat_ids.append(mid + '_r')
    all_mat_ids.append('body_fill')
    all_mat_ids.append('bone_fill')
    mats = {mid: make_material(mid) for mid in all_mat_ids}

    obj_to_mid = {}

    # ── Pass 1: MUSCLE_MAP → bilateral materials ──────────────────────────────
    for mid, names in MUSCLE_MAP.items():
        for name in names:
            if name in BLACKLIST or _should_skip_by_name(name):
                continue
            obj = bpy.data.objects.get(name)
            if obj and obj.type == 'MESH':
                mat_id = mid + get_side_suffix(name)
                obj_to_mid[obj.name] = mat_id

    # ── Pass 2: ALL muscles from all_muscle_names.json → body_fill ───────────
    muscle_fill_count = 0
    for name in all_muscle_names:
        if name in BLACKLIST or _should_skip_by_name(name):
            continue
        obj = bpy.data.objects.get(name)
        if obj and obj.type == 'MESH' and obj.name not in obj_to_mid:
            obj_to_mid[obj.name] = 'body_fill'
            muscle_fill_count += 1

    # ── Pass 3: Bones from BONE_FILL_NAMES → bone_fill ───────────────────────
    bone_count = 0
    for name in BONE_FILL_NAMES:
        if name in BLACKLIST:
            continue
        obj = bpy.data.objects.get(name)
        if obj and obj.type == 'MESH' and obj.name not in obj_to_mid:
            obj_to_mid[obj.name] = 'bone_fill'
            bone_count += 1

    # ── Pass 3.5: Skull/face surfaces → body_fill (close visual holes w/o white dome)
    skull_surface_count = 0
    for name in SKULL_SURFACE_NAMES:
        obj = bpy.data.objects.get(name)
        if obj and obj.type == 'MESH' and obj.name not in obj_to_mid:
            obj_to_mid[obj.name] = 'body_fill'
            skull_surface_count += 1

    # ── Pass 3.6: Teeth + gingiva → bone_fill (bypasses premolar/molar/incisor filter) ──
    teeth_count = 0
    for name in TEETH_NAMES:
        obj = bpy.data.objects.get(name)
        if obj and obj.type == 'MESH' and obj.name not in obj_to_mid:
            obj_to_mid[obj.name] = 'bone_fill'
            teeth_count += 1

    muscle_map_count = len(obj_to_mid) - muscle_fill_count - bone_count - skull_surface_count - teeth_count
    print("[export] MUSCLE_MAP bilateral objects : " + str(muscle_map_count))
    print("[export] Extra muscle body_fill objects: " + str(muscle_fill_count))
    print("[export] Bone bone_fill objects        : " + str(bone_count))
    print("[export] Face surfaces (body_fill)     : " + str(skull_surface_count))
    print("[export] Teeth + gingiva (bone_fill)   : " + str(teeth_count))
    print("[export] Total objects                 : " + str(len(obj_to_mid)))

    # ── Build export collection ───────────────────────────────────────────────
    scene = bpy.context.scene
    export_col = bpy.data.collections.new("_muscles_export")
    scene.collection.children.link(export_col)

    export_objs = []
    active = None

    for obj_name, mid in obj_to_mid.items():
        src = bpy.data.objects.get(obj_name)
        if src is None:
            continue
        new_obj = src.copy()
        new_obj.data = src.data.copy()
        new_obj.name = "_exp_" + obj_name[:50]
        new_obj.data.materials.clear()
        new_obj.data.materials.append(mats[mid])
        export_col.objects.link(new_obj)
        export_objs.append(new_obj)
        active = active or new_obj

    # ── Pass 4: Mirror right-side objects to create left-side copies ─────────
    mirror_count = 0
    bone_mat = mats['bone_fill']
    for bone_src in MIRROR_TO_LEFT:
        mirrored = create_mirror_obj(bone_src, bone_mat, export_col)
        if mirrored:
            export_objs.append(mirrored)
            active = active or mirrored
            mirror_count += 1

    body_mat = mats['body_fill']
    for src_name in MIRROR_TO_LEFT_BODY:
        mirrored = create_mirror_obj(src_name, body_mat, export_col)
        if mirrored:
            export_objs.append(mirrored)
            active = active or mirrored
            mirror_count += 1

    print("[export] Created " + str(len(export_objs)) + " export objects")
    print("[export] Mirrored left-side bones    : " + str(mirror_count))

    hidden_cols = []
    for col in bpy.data.collections:
        if col is not export_col:
            col.hide_viewport = True
            hidden_cols.append(col)

    hidden_objs = []
    for obj in scene.objects:
        if obj not in export_objs:
            obj.hide_viewport = True
            hidden_objs.append(obj)

    for obj in export_objs:
        obj.hide_viewport = False
        obj.hide_set(False)
        obj.hide_render = False
        obj.select_set(True)

    if active:
        bpy.context.view_layer.objects.active = active

    print("[export] Writing → " + OUTPUT_PATH)

    with bpy.context.temp_override(
        selected_objects=export_objs,
        active_object=active,
    ):
        bpy.ops.export_scene.gltf(
            filepath=OUTPUT_PATH,
            use_selection=True,
            export_format='GLB',
            export_draco_mesh_compression_enable=True,
            export_draco_mesh_compression_level=10,
            export_materials='EXPORT',
            export_image_format='NONE',
            export_normals=True,
            export_yup=True,
            export_animations=False,
            export_skins=False,
        )

    size_mb = os.path.getsize(OUTPUT_PATH) / 1024 / 1024
    print("[export] Done!  Size: " + str(round(size_mb, 2)) + " MB")

    patch_glb_doublesided(OUTPUT_PATH)
    size_mb2 = os.path.getsize(OUTPUT_PATH) / 1024 / 1024
    print("[export] Final size: " + str(round(size_mb2, 2)) + " MB")

    for col in hidden_cols:
        col.hide_viewport = False
    for obj in hidden_objs:
        obj.hide_viewport = False
    for obj in export_objs:
        bpy.data.meshes.remove(obj.data, do_unlink=True)
    bpy.data.collections.remove(export_col)
    print("[export] Cleaned up " + str(len(export_objs)) + " temporary objects")


main()
