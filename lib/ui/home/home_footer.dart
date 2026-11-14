import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// End of the list: the optional support entry and the privacy policy link.
class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key, required this.onSupport, this.onPrivacyPolicy});
  final VoidCallback onSupport;
  final VoidCallback? onPrivacyPolicy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Card(
            key: const ValueKey('support-card'),
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.volunteer_activism_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.supportTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.supportIntro, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onSupport,
                    child: Text(l10n.supportOpen),
                  ),
                ],
              ),
            ),
          ),
          if (onPrivacyPolicy != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              key: const ValueKey('privacy-policy'),
              onPressed: onPrivacyPolicy,
              icon: const Icon(Icons.privacy_tip_outlined),
              label: Text(l10n.privacyPolicy),
            ),
          ],
        ],
      ),
    );
  }
}
