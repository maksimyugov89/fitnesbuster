import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/core/ai/ai_exception.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/core/constants/app_colors.dart';

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
          _runCorrection(
            widget.initialContent!,
            AppLocalizations.tl('sourceHintPostWorkout'),
          );
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
    setState(() {
      _step = _ImportStep.parsing;
      _errorMsg = null;
    });
    try {
      final service = sl<IDeepSeekService>();
      final authState = context.read<AuthBloc>().state;
      final uid = authState is AuthStateAuthenticated ? authState.userId : null;

      String jsonStr;
      if (uid != null) {
        final plans = await sl<IUserRepository>().getAiPlans(uid);
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
      setState(() {
        _errorMsg = e.message;
        _step = _ImportStep.error;
      });
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
    setState(() {
      _step = _ImportStep.parsing;
      _errorMsg = null;
    });
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      final resp = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'Mozilla/5.0 (compatible; FitnesBuster/1.0)',
            },
          )
          .timeout(const Duration(seconds: 15));
      String body = resp.body
          .replaceAll(
            RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false),
            '',
          )
          .replaceAll(
            RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false),
            '',
          )
          .replaceAll(RegExp(r'<[^>]+>'), ' ')
          .replaceAll(RegExp(r'\s{2,}'), ' ')
          .trim();
      if (body.length > 8000) body = body.substring(0, 8000);
      await _runCorrection(
        'URL: $url\n\n$body',
        '${AppLocalizations.tl("sourceHintLink")}: $url',
      );
    } on SocketException {
      setState(() {
        _errorMsg = AppLocalizations.tl('networkError');
        _step = _ImportStep.error;
      });
    } catch (e) {
      setState(() {
        _errorMsg = AppLocalizations.tl('pageLoadError');
        _step = _ImportStep.error;
      });
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
        setState(() {
          _errorMsg = AppLocalizations.tl('fileReadError');
          _step = _ImportStep.error;
        });
        return;
      }
    } catch (e) {
      setState(() {
        _errorMsg = AppLocalizations.tl('fileOpenError');
        _step = _ImportStep.error;
      });
    }
  }

  // ── Clipboard ─────────────────────────────────────────────────────────────

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.tl('clipboardEmpty')),
            duration: const Duration(seconds: 2),
          ),
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
      final authState = context.read<AuthBloc>().state;
      final uid = authState is AuthStateAuthenticated ? authState.userId : null;
      if (uid == null) throw Exception(AppLocalizations.tl('notAuthorized'));
      final repo = sl<IUserRepository>();
      final planData = _correctedPlan!;
      final workoutPlanJson = jsonEncode(planData);
      await repo.updateWorkoutPlan(
        userId: uid,
        workoutPlanJson: workoutPlanJson,
      );
    } catch (e) {
      setState(() {
        _saving = false;
        _errorMsg = AppLocalizations.tl('planSaveFailed');
        _step = _ImportStep.error;
      });
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

  void _back() => setState(
    () => _step == _ImportStep.enterContent
        ? _step = _ImportStep.selectSource
        : _reset(),
  );

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isQr =
        _step == _ImportStep.enterContent && _source == _ImportSource.qr;
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
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
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
          ],
        ),
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
          setState(() {
            _source = source;
          });
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
          final isUrl =
              value.startsWith('http://') || value.startsWith('https://');
          if (isUrl) {
            _urlCtrl.text = value;
            _fetchUrl();
          } else {
            _runCorrection(value, AppLocalizations.tl('sourceHintQr'));
          }
        },
      ),
      _ImportStep.parsing => _ParsingView(
        key: const ValueKey('parsing'),
        colors: colors,
      ),
      _ImportStep.preview => _PreviewView(
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
    _ImportSource.text => AppLocalizations.tl('sourceHintPreference'),
    _ImportSource.url => AppLocalizations.tl('sourceHintLink'),
    _ImportSource.file => AppLocalizations.tl('sourceHintFile'),
    _ImportSource.qr => AppLocalizations.tl('sourceHintQr'),
    _ImportSource.sharedApp => AppLocalizations.tl('sourceHintOtherApp'),
    _ImportSource.postWorkout => AppLocalizations.tl('sourceHintPostWorkout'),
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppIcon(
                asset: AppImages.aiAssistant,
                glowColor: c.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).correctPlan,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).aiAdaptsPlanHint,
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // AI analysis hint
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(
                asset: AppImages.aiAssistant,
                glowColor: c.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).aiDeepSeekHint,
                  style: TextStyle(
                    fontSize: 11,
                    color: c.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _OptionCard(
          colors: c,
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: SemanticColors.importSuccess,
          title: AppLocalizations.of(context).writeWishOption,
          subtitle: AppLocalizations.of(context).writeWishSubtitle,
          onTap: () => onSelected(_ImportSource.text),
        ),
        const SizedBox(height: 10),
        _OptionCard(
          colors: c,
          icon: Icons.link_rounded,
          iconColor: SemanticColors.importWarning,
          title: AppLocalizations.of(context).addFromInternet,
          subtitle: AppLocalizations.of(context).addFromInternetSubtitle,
          onTap: () => onSelected(_ImportSource.url),
        ),
        const SizedBox(height: 10),
        _OptionCard(
          colors: c,
          icon: Icons.content_paste_rounded,
          iconColor: SemanticColors.importInfo,
          title: AppLocalizations.of(context).pasteClipboard,
          subtitle: AppLocalizations.of(context).pasteClipboardSubtitle,
          onTap: () => onSelected(_ImportSource.sharedApp),
        ),
        const SizedBox(height: 10),
        _OptionCard(
          colors: c,
          icon: Icons.insert_drive_file_rounded,
          iconColor: SemanticColors.importFlex,
          title: AppLocalizations.of(context).uploadFileOption,
          subtitle: AppLocalizations.of(context).uploadFileSubtitle,
          onTap: () => onSelected(_ImportSource.file),
        ),
        const SizedBox(height: 10),
        _OptionCard(
          colors: c,
          icon: Icons.qr_code_scanner_rounded,
          iconAsset: AppImages.barcodeScanner,
          iconColor: SemanticColors.importError,
          title: AppLocalizations.of(context).scanQr,
          subtitle: AppLocalizations.of(context).scanQrSubtitle,
          onTap: () => onSelected(_ImportSource.qr),
        ),
        const SizedBox(height: 10),
        _OptionCard(
          colors: c,
          icon: Icons.share_rounded,
          iconColor: SemanticColors.importWater,
          title: AppLocalizations.of(context).shareFromApp,
          subtitle: AppLocalizations.of(context).shareFromAppSubtitle,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              AppLocalizations.of(context).autoLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: c.primary,
              ),
            ),
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
  final String? iconAsset;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _OptionCard({
    required this.colors,
    required this.icon,
    this.iconAsset,
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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: iconAsset != null
                  ? AppIcon(asset: iconAsset!, glowColor: iconColor, size: 20)
                  : Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: colors.textMuted,
              ),
          ],
        ),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: c.textMuted,
                  size: 20,
                ),
              ),
              Expanded(
                child: Text(
                  _title(widget.source),
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildBody(c)),
      ],
    );
  }

  Widget _buildBody(dynamic c) => switch (widget.source) {
    _ImportSource.qr => _buildQr(c),
    _ImportSource.url => _buildUrl(c),
    _ImportSource.file => _buildFileWait(c),
    _ => _buildText(c),
  };

  Widget _buildQr(dynamic c) => Column(
    children: [
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
          widget.qrScanned
              ? AppLocalizations.of(context).qrScannedAnalyzing
              : AppLocalizations.of(context).qrPointCamera,
          style: TextStyle(fontSize: 13, color: c.textMuted),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );

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
        child: Row(
          children: [
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
          ],
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in [
            'YouTube',
            'Strava',
            'Hevy',
            'Garmin',
            'GymShark',
            'Reddit',
            AppLocalizations.of(context).anySiteLabel,
          ])
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: c.textPrimary.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                s,
                style: TextStyle(fontSize: 11, color: c.textMuted),
              ),
            ),
        ],
      ),
      const SizedBox(height: 24),
      _ActionButton(
        colors: c,
        label: AppLocalizations.of(context).loadAndCorrectPlanBtn,
        iconAsset: AppImages.aiAssistant,
        onTap: widget.onSubmitUrl,
      ),
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
                ? AppLocalizations.of(context).writeWishHint
                : AppLocalizations.of(context).pasteWorkoutHint,
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
          child: Row(
            children: [
              Icon(Icons.content_paste_rounded, color: c.textMuted, size: 16),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).pasteFromClipboard,
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
            ],
          ),
        ),
      ),
      if (widget.source == _ImportSource.text) ...[
        const SizedBox(height: 8),
        _ExamplesHint(colors: c),
      ],
      const SizedBox(height: 24),
      ListenableBuilder(
        listenable: widget.textCtrl,
        builder: (_, _) => _ActionButton(
          colors: c,
          label: AppLocalizations.of(context).correctPlanWithAiBtn,
          iconAsset: AppImages.aiAssistant,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 56,
            color: c.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).openingFilePicker,
            style: TextStyle(fontSize: 14, color: c.textMuted),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: widget.onPickFile,
            icon: Icon(Icons.upload_file_rounded, size: 18, color: c.primary),
            label: Text(
              AppLocalizations.of(context).selectFileAgain,
              style: TextStyle(color: c.primary),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: c.primary.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).supportedFormatsHint,
            style: TextStyle(fontSize: 12, color: c.textMuted),
          ),
        ],
      ),
    ),
  );

  static String _title(_ImportSource src) => switch (src) {
    _ImportSource.text => AppLocalizations.tl('yourWishTitle'),
    _ImportSource.url => AppLocalizations.tl('programLinkTitle'),
    _ImportSource.file => AppLocalizations.tl('fromFileTitle'),
    _ImportSource.qr => AppLocalizations.tl('qrCodeTitle'),
    _ImportSource.sharedApp => AppLocalizations.tl('pasteWorkoutTitle'),
    _ImportSource.postWorkout => AppLocalizations.tl('workoutAnalysisTitle'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).exampleRequestsLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.info,
            ),
          ),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 5, right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.info,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      ex,
                      style: TextStyle(
                        fontSize: 11,
                        color: c.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).aiCorrectingPlan,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).aiAnalyzingQuery,
              style: TextStyle(fontSize: 13, color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
    final totalEx = days.fold<int>(
      0,
      (s, d) => s + ((d['exercises'] as List?)?.length ?? 0),
    );
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
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  asset: AppImages.aiAssistant,
                  glowColor: c.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).planCorrectedTitle,
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).planCorrectedSummary(
                        '${days.length}',
                        '$totalEx',
                        '${changes.length}',
                      ),
                      style: TextStyle(fontSize: 12, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Changes list (most important!) ──
        if (changes.isNotEmpty) ...[
          Text(
            AppLocalizations.of(context).changesTitle,
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...changes.map(
            (ch) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.primary.withValues(alpha: 0.12)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 5, right: 10),
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      ch,
                      style: TextStyle(
                        fontSize: 12,
                        color: c.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(
                  asset: AppImages.aiAssistant,
                  glowColor: c.accentPurple,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).aiLogicTitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: c.accentPurple,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        reasoning,
                        style: TextStyle(
                          fontSize: 11,
                          color: c.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Updated plan overview ──
        Text(
          AppLocalizations.of(context).updatedPlanTitle,
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ...days.asMap().entries.map((e) {
          final i = e.key;
          final day = e.value;
          final l10n = AppLocalizations.of(context);
          final dayLabels = [
            l10n.monShort,
            l10n.tueShort,
            l10n.wedShort,
            l10n.thuShort,
            l10n.friShort,
            l10n.satShort,
            l10n.sunShort,
          ];
          final label = i < dayLabels.length
              ? dayLabels[i]
              : l10n.dayLabel(i + 1);
          final focus =
              day['focus'] as String? ??
              day['name'] as String? ??
              l10n.dayLabel(i + 1);
          final exercises = (day['exercises'] as List? ?? [])
              .cast<Map<String, dynamic>>();
          final isRest =
              exercises.isEmpty ||
              focus.toLowerCase().contains(
                AppLocalizations.tl('restDayKeyword'),
              ) ||
              (day['type'] as String? ?? '') == 'rest';
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.textPrimary.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Image.asset(
                  isRest ? AppImages.sleep : AppImages.workoutsTab,
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    focus,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isRest)
                  Text(
                    l10n.exercisesShortCount('${exercises.length}'),
                    style: TextStyle(fontSize: 11, color: c.textMuted),
                  ),
              ],
            ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).weeklyRecsTitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: c.info,
                  ),
                ),
                const SizedBox(height: 6),
                for (final r in recs.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 5, right: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.info,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            r,
                            style: TextStyle(
                              fontSize: 11,
                              color: c.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: c.accentOrange,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).planReplacementWarning,
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ActionButton(
          colors: c,
          label: saving
              ? AppLocalizations.of(context).savingLabel
              : AppLocalizations.of(context).applyChangesBtn,
          icon: saving ? null : Icons.check_rounded,
          loading: saving,
          onTap: saving ? null : onSave,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: saving ? null : onCancel,
          child: Text(
            AppLocalizations.of(context).cancel,
            style: TextStyle(color: c.textMuted, fontSize: 14),
          ),
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
  const _ErrorView({
    super.key,
    required this.colors,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: c.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.tl('errorTitle'),
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),

            _ActionButton(
              colors: c,
              label: AppLocalizations.tl('tryAgainBtn'),
              icon: Icons.refresh_rounded,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared action button ─────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final dynamic colors;
  final String label;
  final IconData? icon;
  final String? iconAsset;
  final bool loading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.colors,
    required this.label,
    this.icon,
    this.iconAsset,
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
              ? LinearGradient(
                  colors: [c.primary, c.primary.withValues(alpha: 0.75)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: enabled ? null : c.textMuted.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.textOnPrimary,
                ),
              )
            else if (iconAsset != null)
              Opacity(
                opacity: enabled ? 1 : 0.5,
                child: AppIcon(asset: iconAsset!, size: 18),
              )
            else if (icon != null)
              Icon(
                icon,
                color: enabled ? c.textOnPrimary : c.textMuted,
                size: 18,
              ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: enabled ? c.textOnPrimary : c.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
