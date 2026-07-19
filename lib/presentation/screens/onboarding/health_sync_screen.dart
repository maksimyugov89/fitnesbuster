import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart';
import 'package:fitnesbuster/core/health/health_providers.dart';
import 'package:fitnesbuster/core/health/health_connect_service.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

/// Screen shown after registration asking to sync with health apps.
class HealthSyncScreen extends StatefulWidget {
  const HealthSyncScreen({super.key});

  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen> {
  final Set<HealthProvider> _selectedProviders = {};
  bool _isConnecting = false;
  bool _connected = false;
  SyncedHealthData? _syncResult;

  @override
  void initState() {
    super.initState();
    // Auto-select native Health Connect providers
    _selectedProviders.addAll(HealthProvider.androidHealthConnect);
  }

  Future<void> _startSync() async {
    setState(() => _isConnecting = true);

    try {
      final hcService = HealthConnectService();
      final initialized = await hcService.initialize();

      if (initialized) {
        final data = await hcService.readAllToday();
        setState(() {
          _connected = true;
          _syncResult = data;
          _isConnecting = false;
        });
      } else {
        setState(() => _isConnecting = false);
      }
    } catch (e) {
      setState(() => _isConnecting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.tlp('genericErrorMsg', {'error': '$e'}),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with skip button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/dashboard'),
                    child: Text(
                      AppLocalizations.tl('skip'),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.sync_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.tl('onbHealthSyncTitle'),
                      style: AppTextStyles.displayM,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.tl('onbHealthSyncSubtitle'),
                      style: AppTextStyles.bodyL,
                    ),

                    const SizedBox(height: 28),

                    // Native Health Connect providers
                    _buildSection(
                      title: AppLocalizations.tl('onbHealthConnectProviders'),
                      subtitle: AppLocalizations.tl(
                        'onbHealthConnectProvidersSub',
                      ),
                      providers: HealthProvider.androidHealthConnect,
                      selected: _selectedProviders,
                      selectable: true,
                    ),

                    const SizedBox(height: 20),

                    // Bridge providers
                    _buildSection(
                      title: AppLocalizations.tl('onbHealthBridgeProviders'),
                      subtitle: AppLocalizations.tl(
                        'onbHealthBridgeProvidersSub',
                      ),
                      providers: HealthProvider.requiresBridge,
                      selected: _selectedProviders,
                      selectable: false,
                    ),

                    const SizedBox(height: 20),

                    // Sync result
                    if (_syncResult != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.tl('onbHealthSyncComplete'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _SyncRow(
                              AppLocalizations.tl('stepsLabel'),
                              '${_syncResult!.steps}',
                              Icons.directions_walk_rounded,
                            ),
                            const SizedBox(height: 4),
                            _SyncRow(
                              AppLocalizations.tl('healthCalories'),
                              AppLocalizations.tlp('foodDiaryCalories', {
                                'calories': _syncResult!.caloriesBurned
                                    .toStringAsFixed(0),
                              }),
                              Icons.local_fire_department_rounded,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: _connected
                    ? ElevatedButton(
                        onPressed: () => context.go('/dashboard'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.tl('onbHealthStartWorkouts'),
                          style: const TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _isConnecting ? null : _startSync,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isConnecting
                              ? AppColors.surfaceLight
                              : AppColors.primary,
                          foregroundColor: _isConnecting
                              ? AppColors.textMuted
                              : AppColors.textOnPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isConnecting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    AppLocalizations.tl('healthSyncing'),
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.sync_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.tl(
                                      'onbHealthConnectAction',
                                    ),
                                    style: const TextStyle(
                                      fontFamily: 'Syne',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<HealthProvider> providers,
    required Set<HealthProvider> selected,
    required bool selectable,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        ...providers.map((p) {
          final isSelected = selected.contains(p);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.06)
                    : AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  p.iconAsset != null
                      ? Image.asset(p.iconAsset!, width: 22, height: 22)
                      : Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: p.dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      p.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 20,
                    )
                  else if (!selectable)
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SyncRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _SyncRow(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Syne',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
