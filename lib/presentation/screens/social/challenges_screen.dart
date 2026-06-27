import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/services/social_service.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

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
        title: Text('Челленджи', style: AppTextStyles.titleL),
        actions: const [],
        bottom: TabBar(
          controller: _tabs,
          indicator: BoxDecoration(color: colors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          indicatorPadding: const EdgeInsets.all(4),
          labelColor: colors.primary,
          unselectedLabelColor: colors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: const [Tab(text: 'Мои'), Tab(text: 'Публичные')],
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildMyChallenges(colors),
          _buildPublicChallenges(colors),
        ],
      ),
    );
  }

  Widget _buildMyChallenges(ThemePalette colors) {
    return StreamBuilder<List<Challenge>>(
      stream: sl<SocialService>().myChallengesStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final challenges = snap.data ?? [];
        if (challenges.isEmpty) {
          return _buildEmpty(colors, 'Нет активных челленджей', 'Создай свой или присоединись к публичному');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          itemCount: challenges.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _ChallengeCard(
            challenge: challenges[i],
            colors: colors,
            showLeaderboard: true,
          ),
        );
      },
    );
  }

  Widget _buildPublicChallenges(ThemePalette colors) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<List<Challenge>>(
      stream: sl<SocialService>().publicChallengesStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data ?? [];
        if (all.isEmpty) {
          return _buildEmptyPublic(colors);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          itemCount: all.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final isParticipant = all[i].participants.contains(myUid);
            return _ChallengeCard(
              challenge: all[i],
              colors: colors,
              showJoinButton: !isParticipant,
              isParticipant: isParticipant,
            );
          },
        );
      },
    );
  }

  Widget _buildEmpty(ThemePalette colors, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('⚡', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 13, color: colors.textMuted), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildEmptyPublic(ThemePalette colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🏆', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('Нет публичных челленджей', style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text('Нажмите кнопку ниже чтобы загрузить стандартные челленджи', style: TextStyle(fontSize: 13, color: colors.textMuted), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _seedChallenges(colors),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(12)),
              child: Text('Загрузить челленджи', style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w700, color: colors.textOnPrimary)),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _seedChallenges(ThemePalette colors) async {
    try {
      await sl<SocialService>().seedChallenges();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Челленджи добавлены!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.tl('genericErrorMsg').replaceAll('{error}', e.toString()))),
        );
      }
    }
  }
}

// ── Challenge card ─────────────────────────────────────────────────────────────

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final ThemePalette colors;
  final bool showJoinButton;
  final bool showLeaderboard;
  final bool isParticipant;

  const _ChallengeCard({
    required this.challenge,
    required this.colors,
    this.showJoinButton = false,
    this.showLeaderboard = false,
    this.isParticipant = false,
  });

  String get _goalEmoji => challenge.emoji.isNotEmpty ? challenge.emoji : '🎯';

  Color get _statusColor {
    if (!challenge.isActive) return Colors.grey;
    final daysLeft = challenge.endDate.difference(DateTime.now()).inDays;
    if (daysLeft <= 2) return const Color(0xFFFF4466);
    if (daysLeft <= 5) return const Color(0xFFF5A623);
    return const Color(0xFF22D3A5);
  }

  String get _daysLabel {
    if (!challenge.isActive) return 'Завершён';
    final d = challenge.endDate.difference(DateTime.now()).inDays;
    return d == 0 ? 'Последний день!' : 'Осталось $d дн.';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: showLeaderboard ? () => _openLeaderboard(context) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(_goalEmoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(challenge.title, style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w800, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('от ${challenge.creatorName}', style: TextStyle(fontSize: 11, color: colors.textMuted)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(_daysLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _Stat(label: 'Цель', value: '${challenge.targetValue} ${challenge.goalLabel}', colors: colors)),
            Expanded(child: _Stat(label: 'Участники', value: '${challenge.participants.length}', colors: colors)),
            Expanded(child: _Stat(label: 'Длительность', value: '${challenge.durationDays} дн.', colors: colors)),
          ]),
          if (challenge.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(challenge.description, style: TextStyle(fontSize: 12, color: colors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (isParticipant) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: colors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text('✓ Вы участвуете', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.success))),
            ),
          ] else if (showJoinButton) ...[
            const SizedBox(height: 12),
            _JoinButton(challengeId: challenge.id, colors: colors),
          ],
          if (showLeaderboard) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.leaderboard_rounded, size: 12, color: colors.textMuted),
              const SizedBox(width: 4),
              Text('Таблица лидеров →', style: TextStyle(fontSize: 11, color: colors.textMuted)),
            ]),
          ],
        ]),
      ),
    );
  }

  void _openLeaderboard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LeaderboardSheet(challenge: challenge, colors: colors),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final ThemePalette colors;
  const _Stat({required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, color: colors.textMuted)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
    ]);
  }
}

class _JoinButton extends StatefulWidget {
  final String challengeId;
  final ThemePalette colors;
  const _JoinButton({required this.challengeId, required this.colors});

  @override
  State<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends State<_JoinButton> {
  bool _loading = false;
  bool _joined = false;

  @override
  Widget build(BuildContext context) {
    if (_joined) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: widget.colors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text('✓ Вы участвуете!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: widget.colors.success))),
      );
    }
    return GestureDetector(
      onTap: _loading ? null : _join,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: widget.colors.primary, borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: _loading
              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: widget.colors.textOnPrimary))
              : Text('Присоединиться', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: widget.colors.textOnPrimary)),
        ),
      ),
    );
  }

  Future<void> _join() async {
    setState(() => _loading = true);
    try {
      await sl<SocialService>().joinChallenge(widget.challengeId);
      if (mounted) setState(() { _loading = false; _joined = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.tl('genericErrorMsg').replaceAll('{error}', e.toString()))));
      }
    }
  }
}

// ── Leaderboard sheet ──────────────────────────────────────────────────────────

class _LeaderboardSheet extends StatelessWidget {
  final Challenge challenge;
  final ThemePalette colors;
  const _LeaderboardSheet({required this.challenge, required this.colors});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Text('🏆', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(child: Text(challenge.title, style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Цель: ${challenge.targetValue} ${challenge.goalLabel}', style: TextStyle(fontSize: 12, color: colors.textMuted)),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<List<ChallengeParticipant>>(
            stream: sl<SocialService>().challengeLeaderboardStream(challenge.id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final participants = snap.data ?? [];
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: participants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = participants[i];
                  final isMe = p.uid == myUid;
                  final progress = (p.currentValue / challenge.targetValue).clamp(0.0, 1.0);
                  final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '${i + 1}.';
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? colors.primary.withValues(alpha: 0.08) : colors.elevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isMe ? colors.primary.withValues(alpha: 0.3) : Colors.transparent),
                    ),
                    child: Column(children: [
                      Row(children: [
                        SizedBox(width: 28, child: Text(medal, style: const TextStyle(fontSize: 14))),
                        Expanded(child: Text(p.name + (isMe ? ' (Вы)' : ''), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary))),
                        Text('${p.currentValue} / ${challenge.targetValue}', style: TextStyle(fontSize: 12, color: colors.textMuted)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: colors.primary.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(progress >= 1.0 ? colors.success : colors.primary),
                        ),
                      ),
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}