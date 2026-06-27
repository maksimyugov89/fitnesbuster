import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/core/ai/deepseek_service.dart' show AiException;
import 'package:fitnesbuster/core/cache/hive_cache.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _uid;
  UserProfile? _profile;

  static const _welcomeText =
      'Привет! Я твой персональный AI-тренер FitnesBuster 💪\n\n'
      'Задавай вопросы о тренировках, питании, восстановлении и прогрессе — '
      'отвечу конкретно с учётом твоего профиля.';

  static const _suggestions = [
    'Как ускорить восстановление после тренировки?',
    'Что есть до и после тренировки?',
    'Сколько белка мне нужно в день?',
    'Как правильно делать приседания со штангой?',
  ];

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    _uid = authState is AuthStateAuthenticated ? authState.user.id : null;
    _loadProfile();
    _loadHistory();
  }

  void _loadProfile() {
    final state = context.read<AuthBloc>().state;
    if (state is AuthStateAuthenticated) {
      _profile = state.user.profile;
    }
  }

  void _loadHistory() {
    if (_uid == null) return;
    setState(() => _messages = HiveCache.getChatHistory(_uid!));
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottom(animate: false));
  }

  Future<void> _saveHistory() async {
    if (_uid == null) return;
    await HiveCache.saveChatHistory(_uid!, _messages);
  }

  Future<void> _clearHistory() async {
    if (_uid == null) return;
    await HiveCache.clearChatHistory(_uid!);
    if (mounted) setState(() => _messages = []);
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollCtrl.hasClients) return;
    if (animate) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    }
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _ctrl.clear();
    final historySnapshot = List<ChatMessage>.from(_messages);
    final userMsg = ChatMessage(
      role: 'user',
      content: trimmed,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    await _saveHistory();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottom());

    try {
      final response = await sl<IDeepSeekService>().askWithHistory(
        historySnapshot,
        trimmed,
        profile: _profile,
      );
      final aiMsg = ChatMessage(
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
      );
      if (mounted) {
        setState(() {
          _messages.add(aiMsg);
          _isLoading = false;
        });
        await _saveHistory();
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());
      }
    } on AiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _confirmClear() async {
    final colors = AppTheme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surfaceCard,
        title: Text(
          'Очистить историю?',
          style: TextStyle(
              color: colors.textPrimary,
              fontFamily: 'Syne',
              fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Все сообщения будут удалены.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Отмена', style: TextStyle(color: colors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Очистить',
                style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _clearHistory();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI-тренер',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            Text(
              'Персональный фитнес-эксперт',
              style: TextStyle(fontSize: 11, color: colors.textMuted),
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  color: colors.textMuted, size: 22),
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount:
                  _messages.length + 1 + (_isLoading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return _WelcomeBubble(
                    text: _welcomeText,
                    showSuggestions:
                        _messages.isEmpty && !_isLoading,
                    suggestions: _suggestions,
                    onSuggestion: _send,
                    colors: colors,
                  );
                }
                if (_isLoading && i == _messages.length + 1) {
                  return _TypingBubble(colors: colors);
                }
                return _MessageBubble(
                  message: _messages[i - 1],
                  colors: colors,
                );
              },
            ),
          ),
          _InputBar(
            ctrl: _ctrl,
            focusNode: _focusNode,
            isLoading: _isLoading,
            onSend: _send,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

// ─── Welcome bubble ───────────────────────────────────────────────────────────

class _WelcomeBubble extends StatelessWidget {
  final String text;
  final bool showSuggestions;
  final List<String> suggestions;
  final ValueChanged<String> onSuggestion;
  final ThemePalette colors;

  const _WelcomeBubble({
    required this.text,
    required this.showSuggestions,
    required this.suggestions,
    required this.onSuggestion,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _AiAvatar(colors: colors),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                    ),
                    border: Border.all(
                        color: colors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        height: 1.5),
                  ),
                ),
              ),
            ],
          ),
          if (showSuggestions) ...[
            const SizedBox(height: 16),
            Text(
              'Попробуй спросить:',
              style: TextStyle(
                  fontSize: 12,
                  color: colors.textMuted,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions
                  .map((s) => GestureDetector(
                        onTap: () => onSuggestion(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: colors.primary
                                    .withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            s,
                            style: TextStyle(
                                color: colors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ThemePalette colors;

  const _MessageBubble(
      {required this.message, required this.colors});

  bool get _isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isUser) ...[
            _AiAvatar(colors: colors),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    _isUser ? colors.primary : colors.surfaceCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft:
                      Radius.circular(_isUser ? 18 : 4),
                  bottomRight:
                      Radius.circular(_isUser ? 4 : 18),
                ),
                border: _isUser
                    ? null
                    : Border.all(
                        color:
                            Colors.white.withValues(alpha: 0.06)),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: _isUser
                      ? colors.textOnPrimary
                      : colors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (_isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  final ThemePalette colors;
  const _TypingBubble({required this.colors});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  double _dotOpacity(int index, double t) {
    final offset = (t + index * 0.33) % 1.0;
    return 0.25 + 0.75 * (0.5 + 0.5 * sin(offset * 2 * pi));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _AiAvatar(colors: widget.colors),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: widget.colors.surfaceCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return Padding(
                    padding:
                        EdgeInsets.only(right: i < 2 ? 5.0 : 0),
                    child: Opacity(
                      opacity: _dotOpacity(i, _anim.value),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: widget.colors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final bool isLoading;
  final ValueChanged<String> onSend;
  final ThemePalette colors;

  const _InputBar({
    required this.ctrl,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding:
          EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
            top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              focusNode: focusNode,
              enabled: !isLoading,
              textInputAction: TextInputAction.send,
              onSubmitted: onSend,
              maxLines: 4,
              minLines: 1,
              style:
                  TextStyle(color: colors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Задать вопрос...',
                hintStyle: TextStyle(
                    color: colors.textMuted, fontSize: 15),
                filled: true,
                fillColor: colors.surfaceCard,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isLoading ? null : () => onSend(ctrl.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isLoading
                    ? colors.surfaceLight
                    : colors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLoading
                    ? Icons.hourglass_empty_rounded
                    : Icons.send_rounded,
                color: isLoading
                    ? colors.textMuted
                    : colors.textOnPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared AI avatar ─────────────────────────────────────────────────────────

class _AiAvatar extends StatelessWidget {
  final ThemePalette colors;
  const _AiAvatar({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'AI',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white),
        ),
      ),
    );
  }
}
