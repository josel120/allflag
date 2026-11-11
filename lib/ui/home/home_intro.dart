import 'package:flutter/material.dart';

import '../../domain/flag_item.dart';
import '../../domain/flag_preferences.dart';
import '../../l10n/generated/app_localizations.dart';
import '../brand_header.dart';
import '../brand_theme.dart';
import 'quick_flag_card.dart';

/// Everything above the country list: identity, instructions, search, the
/// Quick Flag card, save errors, the selection confirmation and empty search.
class HomeIntro extends StatelessWidget {
  const HomeIntro({
    super.key,
    required this.preferences,
    required this.search,
    required this.onSearchChanged,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.quickItem,
    required this.onShowQuickFlag,
    required this.onToggleQuickFlag,
    required this.saveFailed,
    required this.onRetrySave,
    required this.selected,
    required this.noResults,
    this.onSupport,
  });

  final FlagPreferences preferences;
  final TextEditingController search;
  final VoidCallback onSearchChanged;
  final ValueChanged<ThemePreference> onThemeChanged;
  final ValueChanged<LanguagePreference> onLanguageChanged;
  final FlagItem? quickItem;
  final VoidCallback onShowQuickFlag;
  final VoidCallback onToggleQuickFlag;
  final bool saveFailed;
  final VoidCallback onRetrySave;
  final FlagItem? selected;
  final bool noResults;
  final VoidCallback? onSupport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandHeader(
          theme: preferences.theme,
          language: preferences.language,
          onLanguageChanged: onLanguageChanged,
          onThemeChanged: onThemeChanged,
          onSupport: onSupport,
        ),
        const SizedBox(height: 20),
        Text(l10n.chooseCountry, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 4),
        Text(l10n.quickFlagHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: 24),
        Semantics(
          container: true,
          child: TextField(
            controller: search,
            onChanged: (_) => onSearchChanged(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.searchCountries,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.clearSearch,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        search.clear();
                        onSearchChanged();
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (quickItem != null) ...[
          QuickFlagCard(
            key: const ValueKey('quick-flag-card'),
            item: quickItem!,
            onShow: onShowQuickFlag,
            onToggleQuickFlag: onToggleQuickFlag,
          ),
          const SizedBox(height: 12),
        ],
        if (saveFailed)
          TextButton.icon(
            onPressed: onRetrySave,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.saveError),
          ),
        if (selected != null) ...[
          // Visual confirmation only; the tapped row speaks it to TalkBack
          // because this card may already be recycled after a long scroll.
          Card(
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.screen_rotation_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.countrySelected(
                        selected!.displayName(l10n.localeName),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        AnimatedSwitcher(
          duration: AllFlagMotion.duration(context, AllFlagMotion.reveal),
          switchInCurve: AllFlagMotion.curve,
          child: noResults
              ? const EmptySearch(key: ValueKey('empty-search'))
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
