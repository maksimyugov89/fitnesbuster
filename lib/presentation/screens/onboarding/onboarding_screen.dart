import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Entry point for onboarding flow. Immediately redirects to goal selection.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/onboarding/goal');
    });
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: const SizedBox.shrink(),
    );
  }
}
