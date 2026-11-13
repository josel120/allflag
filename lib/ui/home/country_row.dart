import 'package:flutter/material.dart';

import '../../domain/flag_item.dart';
import '../../l10n/generated/app_localizations.dart';
import '../brand_theme.dart';
import 'home_rows.dart';
import 'quick_flag_card.dart';

/// Whether rows must stack their actions under the title (narrow or 200% text).
bool constrainedRows(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 360 ||
    MediaQuery.textScalerOf(context).scale(16) > 20;

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.section});
  final FlagSection section;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 10),
        child: Row(
          children: [
            Icon(
              switch (section) {
                FlagSection.favorites => Icons.star_rounded,
                FlagSection.recent => Icons.history_rounded,
                _ => Icons.public_rounded,
              },
              size: 18,
              color: section == FlagSection.favorites
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(switch (section) {
                FlagSection.favorites => l10n.favorites,
                FlagSection.recent => l10n.recent,
                _ => l10n.allCountries,
              }, style: theme.textTheme.titleSmall),
            ),
          ],
        ),
      ),
    );
  }
}

class CountryRow extends StatelessWidget {
  const CountryRow({
    super.key,
    required this.item,
    required this.section,
    required this.favorite,
    required this.selected,
    required this.announceSelection,
    required this.isQuickFlag,
    required this.onSelect,
    required this.onToggleFavorite,
    required this.onToggleQuickFlag,
  });

  final FlagItem item;
  final FlagSection section;
  final bool favorite;
  final bool selected;

  /// Only the row the user tapped speaks the confirmation. It is mounted and
  /// focused, unlike the header card that a long scroll may have recycled.
  final bool announceSelection;
  final bool isQuickFlag;
  final VoidCallback onSelect;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleQuickFlag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = item.displayName(l10n.localeName);
    final style =
        theme.extension<FlagRowStyle>() ?? FlagRowStyle.of(theme.colorScheme);
    final favoriteLabel = favorite
        ? l10n.removeFavorite(name)
        : l10n.addFavorite(name);
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        QuickFlagMenu(
          item: item,
          current: isQuickFlag,
          onToggle: onToggleQuickFlag,
        ),
        Semantics(
          container: true,
          liveRegion: announceSelection,
          label: selected && announceSelection
              ? l10n.countrySelected(name)
              : (selected ? l10n.selected : null),
          excludeSemantics: true,
          child: selected
              ? Icon(
                  Icons.check_circle,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                )
              : const SizedBox.shrink(),
        ),
        Semantics(
          container: true,
          excludeSemantics: true,
          label: favoriteLabel,
          button: true,
          toggled: favorite,
          onTap: onToggleFavorite,
          child: IconButton(
            tooltip: favoriteLabel,
            isSelected: favorite,
            icon: const Icon(Icons.star_border_rounded),
            selectedIcon: Icon(
              Icons.star_rounded,
              color: theme.colorScheme.primary,
            ),
            onPressed: onToggleFavorite,
          ),
        ),
      ],
    );
    final constrained = constrainedRows(context);
    final radius = BorderRadius.circular(BrandTokens.radius);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          key: ValueKey(switch (section) {
            FlagSection.favorites => 'Favorites-${item.id}',
            FlagSection.recent => 'Recent-${item.id}',
            _ => item.id.toString(),
          }),
          tileColor: switch (section) {
            FlagSection.favorites => style.favorite,
            FlagSection.recent => style.recent,
            _ => style.all,
          },
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: section == FlagSection.recent && !selected
                ? BorderSide(
                    color: style.recentBorder,
                    // Outside: the outline must not shift row content.
                    strokeAlign: BorderSide.strokeAlignOutside,
                  )
                : BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: BrandTokens.listTileHorizontalPadding,
            vertical: 8,
          ),
          leading: FlagThumbnail(asset: item.asset),
          title: Text(name),
          subtitle: constrained
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [if (isQuickFlag) Text(l10n.quickFlag), actions],
                )
              : isQuickFlag
              ? Text(l10n.quickFlag)
              : null,
          selected: selected,
          trailing: constrained ? null : actions,
          onTap: onSelect,
        ),
      ),
    );
  }
}

/// 48×32 flag preview decoded at display size (not the 2560px source).
class FlagThumbnail extends StatelessWidget {
  const FlagThumbnail({super.key, required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    width: 48,
    height: 32,
    fit: BoxFit.contain,
    cacheWidth: (48 * MediaQuery.devicePixelRatioOf(context)).ceil(),
    excludeFromSemantics: true,
  );
}
