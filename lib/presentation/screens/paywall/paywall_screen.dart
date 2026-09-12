import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';
import 'package:fitnesbuster/domain/services/i_analytics_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    try {
      sl<IAnalyticsService>().logPaywallViewed().ignore();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.tl('premiumTitle'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: AppIcon(
                asset: AppImages.premium,
                size: 72,
                glowColor: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.tl('premiumSubtitle'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            _TariffCard(text: AppLocalizations.tl('premiumMonthly')),
            const SizedBox(height: 12),
            _TariffCard(text: AppLocalizations.tl('premiumYearly')),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.tl('premiumBetaNotice'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: null,
              child: Text(AppLocalizations.tl('premiumPaymentSoon')),
            ),
          ],
        ),
      ),
    );
  }
}

class _TariffCard extends StatelessWidget {
  const _TariffCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}
