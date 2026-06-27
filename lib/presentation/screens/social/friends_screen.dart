import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/services/social_service.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/data/models/user_search_result.dart';
import 'package:fitnesbuster/presentation/widgets/loading_shimmer.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();
  List<UserSearchResult> _searchResults = [];
  bool _searching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() { _searchResults = []; _searchError = null; });
      return;
    }
    setState(() { _searching = true; _searchError = null; });
    try {
      final results = await sl<SocialService>().searchUsers(query.trim());
      if (mounted) setState(() { _searchResults = results; _searching = false; });
    } catch (e) {
      if (mounted) setState(() { _searching = false; _searchError = e.toString(); });
    }
  }

  Future<void> _addFriend(String uid) async {
    // Optimistic update — instantly mark as sent
    setState(() {
      _searchResults = _searchResults.map((r) {
        if (r.uid == uid) return r.copyWith(requestSent: true);
        return r;
      }).toList();
    });
    try {
      await sl<SocialService>().sendFriendRequest(uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запрос отправлен!')),
        );
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _searchResults = _searchResults.map((r) {
            if (r.uid == uid) return r.copyWith(requestSent: false);
            return r;
          }).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.tl('genericErrorMsg').replaceAll('{error}', e.toString()))),
        );
      }
    }
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
        title: const Text('Друзья', style: AppTextStyles.titleL),
        bottom: TabBar(
          controller: _tabs,
          indicator: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          dividerColor: Colors.transparent,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          labelPadding: EdgeInsets.zero,
          tabs: const [
            Tab(text: 'Мои друзья', height: 36),
            Tab(text: 'Запросы', height: 36),
            Tab(text: 'Поиск', height: 36),
          ],
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildFriendsList(colors),
          _buildRequests(colors),
          _buildSearch(colors),
        ],
      ),
    );
  }

  // ── My friends ─────────────────────────────────────────────────────────────

  Widget _buildFriendsList(ThemePalette colors) {
    return StreamBuilder<List<FriendUser>>(
      stream: sl<SocialService>().friendsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final friends = snap.data ?? [];
        if (friends.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🤝', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Нет друзей', style: TextStyle(fontSize: 16, fontFamily: 'Syne', fontWeight: FontWeight.w800, color: colors.textPrimary)),
              const SizedBox(height: 6),
              Text('Найди друзей во вкладке «Поиск»', style: TextStyle(fontSize: 12, color: colors.textMuted)),
            ]),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          itemCount: friends.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _FriendTile(
            user: friends[i],
            colors: colors,
            trailing: IconButton(
              icon: Icon(Icons.person_remove_outlined, color: colors.textMuted, size: 20),
              onPressed: () => _confirmRemove(context, friends[i], colors),
            ),
          ),
        );
      },
    );
  }

  void _confirmRemove(BuildContext context, FriendUser user, ThemePalette colors) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surfaceCard,
        title: Text('Удалить друга?', style: TextStyle(color: colors.textPrimary, fontFamily: 'Syne', fontWeight: FontWeight.w800)),
        content: Text('${user.name} будет удалён из списка друзей.', style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена', style: TextStyle(color: colors.textMuted))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await sl<SocialService>().removeFriend(user.uid);
            },
            child: Text('Удалить', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }

  // ── Incoming requests ──────────────────────────────────────────────────────

  Widget _buildRequests(ThemePalette colors) {
    return StreamBuilder<List<FriendRequest>>(
      stream: sl<SocialService>().incomingRequestsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Ошибка: ${snap.error}', style: TextStyle(color: colors.error, fontSize: 13)),
            ),
          );
        }
        final requests = snap.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('📭', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Нет входящих запросов', style: TextStyle(fontSize: 16, fontFamily: 'Syne', fontWeight: FontWeight.w800, color: colors.textPrimary)),
              const SizedBox(height: 6),
              Text('Запросы появятся здесь когда\nкто-то захочет добавить вас', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: colors.textMuted)),
            ]),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _RequestTile(request: requests[i], colors: colors),
        );
      },
    );
  }

  // ── Search ──────────────────────────────────────────────────────────────────

  Widget _buildSearch(ThemePalette colors) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _search,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Поиск по имени пользователя...',
            hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: colors.textMuted),
            filled: true,
            fillColor: colors.surfaceCard,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ),
      if (_searching)
        Padding(padding: const EdgeInsets.all(24), child: LoadingShimmer.listView(5))
      else if (_searchError != null)
        Padding(padding: const EdgeInsets.all(24), child: Text(_searchError!, style: TextStyle(color: colors.error)))
      else
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
            itemCount: _searchResults.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final r = _searchResults[i];
              final isFriend = r.isFriend;
              final requestSent = r.requestSent;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(children: [
                  _Avatar(name: r.name.isEmpty ? '?' : r.name, colors: colors),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                    Text(
                      (r.email ?? '').isNotEmpty
                          ? r.email!
                          : (r.username ?? '').isNotEmpty
                              ? '@${r.username}'
                              : '',
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                  ])),
                  if (isFriend)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: colors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text('Друг', style: TextStyle(fontSize: 11, color: colors.success, fontWeight: FontWeight.w600)),
                    )
                  else if (requestSent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: colors.textMuted.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text('Отправлено', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                    )
                  else
                    GestureDetector(
                      onTap: () => _addFriend(r.uid),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(8)),
                        child: Text('Добавить', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textOnPrimary)),
                      ),
                    ),
                ]),
              );
            },
          ),
        ),
    ]);
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final ThemePalette colors;
  const _Avatar({required this.name, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w800, color: colors.primary),
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendUser user;
  final ThemePalette colors;
  final Widget? trailing;
  const _FriendTile({required this.user, required this.colors, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        _Avatar(name: user.name, colors: colors),
        const SizedBox(width: 12),
        Expanded(child: Text(user.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary))),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class _RequestTile extends StatefulWidget {
  final FriendRequest request;
  final ThemePalette colors;
  const _RequestTile({required this.request, required this.colors});

  @override
  State<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<_RequestTile> {
  bool _loading = false;

  Future<void> _accept() async {
    setState(() => _loading = true);
    try {
      await sl<SocialService>().acceptFriendRequest(widget.request.id);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decline() async {
    setState(() => _loading = true);
    try {
      await sl<SocialService>().declineFriendRequest(widget.request.id);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        _Avatar(name: widget.request.fromName, colors: colors),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.request.fromName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          Text('хочет добавить вас в друзья', style: TextStyle(fontSize: 11, color: colors.textMuted)),
        ])),
        if (_loading)
          SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary))
        else
          Row(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(
              onTap: _accept,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(8)),
                child: Text('Принять', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textOnPrimary)),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _decline,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: colors.elevated, borderRadius: BorderRadius.circular(8)),
                child: Text('Отклонить', style: TextStyle(fontSize: 12, color: colors.textMuted)),
              ),
            ),
          ]),
      ]),
    );
  }
}
