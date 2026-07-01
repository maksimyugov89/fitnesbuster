import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// 3D muscle map built from Z-Anatomy GLB.
///
/// Each material in the GLB is named with our Flutter muscle_id (e.g.
/// "biceps_r"). On load the embedded JavaScript colours every material:
///   • primary muscles   → red  [0.91, 0.27, 0.24]
///   • secondary muscles → blue [0.31, 0.64, 0.88]
///   • all others        → neutral warm flesh tone (x-ray when highlight active)
class MuscleMap3DWidget extends StatelessWidget {
  final Set<String> primaryMuscles;
  final Set<String> secondaryMuscles;
  final double height;

  const MuscleMap3DWidget({
    super.key,
    this.primaryMuscles = const {},
    this.secondaryMuscles = const {},
    this.height = 380,
  });

  String _buildRelatedJs() {
    final primaryJson = '[${primaryMuscles.map((id) => '"$id"').join(',')}]';
    final secondaryJson =
        '[${secondaryMuscles.map((id) => '"$id"').join(',')}]';

    return '''
(function () {
  var primary   = $primaryJson;
  var secondary = $secondaryJson;
  var hasHighlight = primary.length > 0 || secondary.length > 0;

  // Camera presets: [azimuthDeg, elevationDeg, radiusPct, fieldOfViewDeg, targetY_m]
  // azimuth: 0=front, 90=model-right, 180=back, -90=model-left
  // targetY: estimated Y position in model space (feet≈0, head≈1.75 after Y-up export)
  var MUSCLE_CAM = {
    'neck':                [0,   75, 38, 16, 1.50],
    'upper_trapezius':     [160, 72, 40, 17, 1.42],
    'middle_trapezius':    [180, 75, 44, 18, 1.30],
    'lower_trapezius':     [180, 78, 46, 19, 1.20],
    'anterior_deltoid':    [20,  76, 40, 17, 1.38],
    'lateral_deltoid':     [-70, 78, 38, 16, 1.38],
    'posterior_deltoid':   [150, 76, 40, 17, 1.36],
    'rotator_cuff':        [150, 74, 40, 17, 1.40],
    'pectoralis_upper':    [10,  78, 42, 18, 1.28],
    'pectoralis_lower':    [5,   80, 44, 18, 1.22],
    'pectoralis_minor':    [25,  77, 42, 17, 1.24],
    'serratus_anterior':   [35,  80, 42, 17, 1.18],
    'biceps':              [-50, 80, 38, 16, 1.15],
    'brachialis':          [-55, 80, 36, 15, 1.10],
    'triceps':             [110, 80, 38, 16, 1.15],
    'forearm_flexors':     [-70, 82, 34, 14, 0.95],
    'rectus_abdominis':    [0,   82, 44, 18, 1.08],
    'external_oblique':    [30,  82, 42, 17, 1.06],
    'transverse_abdominis':[5,   82, 44, 18, 1.08],
    'latissimus':          [180, 80, 46, 19, 1.12],
    'teres_major':         [155, 76, 40, 17, 1.32],
    'erector_spinae':      [180, 82, 48, 20, 1.06],
    'hip_flexors':         [5,   84, 44, 18, 0.88],
    'adductors':           [30,  84, 42, 17, 0.75],
    'gluteus_medius':      [155, 82, 44, 18, 0.92],
    'gluteus_maximus':     [180, 82, 46, 19, 0.88],
    'quadriceps':          [0,   84, 50, 20, 0.65],
    'hamstrings':          [180, 84, 50, 20, 0.62],
    'gastrocnemius':       [0,   86, 46, 19, 0.30],
    'soleus':              [10,  86, 44, 18, 0.25],
    'tibialis_anterior':   [10,  85, 44, 18, 0.25],
  };

  // ── Performance: limit render resolution on weak devices ──────────────────
  (function applyPerfSettings() {
    var mv = document.querySelector('model-viewer');
    if (!mv) { setTimeout(applyPerfSettings, 100); return; }
    mv.minimumRenderScale = 0.5;
  })();

  // Match material names like 'latissimus_l'/'latissimus_r' against id 'latissimus'
  function isIn(matName, list) {
    for (var i = 0; i < list.length; i++) {
      var id = list[i];
      if (matName === id || matName === id + '_l' || matName === id + '_r') return true;
    }
    return false;
  }

  function applyCameraForMuscle(muscleId) {
    var mv = document.querySelector('model-viewer');
    if (!mv) return;
    var c = MUSCLE_CAM[muscleId];
    if (!c) {
      mv.cameraOrbit = '0deg 80deg 75%';
      mv.fieldOfView = '28deg';
      mv.cameraTarget = 'auto auto auto';
    } else {
      mv.cameraOrbit = c[0] + 'deg ' + c[1] + 'deg ' + c[2] + '%';
      mv.fieldOfView = c[3] + 'deg';
      mv.cameraTarget = '0m ' + c[4] + 'm 0m';
    }
    mv.interpolationDecay = 75;
    mv.removeAttribute('auto-rotate');
  }

  function resetCamera() {
    var mv = document.querySelector('model-viewer');
    if (!mv) return;
    mv.cameraOrbit = '0deg 80deg 115%';
    mv.fieldOfView = 'auto';
    mv.cameraTarget = 'auto auto auto';
    mv.interpolationDecay = 75;
    mv.setAttribute('auto-rotate', '');
  }

  function applyColors() {
    var mv = document.querySelector('model-viewer');
    if (!mv || !mv.model) return false;
    var mats = mv.model.materials;
    if (!mats || mats.length === 0) return false;
    for (var i = 0; i < mats.length; i++) {
      var mat  = mats[i];
      var name = mat.name;
      var color;
      var alphaMode;
      if (isIn(name, primary)) {
        color = [0.91, 0.27, 0.24, 1.0];
        alphaMode = 'OPAQUE';
      } else if (isIn(name, secondary)) {
        color = [0.31, 0.64, 0.88, 1.0];
        alphaMode = 'OPAQUE';
      } else if (name === 'bone_fill') {
        color = [0.88, 0.82, 0.66, hasHighlight ? 0.40 : 1.0];
        alphaMode = hasHighlight ? 'BLEND' : 'OPAQUE';
      } else if (hasHighlight) {
        color = [0.72, 0.45, 0.38, 0.15];
        alphaMode = 'BLEND';
      } else {
        color = [0.72, 0.45, 0.38, 1.0];
        alphaMode = 'OPAQUE';
      }
      // Switch alphaMode before setting color — BLEND enables runtime transparency,
      // OPAQUE keeps depthWrite=true for correct depth occlusion in the default view.
      if (mat.setAlphaMode) mat.setAlphaMode(alphaMode);
      mat.pbrMetallicRoughness.setBaseColorFactor(color);
    }
    // Auto-zoom: move camera to show the selected muscle, stop rotation
    if (hasHighlight) {
      var targetId = primary.length > 0 ? primary[0]
                   : (secondary.length > 0 ? secondary[0] : null);
      if (targetId) applyCameraForMuscle(targetId);
    } else {
      resetCamera();
    }
    return true;
  }

  // Poll until model materials are available (timing-safe, max 10 s)
  var tries = 0;
  function poll() {
    if (applyColors() || tries++ > 40) return;
    setTimeout(poll, 250);
  }

  function hookLoad() {
    var mv = document.querySelector('model-viewer');
    if (mv) mv.addEventListener('load', function() { applyColors(); });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() { hookLoad(); poll(); });
  } else {
    hookLoad();
    poll();
  }
})();
''';
  }

  @override
  Widget build(BuildContext context) {
    // ValueKey forces full widget rebuild (and model reload) when muscles change.
    final key = ValueKey(
      '3d_${primaryMuscles.join(",")}_${secondaryMuscles.join(",")}',
    );

    return SizedBox(
      height: height,
      child: ModelViewer(
        key: key,
        src: 'assets/anatomy/muscles_3d.glb',
        alt: 'Interactive 3D muscle anatomy',

        // ── Auto-rotate ──────────────────────────────────────────────────────
        autoRotate: true,
        autoRotateDelay: 3000,
        rotationPerSecond: '15deg', // slower = less GPU per frame
        // ── Interaction ──────────────────────────────────────────────────────
        cameraControls: true,
        disableZoom: false,

        // ── Background / appearance ──────────────────────────────────────────
        backgroundColor: Colors.transparent,

        // ── Lighting: no shadow = biggest single GPU win on mobile ───────────
        shadowIntensity: 0,
        shadowSoftness: 0,

        // ── Camera: slightly zoomed-out to fit full body + head in frame ─────
        // 0deg azimuth → front view on load; 80deg elevation → slight top-down;
        // 115% distance → guaranteed full-body visibility in any height.
        cameraOrbit: '0deg 80deg 115%',

        // ── JS: colours + minimumRenderScale performance hint ────────────────
        relatedJs: _buildRelatedJs(),
      ),
    );
  }
}
