/// Maps Russian muscle text from AI plan → 3D zone IDs for MuscleMap3DWidget.
/// Handles both adjective forms ("грудная") and noun forms ("грудь") that AI may generate.
class MuscleZoneMatcher {
  MuscleZoneMatcher._();

  static Set<String> parse(String text) {
    final t = text.toLowerCase();
    final zones = <String>{};

    if (t.contains('грудн') || t.contains('грудь') || t.contains('пектор')) {
      zones.addAll(['pectoralis_upper', 'pectoralis_lower']);
    }
    if (t.contains('малая грудн') || (t.contains('грудн') && t.contains('малая'))) {
      zones.add('pectoralis_minor');
    }
    if (t.contains('широч') || t.contains('latiss') || t.contains('lats') || t.contains('спин')) {
      zones.add('latissimus');
    }
    if (t.contains('трапец') || t.contains('trapez')) {
      zones.addAll(['upper_trapezius', 'middle_trapezius', 'lower_trapezius']);
    }
    if (t.contains('дельт') || t.contains('delt') || t.contains('плечи') || t.contains('плечо')) {
      if (t.contains('перед')) {
        zones.add('anterior_deltoid');
      } else if (t.contains('задн')) {
        zones.add('posterior_deltoid');
      } else if (t.contains('сред') || t.contains('боков') || t.contains('латер')) {
        zones.add('lateral_deltoid');
      } else {
        zones.addAll(['anterior_deltoid', 'lateral_deltoid', 'posterior_deltoid']);
      }
    }
    if (t.contains('бицепс') || t.contains('bicep')) {
      zones.add('biceps');
    }
    if (t.contains('трицепс') || t.contains('tricep')) {
      zones.add('triceps');
    }
    if (t.contains('квадр') || t.contains('quad') || (t.contains('бедр') && t.contains('перед'))) {
      zones.add('quadriceps');
    }
    if (t.contains('бицепс бедра') || (t.contains('задн') && t.contains('бедр')) || t.contains('hamstr')) {
      zones.add('hamstrings');
    }
    if (t.contains('ягоди') || t.contains('glute')) {
      if (t.contains('средн') || t.contains('medius')) {
        zones.add('gluteus_medius');
      } else {
        zones.addAll(['gluteus_maximus', 'gluteus_medius']);
      }
    }
    if (t.contains('икр') || t.contains('голень') || t.contains('calf') || t.contains('calves')) {
      zones.addAll(['gastrocnemius', 'soleus']);
    }
    if (t.contains('пресс') || t.contains('брюшн') || t.contains('abdom') || t.contains('rectus') ||
        (t.contains('прям') && t.contains('живот'))) {
      zones.add('rectus_abdominis');
    }
    if (t.contains('косые') || t.contains('облик') || t.contains('oblique')) {
      zones.add('external_oblique');
    }
    if (t.contains('поперечн') || t.contains('transvers')) {
      zones.add('transverse_abdominis');
    }
    if ((t.contains('разгибател') && t.contains('спин')) || t.contains('erector') || t.contains('выпрямит') || t.contains('поясниц')) {
      zones.add('erector_spinae');
    }
    if (t.contains('ромбовидн') || t.contains('rhomb')) {
      zones.add('teres_major');
    }
    if (t.contains('предплечь') || t.contains('forearm')) {
      zones.add('forearm_flexors');
    }
    if (t.contains('шея') || t.contains('neck') || t.contains('лопатк') || t.contains('грудино')) {
      zones.add('neck');
    }
    if (t.contains('приводящ') || t.contains('adduct')) {
      zones.add('adductors');
    }
    if ((t.contains('сгибател') && t.contains('бедр')) || t.contains('подвздошн') || t.contains('hip flex')) {
      zones.add('hip_flexors');
    }
    if (t.contains('зубчат') || t.contains('serratus')) {
      zones.add('serratus_anterior');
    }
    if (t.contains('манжет') || t.contains('rotator') || t.contains('вращател')) {
      zones.add('rotator_cuff');
    }
    if ((t.contains('плечев') && !t.contains('пояс')) || t.contains('brachiali')) {
      zones.add('brachialis');
    }
    if (t.contains('тибиалис') || t.contains('tibial') || (t.contains('перед') && t.contains('берц'))) {
      zones.add('tibialis_anterior');
    }
    return zones;
  }
}
