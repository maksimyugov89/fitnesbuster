import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum BodyView { front, back }

class MuscleZone {
  final String id;
  final String displayName;
  final String displayNameRu;
  final BodyView view;

  const MuscleZone({
    required this.id,
    required this.displayName,
    required this.displayNameRu,
    required this.view,
  });
}

class MuscleMapWidget extends StatefulWidget {
  final BodyView view;
  final Set<String> primaryMuscles;
  final Set<String> secondaryMuscles;
  final void Function(String muscleId)? onMuscleTap;
  final double? width;
  final double? height;

  const MuscleMapWidget({
    super.key,
    required this.view,
    this.primaryMuscles = const {},
    this.secondaryMuscles = const {},
    this.onMuscleTap,
    this.width,
    this.height,
  });

  @override
  State<MuscleMapWidget> createState() => _MuscleMapWidgetState();
}

class _MuscleMapWidgetState extends State<MuscleMapWidget> {
  static Map<String, MuscleZone>? _manifest;
  static ui.Image? _cachedFront;
  static ui.Image? _cachedBack;

  String? _tappedId;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_loadManifest(), _loadImages()]);
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _loadManifest() async {
    if (_manifest != null) return;
    final raw = await rootBundle.loadString('assets/anatomy/muscle_manifest.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _manifest = {};
    for (final e in json.entries) {
      final d = e.value as Map<String, dynamic>;
      _manifest![e.key] = MuscleZone(
        id: e.key,
        displayName: d['displayName'] as String,
        displayNameRu: d['displayNameRu'] as String? ?? d['displayName'] as String,
        view: (d['view'] as String) == 'front' ? BodyView.front : BodyView.back,
      );
    }
  }

  Future<void> _loadImages() async {
    await Future.wait([
      if (_cachedFront == null)
        _loadUiImage('assets/anatomy/front_body.png').then((v) => _cachedFront = v),
      if (_cachedBack == null)
        _loadUiImage('assets/anatomy/back_body.png').then((v) => _cachedBack = v),
    ]);
  }

  Future<ui.Image> _loadUiImage(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    final bodyImage = widget.view == BodyView.front ? _cachedFront : _cachedBack;

    return LayoutBuilder(builder: (ctx, constraints) {
      final w = widget.width ?? constraints.maxWidth;
      final h = widget.height ?? w * (1536 / 1024);

      if (!_ready || bodyImage == null) {
        return SizedBox(
          width: w, height: h,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }

      final zones = widget.view == BodyView.front ? _kFrontZones : _kBackZones;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onMuscleTap == null ? null : (d) {
          final svgX = d.localPosition.dx / w * 1024;
          final svgY = d.localPosition.dy / h * 1536;
          final hit = _hitTest(svgX, svgY, zones);
          if (hit != null) {
            setState(() => _tappedId = hit);
            widget.onMuscleTap!(hit);
          }
        },
        child: CustomPaint(
          size: Size(w, h),
          painter: _MusclePainter(
            bodyImage: bodyImage,
            primaryMuscles: widget.primaryMuscles,
            secondaryMuscles: widget.secondaryMuscles,
            tappedId: _tappedId,
            zones: zones,
          ),
        ),
      );
    });
  }

  String? _hitTest(double x, double y, Map<String, List<List<int>>> zones) {
    for (final e in zones.entries) {
      if (_pointInPolygon(x, y, e.value)) return e.key;
    }
    return null;
  }

  static bool _pointInPolygon(double px, double py, List<List<int>> poly) {
    final n = poly.length;
    bool inside = false;
    int j = n - 1;
    for (int i = 0; i < n; i++) {
      final xi = poly[i][0].toDouble(), yi = poly[i][1].toDouble();
      final xj = poly[j][0].toDouble(), yj = poly[j][1].toDouble();
      if ((yi > py) != (yj > py) &&
          px < (xj - xi) * (py - yi) / (yj - yi) + xi) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  // ── Zone polygon data (1024×1536 SVG coordinate space) ──────────────────────

  static const _kFrontZones = <String, List<List<int>>>{
    'neck':                     [[455,225],[570,225],[578,298],[448,298]],
    'upper_trapezius':          [[448,215],[572,215],[718,305],[700,335],[570,292],[455,292],[325,335],[307,305]],
    'anterior_deltoid_right':   [[295,300],[390,300],[395,385],[365,450],[260,445],[258,380]],
    'anterior_deltoid_left':    [[635,300],[730,300],[767,380],[765,445],[630,450],[608,385]],
    'lateral_deltoid_right':    [[200,295],[300,295],[275,455],[185,445]],
    'lateral_deltoid_left':     [[725,295],[825,295],[840,445],[750,455]],
    'pectoralis_upper_right':   [[370,298],[510,298],[508,445],[352,435]],
    'pectoralis_upper_left':    [[515,298],[655,298],[673,435],[515,445]],
    'pectoralis_lower_right':   [[365,445],[508,445],[505,518],[388,528]],
    'pectoralis_lower_left':    [[515,445],[660,445],[637,528],[518,518]],
    'biceps_right':             [[225,455],[365,455],[368,630],[218,625]],
    'biceps_left':              [[660,455],[800,455],[808,625],[658,630]],
    'forearm_flexors_right':    [[208,635],[370,635],[355,830],[200,820]],
    'forearm_flexors_left':     [[655,635],[820,635],[828,820],[670,830]],
    'rectus_abdominis':         [[452,518],[572,518],[568,840],[455,840]],
    'external_oblique_right':   [[372,518],[452,518],[448,840],[358,800],[355,680]],
    'external_oblique_left':    [[572,518],[652,518],[668,680],[665,800],[575,840]],
    'hip_flexors_right':        [[385,840],[510,840],[502,960],[375,952]],
    'hip_flexors_left':         [[515,840],[640,840],[650,952],[522,960]],
    'adductors_right':          [[430,960],[510,960],[508,1185],[435,1182]],
    'adductors_left':           [[515,960],[595,960],[590,1182],[515,1185]],
    'quadriceps_right':         [[350,952],[430,952],[435,1185],[345,1178]],
    'quadriceps_left':          [[595,952],[675,952],[680,1178],[568,1185]],
    'tibialis_anterior_right':  [[415,1192],[505,1192],[498,1390],[420,1388]],
    'tibialis_anterior_left':   [[520,1192],[610,1192],[605,1388],[525,1390]],
  };

  static const _kBackZones = <String, List<List<int>>>{
    'posterior_deltoid_right':  [[225,298],[355,298],[375,458],[210,452]],
    'posterior_deltoid_left':   [[672,298],[800,298],[815,452],[650,458]],
    'middle_trapezius':         [[355,298],[672,298],[660,525],[368,525]],
    'lower_trapezius':          [[400,525],[625,525],[560,710],[470,710]],
    'latissimus_right':         [[268,475],[445,475],[420,730],[265,710]],
    'latissimus_left':          [[580,475],[758,475],[760,710],[603,730]],
    'teres_major_right':        [[268,435],[385,435],[408,530],[270,528]],
    'teres_major_left':         [[640,435],[758,435],[756,528],[617,530]],
    'triceps_right':            [[195,432],[305,432],[318,678],[188,665]],
    'triceps_left':             [[720,432],[832,432],[840,665],[708,678]],
    'erector_spinae':           [[435,710],[592,710],[580,940],[445,940]],
    'gluteus_medius_right':     [[340,810],[472,810],[480,912],[342,910]],
    'gluteus_medius_left':      [[553,810],[688,810],[685,910],[543,912]],
    'gluteus_maximus_right':    [[370,910],[510,910],[505,1090],[352,1082]],
    'gluteus_maximus_left':     [[515,910],[655,910],[673,1082],[520,1090]],
    'hamstrings_right':         [[358,1090],[510,1090],[505,1200],[360,1196]],
    'hamstrings_left':          [[515,1090],[668,1090],[665,1196],[520,1200]],
    'gastrocnemius_right':      [[382,1205],[498,1205],[492,1345],[388,1342]],
    'gastrocnemius_left':       [[527,1205],[643,1205],[638,1342],[532,1345]],
    'soleus_right':             [[390,1348],[490,1348],[482,1448],[395,1446]],
    'soleus_left':              [[535,1348],[635,1348],[630,1446],[540,1448]],
  };
}

// ── CustomPainter ─────────────────────────────────────────────────────────────

class _MusclePainter extends CustomPainter {
  final ui.Image bodyImage;
  final Set<String> primaryMuscles;
  final Set<String> secondaryMuscles;
  final String? tappedId;
  final Map<String, List<List<int>>> zones;

  static const _primaryColor   = Color(0xFFE8453C);
  static const _secondaryColor = Color(0xFF4FA3E0);
  static const _tapColor       = Color(0xFFFFB300);

  _MusclePainter({
    required this.bodyImage,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.zones,
    this.tappedId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 1024;
    final sy = size.height / 1536;
    final src = Rect.fromLTWH(
        0, 0, bodyImage.width.toDouble(), bodyImage.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Draw base body
    canvas.drawImageRect(
        bodyImage, src, dst, Paint()..filterQuality = FilterQuality.high);

    final activeIds = <String>{
      ...primaryMuscles,
      ...secondaryMuscles,
      if (tappedId != null) tappedId!,
    };
    if (activeIds.isEmpty) return;

    // 2. Draw highlights in a layer composited via srcATop.
    //    srcATop: layer pixels show only where canvas (body image) has alpha > 0.
    //    This works on all renderers (Skia + Impeller) unlike dstIn-within-layer.
    canvas.saveLayer(dst, Paint()..blendMode = BlendMode.srcATop);

    for (final id in activeIds) {
      final poly = zones[id];
      if (poly == null) continue;

      final color = _colorFor(id);
      final path = _toPath(poly, sx, sy);

      // Outer soft glow
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.45)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 * sx),
      );

      // Solid fill
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.70)
          ..style = PaintingStyle.fill,
      );

      // Bright border
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8 * sx
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, 2 * sx),
      );
    }

    // Restore composites the highlight layer onto the body image via srcATop —
    // highlights only appear where the body PNG has alpha > 0.
    canvas.restore();

    // 3. Re-draw body anatomy at low opacity so muscle lines show through.
    canvas.drawImageRect(
        bodyImage, src, dst,
        Paint()
          ..filterQuality = FilterQuality.high
          ..color = const Color(0x55FFFFFF)); // ~33 % opacity overlay
  }

  Color _colorFor(String id) {
    if (id == tappedId) return _tapColor;
    if (primaryMuscles.contains(id)) return _primaryColor;
    return _secondaryColor;
  }

  Path _toPath(List<List<int>> poly, double sx, double sy) {
    final path = Path();
    for (int i = 0; i < poly.length; i++) {
      final x = poly[i][0] * sx;
      final y = poly[i][1] * sy;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_MusclePainter old) =>
      old.bodyImage != bodyImage ||
      old.primaryMuscles != primaryMuscles ||
      old.secondaryMuscles != secondaryMuscles ||
      old.tappedId != tappedId;
}
