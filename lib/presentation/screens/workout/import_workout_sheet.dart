import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/ai/deepseek_service.dart';
import 'package:fitnesbuster/data/repositories/user_repository.dart';

// ─── Entry points ─────────────────────────────────────────────────────────────

/// Opens the plan correction sheet. [correctionType] can be:
///   'auto'        — user selects source manually (default)
///   'post_workout'— pre-filled with workout data, auto-starts analysis
///   'preference'  — user states a text preference
void showPlanCorrectionSheet(
  BuildContext context, {
  String? initialContent,
  String correctionType = 'auto',
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ImportWorkoutSheet(
      initialContent: initialContent,
      correctionType: correctionType,
    ),
  );
}

// ─── Backward-compat alias ────────────────────────────────────────────────────
void showImportWorkoutSheet(BuildContext context) =>
    showPlanCorrectionSheet(context);

// ─── State types ──────────────────────────────────────────────────────────────

enum _ImportSource { text, url, file, qr, sharedApp, postWorkout }
enum _ImportStep { selectSource, enterContent, parsing, preview, error }

// ─── Main widget ──────────────────────────────────────────────────────────────

class ImportWorkoutSheet extends StatefulWidget {
  /// Pre-filled content (from Android share intent or post-workout analysis).
  final String? initialContent;

  /// How the AI should interpret the input:
  /// 'auto', 'merge', 'preference', 'post_workout'
  final String correctionType;

  const ImportWorkoutSheet({
    super.key,
    this.initialContent,
    this.correctionType = 'auto',
  });

  @override
  State<ImportWorkoutSheet> createState() => _ImportWorkoutSheetState();
}

class _ImportWorkoutSheetState extends State<ImportWorkoutSheet> {
  _ImportStep _step = _ImportStep.selectSource;
  _ImportSource? _source;

  final _urlCtrl = TextEditingController();
  final _textCtrl = TextEditingController();

  String? _errorMsg;
  Map<String, dynamic>? _correctedPlan;
  List<String> _changes = [];
  String _reasoningText = '';
  bool _saving = false;

  final MobileScannerController _scanCtrl = MobileScannerController();
  bool _qrScanned = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialContent != null) {
      _textCtrl.text = widget.initialContent!;
      if (widget.correctionType == 'post_workout') {
        // Auto-start analysis for post-workout flow
        _source = _ImportSource.postWorkout;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _runCorrection(widget.initialContent!, 'анализ прошедшей тренировки');
        });
      } else {
        _source = _ImportSource.sharedApp;
        _step = _ImportStep.enterContent;
      }
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _textCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  // ── Core AI correction ────────────────────────────────────────────────────

  Future<void> _runCorrection(String userInput, String sourceHint) async {
    if (userInput.trim().isEmpty) return;
    setState(() { _step = _ImportStep.parsing; _errorMsg = null; });
    try {
      final service = sl<DeepSeekService>();
      final uid = FirebaseAuth.instance.currentUser?.uid;

      String jsonStr;
      if (uid != null) {
        final plans = await sl<UserRepository>().getAiPlans(uid);
        final currentPlanJson = plans['workoutPlan'];
        if (currentPlanJson != null) {
          // Correction mode: AI sees current plan and adjusts it
          final type = _resolveType(sourceHint);
          jsonStr = await service.correctWorkoutPlan(
            currentPlanJson: currentPlanJson,
            userInput: userInput,
            correctionType: type,
            sourceHint: sourceHint,
          );
        } else {
          // No plan yet — create from scratch
          jsonStr = await service.parseWorkoutFromContent(
            userInput,
            sourceHint: sourceHint,
          );
        }
      } else {
        jsonStr = await service.parseWorkoutFromContent(
          userInput,
          sourceHint: sourceHint,
        );
      }

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final changes = (data['changes'] as List? ?? []).cast<String>();
      final reasoning = data['correction_reasoning'] as String? ?? '';
      setState(() {
        _correctedPlan = data;
        _changes = changes;
        _reasoningText = reasoning;
        _step = _ImportStep.preview;
      });
    } on AiException catch (e) {
      setState(() { _errorMsg = e.message; _step = _ImportStep.error; });
    } catch (_) {
      setState(() {
        _errorMsg = AppLocalizations.tl('correctionRetryMsg');
        _step = _ImportStep.error;
      });
    }
  }

  String _resolveType(String sourceHint) {
    if (widget.correctionType == 'post_workout') return 'post_workout';
    if (widget.correctionType == 'preference') return 'preference';
    if (_source == _ImportSource.postWorkout) return 'post_workout';
    if (_source == _ImportSource.text && widget.correctionType == 'auto') {
      return 'preference';
    }
    return 'merge';
  }

  // ── URL fetch ─────────────────────────────────────────────────────────────

  Future<void> _fetchUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() { _step = _ImportStep.parsing; _errorMsg = null; });
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      final resp = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; FitnesBuster/1.0)',
      }).timeout(const Duration(seconds: 15));
      String body = resp.body
          .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<[^>]+>'), ' ')
          .replaceAll(RegExp(r'\s{2,}'), ' ')
          .trim();
      if (body.length > 8000) body = body.substring(0, 8000);
      await _runCorrection('URL: $url\n\n$body', 'ссылка: $url');
    } on SocketException {
      setState(() { _errorMsg = AppLocalizations.tl('networkError'); _step = _ImportStep.error; });
    } catch (e) {
      setState(() { _errorMsg = AppLocalizations.tl('pageLoadError'); _step = _ImportStep.error; });
    }
  }

  // ── File picker ───────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt', 'csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() { _errorMsg = AppLocalizations.tl('fileReadError'); _step = _ImportStep.error; });
        return;
      }
    } catch (e) {
      setState(() { _errorMsg = AppLocalizations.tl('fileOpenError'); _step = _ImportStep.error; });
    }
  }

  // ── Clipboard ─────────────────────────────────────────────────────────────

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Буфер обмена пуст'), duration: Duration(seconds: 2)),
        );
      }
      return;
    }
    _textCtrl.text = text;
    _source = _ImportSource.sharedApp;
    if (mounted) setState(() => _step = _ImportStep.enterContent);
  }

  // ── Save plan ─────────────────────────────────────────────────────────────

  Future<void> _savePlan() async {
    if (_correctedPlan == null || _saving) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception(AppLocalizations.tl('notAuthorized'));
      final repo = sl<UserRepository>();
      final planData = _correctedPlan!;
      final workoutPlanJson = jsonEncode(planData);
      await repo.updateWorkoutPlan(userId: uid, workoutPlanJson: workoutPlanJson);
    } catch (e) {
      setState(() { _saving = false; _errorMsg = AppLocalizations.tl('planSaveFailed'); _step = _ImportStep.error; });
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _reset() => setState(() {
    _step = _ImportStep.selectSource;
    _source = null;
    _correctedPlan = null;
    _changes = [];
    _reasoningText = '';
    _errorMsg = null;
    _qrScanned = false;
    _urlCtrl.clear();
    _textCtrl.clear();
  });

  void _back() => setState(() => _step == _ImportStep.enterContent
      ? _step = _ImportStep.selectSource
      : _reset());

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isQr = _step == _ImportStep.enterContent && _source == _ImportSource.qr;
    return DraggableScrollableSheet(
      initialChildSize: isQr ? 0.92 : 0.80,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(
            width: 38, height: 4,
            decoration: BoxDecoration(
              color: colors.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildStep(colors, scrollCtrl),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStep(dynamic colors, ScrollController scrollCtrl) {
    return switch (_step) {
      _ImportStep.selectSource => _SourceSelector(
          key: const ValueKey('select'),
          colors: colors,
          scrollCtrl: scrollCtrl,
          onSelected: (source) {
            setState(() { _source = source; });
            if (source == _ImportSource.sharedApp) {
              _pasteClipboard();
            } else {
              setState(() => _step = _ImportStep.enterContent);
            }
          },
        ),
      _ImportStep.enterContent => _ContentInput(
          key: ValueKey('input_$_source'),
          colors: colors,
          source: _source!,
          urlCtrl: _urlCtrl,
          textCtrl: _textCtrl,
          scrollCtrl: scrollCtrl,
          scanCtrl: _scanCtrl,
          qrScanned: _qrScanned,
          onBack: _back,
          onSubmitText: (text) => _runCorrection(text, _sourceLabelFor(_source!)),
          onSubmitUrl: _fetchUrl,
          onPickFile: _pickFile,
          onQrDetect: (value) {
            if (_qrScanned) return;
            setState(() => _qrScanned = true);
            HapticFeedback.mediumImpact();
            final isUrl = value.startsWith('http://') || value.startsWith('https://');
            if (isUrl) { _urlCtrl.text = value; _fetchUrl(); }
            else { _runCorrection(value, 'QR-код'); }
          },
        ),
      _ImportStep.parsing => _ParsingView(key: const ValueKey('parsing'), colors: colors),
      _ImportStep.preview  => _PreviewView(
          key: const ValueKey('preview'),
          colors: colors,
          plan: _correctedPlan!,
          changes: _changes,
          reasoning: _reasoningText,
          saving: _saving,
          scrollCtrl: scrollCtrl,
          onSave: _savePlan,
          onCancel: _reset,
        ),
      _ImportStep.error => _ErrorView(
          key: const ValueKey('error'),
          colors: colors,
          message: _errorMsg ?? AppLocalizations.tl('unknownErrorMsg'),
          onRetry: _back,
        ),
    };
  }

  static String _sourceLabelFor(_ImportSource src) => switch (src) {
    _ImportSource.text       => 'предпочтения пользователя',
    _ImportSource.url        => 'ссылка',
    _ImportSource.file       => 'файл',
    _ImportSource.qr         => 'QR-код',
    _ImportSource.sharedApp  => 'другое приложение',
    _ImportSource.postWorkout => 'анализ прошедшей тренировки',
  };
}

// ─── Source selector ──────────────────────────────────────────────────────────

class _SourceSelector extends StatelessWidget {
  final dynamic colors;
  final ScrollController scrollCtrl;
  final ValueChanged<_ImportSource> onSelected;

  const _SourceSelector({
    super.key,
    required this.colors,
    required this.scrollCtrl,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Header
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.auto_fix_high_rounded, color: c.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Скорректировать план',
                style: TextStyle(fontFamily: 'Syne', fontSize: 17, fontWeight: FontWeight.w800, color: c.textPrimary)),
            Text('AI адаптирует ваш план под запрос', style: TextStyle(fontSize: 12, color: c.textMuted)),
          ])),
        ]),
        const SizedBox(height: 20),

        // AI analysis hint
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.primary.withValues(alpha: 0.18)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.psychology_rounded, color: c.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'DeepSeek видит ваш текущий план и вносит точечные изменения — '
              'не переписывает с нуля, а адаптирует.',
              style: TextStyle(fontSize: 11, color: c.textSecondary, height: 1.45),
            )),
          ]),
        ),
        const SizedBox(height: 20),

        _OptionCard(
          colors: c,
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: const Color(0xFF4CAF50),
          title: 'Написать пожелание',
          subtitle: 'Замени упражнение, добавь ноги, убери кардио...',
          onTap: () => onSelected(_ImportSource.text),
        ),
        const SizedBox(height: 10),
        _OptionCard(
          colors: c,
          icon: Icons.link_rounded,
          iconColor: const Color(0xFFFF9500),
          title: 'Добавить из интернета',
          subtitle: 'Ссылка на программу: YouTube, Strava, Hevy, любой сайт',
          onTap: () => onSelected(_ImportSource.url),
        ),
        const SizedBox(height: 10),
        _OptionCard(
          colors: c,
          icon: Icons.content_paste_rounded,
          iconColor: const Color(0xFF4FA3E0),
          title: 'Вставить из буфера',
          subtitle: 'Скопированный текст тренировки',
          onTap: () => onSelected(_ImportSource.sharedApp),
        ),
        const SizedBox(height: 10),
        _OptionCard(
          colors: c,
          icon: Icons.insert_drive_file_rounded,
          iconColor: const Color(0xFFAB47BC),
          title: 'Загрузить файл',
          subtitle: 'JSON, TXT, CSV — программа из другого приложения',
          onTap: () => onSelected(_ImportSource.file),
        ),
        const SizedBox(height: 10),
        _OptionCard(
          colors: c,
          icon: Icons.qr_code_scanner_rounded,
          iconColor: const Color(0xFFE84444),
          title: 'Сканировать QR-код',
          subtitle: 'Ссылка или тренировка в QR',
          onTap: () => onSelected(_ImportSource.qr),
        ),
        const SizedBox(height: 10),
        _OptionCard(
          colors: c,
          icon: Icons.share_rounded,
          iconColor: const Color(0xFF26C6DA),
          title: 'Поделиться из приложения',
          subtitle: 'Hevy, Garmin Connect, Strong, Notes и др.',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Авто', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.primary)),
          ),
          onTap: () => onSelected(_ImportSource.sharedApp),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final dynamic colors;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _OptionCard({
    required this.colors,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.textPrimary.withValues(alpha: 0.07)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: colors.textMuted)),
          ])),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!]
          else Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.textMuted),
        ]),
      ),
    );
  }
}

// ─── Content input ────────────────────────────────────────────────────────────

class _ContentInput extends StatefulWidget {
  final dynamic colors;
  final _ImportSource source;
  final TextEditingController urlCtrl;
  final TextEditingController textCtrl;
  final ScrollController scrollCtrl;
  final MobileScannerController scanCtrl;
  final bool qrScanned;
  final VoidCallback onBack;
  final ValueChanged<String> onSubmitText;
  final VoidCallback onSubmitUrl;
  final VoidCallback onPickFile;
  final ValueChanged<String> onQrDetect;

  const _ContentInput({
    super.key,
    required this.colors,
    required this.source,
    required this.urlCtrl,
    required this.textCtrl,
    required this.scrollCtrl,
    required this.scanCtrl,
    required this.qrScanned,
    required this.onBack,
    required this.onSubmitText,
    required this.onSubmitUrl,
    required this.onPickFile,
    required this.onQrDetect,
  });

  @override
  State<_ContentInput> createState() => _ContentInputState();
}

class _ContentInputState extends State<_ContentInput> {
  @override
  void initState() {
    super.initState();
    if (widget.source == _ImportSource.file) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onPickFile());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
        child: Row(children: [
          IconButton(
            onPressed: widget.onBack,
            icon: Icon(Icons.arrow_back_ios_rounded, color: c.textMuted, size: 20),
          ),
          Expanded(child: Text(
            _title(widget.source),
            style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w800, color: c.textPrimary),
          )),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(child: _buildBody(c)),
    ]);
  }

  Widget _buildBody(dynamic c) => switch (widget.source) {
    _ImportSource.qr   => _buildQr(c),
    _ImportSource.url  => _buildUrl(c),
    _ImportSource.file => _buildFileWait(c),
    _                  => _buildText(c),
  };

  Widget _buildQr(dynamic c) => Column(children: [
    Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: MobileScanner(
          controller: widget.scanCtrl,
          onDetect: (capture) {
            final code = capture.barcodes.firstOrNull?.rawValue;
            if (code != null) widget.onQrDetect(code);
          },
        ),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        widget.qrScanned ? 'QR-код распознан, анализирую...' : 'Наведите камеру на QR-код',
        style: TextStyle(fontSize: 13, color: c.textMuted),
        textAlign: TextAlign.center,
      ),
    ),
  ]);

  Widget _buildUrl(dynamic c) => ListView(
    controller: widget.scrollCtrl,
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
    children: [
      Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.textPrimary.withValues(alpha: 0.1)),
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(Icons.link_rounded, color: c.textMuted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.urlCtrl,
              keyboardType: TextInputType.url,
              style: TextStyle(fontSize: 13, color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'https://...',
                hintStyle: TextStyle(color: c.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onSubmitted: (_) => widget.onSubmitUrl(),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final s in ['YouTube', 'Strava', 'Hevy', 'Garmin', 'GymShark', 'Reddit', 'любой сайт'])
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: c.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.textPrimary.withValues(alpha: 0.08)),
            ),
            child: Text(s, style: TextStyle(fontSize: 11, color: c.textMuted)),
          ),
      ]),
      const SizedBox(height: 24),
      _ActionButton(colors: c, label: 'Загрузить и скорректировать план',
          icon: Icons.auto_fix_high_rounded, onTap: widget.onSubmitUrl),
    ],
  );

  Widget _buildText(dynamic c) => ListView(
    controller: widget.scrollCtrl,
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
    children: [
      Container(
        constraints: const BoxConstraints(minHeight: 140, maxHeight: 260),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.textPrimary.withValues(alpha: 0.1)),
        ),
        child: TextField(
          controller: widget.textCtrl,
          maxLines: null,
          expands: true,
          style: TextStyle(fontSize: 13, color: c.textPrimary, height: 1.5),
          decoration: InputDecoration(
            hintText: widget.source == _ImportSource.text
                ? 'Например: "Замени жим лёжа на отжимания на брусьях", '
                  '"Хочу больше упражнений на ноги", "Убери кардио"...'
                : 'Вставьте описание тренировки: упражнения, подходы, повторения...',
            hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () async {
          final data = await Clipboard.getData(Clipboard.kTextPlain);
          if (data?.text != null) widget.textCtrl.text = data!.text!;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: c.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.textPrimary.withValues(alpha: 0.07)),
          ),
          child: Row(children: [
            Icon(Icons.content_paste_rounded, color: c.textMuted, size: 16),
            const SizedBox(width: 8),
            Text('Вставить из буфера обмена', style: TextStyle(fontSize: 12, color: c.textSecondary)),
          ]),
        ),
      ),
      if (widget.source == _ImportSource.text) ...[
        const SizedBox(height: 8),
        _ExamplesHint(colors: c),
      ],
      const SizedBox(height: 24),
      ListenableBuilder(
        listenable: widget.textCtrl,
        builder: (_, __) => _ActionButton(
          colors: c,
          label: 'Скорректировать план с AI',
          icon: Icons.auto_fix_high_rounded,
          onTap: widget.textCtrl.text.trim().isEmpty
              ? null
              : () => widget.onSubmitText(widget.textCtrl.text),
        ),
      ),
    ],
  );

  Widget _buildFileWait(dynamic c) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.folder_open_rounded, size: 56, color: c.textMuted.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        Text('Открывается файловый менеджер...', style: TextStyle(fontSize: 14, color: c.textMuted)),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: widget.onPickFile,
          icon: Icon(Icons.upload_file_rounded, size: 18, color: c.primary),
          label: Text('Выбрать файл снова', style: TextStyle(color: c.primary)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: c.primary.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Text('Поддерживаются: .json  .txt  .csv', style: TextStyle(fontSize: 12, color: c.textMuted)),
      ]),
    ),
  );

  static String _title(_ImportSource src) => switch (src) {
    _ImportSource.text       => 'Ваше пожелание',
    _ImportSource.url        => 'Ссылка на программу',
    _ImportSource.file       => 'Из файла',
    _ImportSource.qr         => 'QR-код',
    _ImportSource.sharedApp  => 'Вставить тренировку',
    _ImportSource.postWorkout => 'Анализ тренировки',
  };
}

// ─── Examples hint (for text input) ──────────────────────────────────────────

class _ExamplesHint extends StatelessWidget {
  final dynamic colors;
  const _ExamplesHint({required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.info.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.info.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Примеры запросов:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.info)),
        const SizedBox(height: 6),
        for (final ex in [
          '"Замени жим штанги на жим гантелей — болят запястья"',
          '"Хочу больше упражнений на ноги и ягодицы"',
          '"Убери кардио, я бегаю отдельно"',
          '"Добавь суперсеты для плеч и трицепса"',
          '"Уменьши интенсивность — я только начинаю"',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 4, height: 4, margin: const EdgeInsets.only(top: 5, right: 6),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.info)),
              Expanded(child: Text(ex, style: TextStyle(fontSize: 11, color: c.textMuted, height: 1.4))),
            ]),
          ),
      ]),
    );
  }
}

// ─── Parsing view ─────────────────────────────────────────────────────────────

class _ParsingView extends StatelessWidget {
  final dynamic colors;
  const _ParsingView({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 52, height: 52,
            child: CircularProgressIndicator(strokeWidth: 3, color: colors.primary),
          ),
          const SizedBox(height: 24),
          Text('AI корректирует план...',
              style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Анализирую запрос и вношу изменения в ваш план',
              style: TextStyle(fontSize: 13, color: colors.textMuted),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ─── Preview ──────────────────────────────────────────────────────────────────

class _PreviewView extends StatelessWidget {
  final dynamic colors;
  final Map<String, dynamic> plan;
  final List<String> changes;
  final String reasoning;
  final bool saving;
  final ScrollController scrollCtrl;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _PreviewView({
    super.key,
    required this.colors,
    required this.plan,
    required this.changes,
    required this.reasoning,
    required this.saving,
    required this.scrollCtrl,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final days = (plan['plan'] as List? ?? []).cast<Map<String, dynamic>>();
    final totalEx = days.fold<int>(0, (s, d) => s + ((d['exercises'] as List?)?.length ?? 0));
    final recs = (plan['recommendations'] as List? ?? []).cast<String>();

    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // ── Result badge ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.primary.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(Icons.auto_fix_high_rounded, color: c.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('План скорректирован',
                  style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w800, color: c.textPrimary)),
              Text('${days.length} дней · $totalEx упражнений · ${changes.length} изм.',
                  style: TextStyle(fontSize: 12, color: c.textMuted)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Changes list (most important!) ──
        if (changes.isNotEmpty) ...[
          Text('Внесённые изменения',
              style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary)),
          const SizedBox(height: 10),
          ...changes.map((ch) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.primary.withValues(alpha: 0.12)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 6, height: 6,
                margin: const EdgeInsets.only(top: 5, right: 10),
                decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
              ),
              Expanded(child: Text(ch, style: TextStyle(fontSize: 12, color: c.textSecondary, height: 1.45))),
            ]),
          )),
          const SizedBox(height: 6),
        ],

        // ── AI reasoning ──
        if (reasoning.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.accentPurple.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.accentPurple.withValues(alpha: 0.18)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.psychology_rounded, color: c.accentPurple, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Логика AI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.accentPurple)),
                const SizedBox(height: 3),
                Text(reasoning, style: TextStyle(fontSize: 11, color: c.textMuted, height: 1.4)),
              ])),
            ]),
          ),
          const SizedBox(height: 12),
        ],

        // ── Updated plan overview ──
        Text('Обновлённый план',
            style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary)),
        const SizedBox(height: 10),
        ...days.asMap().entries.map((e) {
          final i = e.key;
          final day = e.value;
          const dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
          final label = i < dayLabels.length ? dayLabels[i] : 'День ${i+1}';
          final focus = day['focus'] as String? ?? day['name'] as String? ?? 'День ${i+1}';
          final exercises = (day['exercises'] as List? ?? []).cast<Map<String, dynamic>>();
          final isRest = exercises.isEmpty ||
              focus.toLowerCase().contains('отдых') ||
              (day['type'] as String? ?? '') == 'rest';
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.textPrimary.withValues(alpha: 0.06)),
            ),
            child: Row(children: [
              Text(isRest ? '😴' : '💪', style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textMuted)),
              const SizedBox(width: 6),
              Expanded(child: Text(focus,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textSecondary),
                  overflow: TextOverflow.ellipsis)),
              if (!isRest)
                Text('${exercises.length} упр.', style: TextStyle(fontSize: 11, color: c.textMuted)),
            ]),
          );
        }),

        // ── Recommendations ──
        if (recs.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.info.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.info.withValues(alpha: 0.15)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Рекомендации', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.info)),
              const SizedBox(height: 6),
              for (final r in recs.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 4, height: 4, margin: const EdgeInsets.only(top: 5, right: 6),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: c.info)),
                    Expanded(child: Text(r, style: TextStyle(fontSize: 11, color: c.textMuted, height: 1.4))),
                  ]),
                ),
            ]),
          ),
        ],

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.accentOrange.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.accentOrange.withValues(alpha: 0.2)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.warning_amber_rounded, color: c.accentOrange, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('Это заменит ваш текущий план тренировок.',
                style: TextStyle(fontSize: 11, color: c.textMuted))),
          ]),
        ),
        const SizedBox(height: 16),
        _ActionButton(
          colors: c,
          label: saving ? 'Сохраняем...' : 'Применить изменения',
          icon: saving ? null : Icons.check_rounded,
          loading: saving,
          onTap: saving ? null : onSave,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: saving ? null : onCancel,
          child: Text('Отмена', style: TextStyle(color: c.textMuted, fontSize: 14)),
        ),
      ],
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final dynamic colors;
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({super.key, required this.colors, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline_rounded, size: 56, color: c.error.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text(AppLocalizations.tl('errorTitle'), style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),

          _ActionButton(colors: c, label: AppLocalizations.tl('tryAgainBtn'), icon: Icons.refresh_rounded, onTap: onRetry),
        ]),
      ),
    );
  }
}

// ─── Shared action button ─────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final dynamic colors;
  final String label;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.colors,
    required this.label,
    this.icon,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final enabled = onTap != null && !loading;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(colors: [c.primary, c.primary.withValues(alpha: 0.75)],
                  begin: Alignment.centerLeft, end: Alignment.centerRight)
              : null,
          color: enabled ? null : c.textMuted.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [BoxShadow(color: c.primary.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 5))]
              : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (loading)
            SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: c.textOnPrimary))
          else if (icon != null)
            Icon(icon, color: enabled ? c.textOnPrimary : c.textMuted, size: 18),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w700,
                color: enabled ? c.textOnPrimary : c.textMuted,
              )),
        ]),
      ),
    );
  }
}
