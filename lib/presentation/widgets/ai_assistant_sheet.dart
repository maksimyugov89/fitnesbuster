import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitnesbuster/bloc/ai/ai_bloc.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';

/// AI Assistant chat bottom sheet.
class AiAssistantSheet extends StatefulWidget {
  const AiAssistantSheet({super.key});

  @override
  State<AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<AiAssistantSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
    });
    _controller.clear();
    context.read<AiBloc>().add(AiAskQuestion(question: text));
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return BlocListener<AiBloc, AiState>(
      listener: (context, state) {
        if (state is AiStateLoaded) {
          setState(() {
            _messages.add(_ChatMessage(text: state.result, isUser: false));
          });
          _scrollToBottom();
        } else if (state is AiStateError) {
          setState(() {
            _messages.add(
              _ChatMessage(text: '❌ ${state.message}', isUser: false),
            );
          });
          _scrollToBottom();
        }
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('AI Ассистент', style: AppTextStyles.titleL),
              const SizedBox(height: 4),
              Text(
                'Ваш AI помощник по фитнесу',
                style: TextStyle(fontSize: 13, color: colors.textMuted),
              ),
              const SizedBox(height: 16),
              Divider(color: colors.surfaceLight, height: 1),

              // Messages
              Flexible(
                child: _messages.isEmpty
                    ? _buildQuickActions()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) =>
                            _buildMessageBubble(_messages[i]),
                      ),
              ),

              // Loading indicator
              BlocBuilder<AiBloc, AiState>(
                builder: (context, state) {
                  if (state is AiStateLoading) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Думаю...',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Input field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (v) {
                          _sendMessage(v);
                          _scrollToBottom();
                        },
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Задай вопрос...',
                          hintStyle: TextStyle(color: colors.textMuted),
                          filled: true,
                          fillColor: colors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    BlocBuilder<AiBloc, AiState>(
                      builder: (context, state) {
                        final isLoading = state is AiStateLoading;
                        return Semantics(
                          label: 'Отправить',
                          button: true,
                          child: GestureDetector(
                            onTap: isLoading
                                ? null
                                : () {
                                    _sendMessage(_controller.text);
                                    _scrollToBottom();
                                  },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isLoading
                                    ? colors.surfaceLight
                                    : colors.primary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isLoading
                                    ? Icons.hourglass_empty
                                    : Icons.send_rounded,
                                color: isLoading
                                    ? colors.textMuted
                                    : colors.textOnPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final colors = AppTheme.of(context);
    final suggestions = [
      (AppImages.workoutsTab, 'Как часто тренироваться новичку?'),
      (AppImages.vegetables, 'Что съесть после тренировки?'),
      (AppImages.sleep, 'Сколько нужно спать?'),
      (AppImages.energy, 'Как ускорить метаболизм?'),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Быстрые вопросы',
            style: TextStyle(
              fontSize: 13,
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Semantics(
                label: s.$2,
                button: true,
                child: GestureDetector(
                  onTap: () {
                    _sendMessage(s.$2);
                    _scrollToBottom();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colors.textPrimary.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Image.asset(s.$1, width: 24, height: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s.$2,
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: colors.textMuted,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final colors = AppTheme.of(context);
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: msg.isUser ? colors.primary : colors.surfaceCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'FitnesBuster AI',
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 14,
                color: msg.isUser ? colors.textOnPrimary : colors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  const _ChatMessage({required this.text, required this.isUser});
}
