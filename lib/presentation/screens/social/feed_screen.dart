import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/services/social_service.dart';
import 'package:fitnesbuster/presentation/widgets/loading_shimmer.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.arrow_back_rounded, color: colors.textPrimary, size: 20),
          ),
        ),
        title: const Text('Лента друзей', style: AppTextStyles.titleL),
      ),
      body: StreamBuilder<List<FeedEvent>>(
        stream: sl<SocialService>().feedStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: LoadingShimmer.listView(5));
          }
          final events = snap.data ?? [];
          if (events.isEmpty) {
            return _buildEmpty(colors);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _FeedCard(event: events[i], colors: colors),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(ThemePalette colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('👥', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('Лента пуста', style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text('Добавь друзей, чтобы видеть\nих тренировки и достижения', style: TextStyle(fontSize: 13, color: colors.textMuted), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final FeedEvent event;
  final ThemePalette colors;
  const _FeedCard({required this.event, required this.colors});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин. назад';
    if (diff.inHours < 24)   return '${diff.inHours} ч. назад';
    if (diff.inDays < 7)     return '${diff.inDays} дн. назад';
    return DateFormat('d MMM', 'ru').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              event.fromName.isNotEmpty ? event.fromName[0].toUpperCase() : '?',
              style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w800, color: colors.primary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: TextSpan(
            style: TextStyle(fontSize: 14, color: colors.textPrimary),
            children: [
              TextSpan(text: event.fromName, style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: ' ${event.description}'),
            ],
          )),
          const SizedBox(height: 4),
          Text(_timeAgo(event.timestamp), style: TextStyle(fontSize: 11, color: colors.textMuted)),
        ])),
        const SizedBox(width: 8),
        Text(event.emoji, style: const TextStyle(fontSize: 24)),
      ]),
    );
  }
}
