import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/legal/legal_documents.dart';

/// Renders a [LegalDocument] (Terms of Use, Privacy Policy) as a plain,
/// scrollable screen — used from the registration checkbox and from Profile.
class LegalDocumentScreen extends StatelessWidget {
  final LegalDocument document;

  const LegalDocumentScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(document.title, style: AppTextStyles.titleL),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: colors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          Text(
            'Действует с ${document.lastUpdated}',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 20),
          for (final section in document.sections) ...[
            Text(
              section.heading,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              section.body,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
