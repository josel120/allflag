import 'package:flutter/material.dart';

import '../../domain/flag_item.dart';
import '../../l10n/generated/app_localizations.dart';
import '../brand_theme.dart';
import 'country_row.dart';

/// Per-country menu that sets or removes the Quick Flag.
class QuickFlagMenu extends StatelessWidget {
  const QuickFlagMenu({
    super.key,
    required this.item,
    required this.current,
    required this.onToggle,
  });
  final FlagItem item;
  final bool current;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = item.displayName(l10n.localeName);
    return PopupMenuButton<bool>(
      tooltip: l10n.countryActions(name),
      onSelected: (_) => onToggle(),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: true,
          child: Semantics(
            label: current
                ? l10n.removeQuickFlag
                : l10n.setQuickFlagLabel(name),
            excludeSemantics: true,
            child: Text(current ? l10n.removeQuickFlag : l10n.setQuickFlag),
          ),
        ),
      ],
    );
  }
}

/// The screen's primary action: the only raised surface on Home.
class QuickFlagCard extends StatelessWidget {
  const QuickFlagCard({
    super.key,
    required this.item,
    required this.onShow,
    required this.onToggleQuickFlag,
  });
  final FlagItem item;
  final VoidCallback onShow;
  final VoidCallback onToggleQuickFlag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = item.displayName(l10n.localeName);
    return Card(
      elevation: BrandTokens.quickCardElevation,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.quickFlag,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                QuickFlagMenu(
                  item: item,
                  current: true,
                  onToggle: onToggleQuickFlag,
                ),
              ],
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: BrandTokens.listTileHorizontalPadding,
              ),
              tileColor: Colors.transparent,
              leading: FlagThumbnail(asset: item.asset),
              title: Text(name),
              subtitle: Text(l10n.readyToDisplay),
            ),
            const SizedBox(height: 4),
            Semantics(
              container: true,
              label: l10n.showFlagLabel(name),
              button: true,
              excludeSemantics: true,
              onTap: onShow,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onShow,
                  icon: const Icon(Icons.fullscreen_rounded),
                  label: Text(l10n.showFlag),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
