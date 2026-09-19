import 'package:flutter/material.dart';

import '../domain/flag_preferences.dart';
import '../l10n/generated/app_localizations.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    this.theme = ThemePreference.system,
    this.onThemeChanged,
    this.language = LanguagePreference.system,
    this.onLanguageChanged,
  });

  final ThemePreference theme;
  final ValueChanged<ThemePreference>? onThemeChanged;
  final LanguagePreference language;
  final ValueChanged<LanguagePreference>? onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controls = [
      IconButton(
        key: const ValueKey('appearance-toggle'),
        tooltip: theme == ThemePreference.dark
            ? l10n.switchToLightMode
            : l10n.switchToDarkMode,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: Icon(
          theme == ThemePreference.dark
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          semanticLabel: theme == ThemePreference.dark
              ? l10n.switchToLightMode
              : l10n.switchToDarkMode,
        ),
        onPressed: onThemeChanged == null
            ? null
            : () => onThemeChanged!(
                theme == ThemePreference.dark
                    ? ThemePreference.light
                    : ThemePreference.dark,
              ),
      ),
      _PreferenceMenu<LanguagePreference>(
        tooltip: l10n.language,
        icon: Icons.language,
        selected: language,
        values: const [LanguagePreference.english, LanguagePreference.spanish],
        onSelected: onLanguageChanged,
        label: (value) => switch (value) {
          LanguagePreference.system => l10n.system,
          LanguagePreference.english => l10n.languageEnglish,
          LanguagePreference.spanish => l10n.languageSpanish,
        },
      ),
    ];
    return Semantics(
      container: true,
      header: true,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/branding/allflag-icon.png',
              width: 52,
              height: 52,
              cacheWidth: (52 * MediaQuery.devicePixelRatioOf(context)).ceil(),
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                  ),
                ),
                Text(
                  l10n.tagline,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (MediaQuery.sizeOf(context).width < 360 ||
              MediaQuery.textScalerOf(context).scale(14) > 20)
            Column(mainAxisSize: MainAxisSize.min, children: controls)
          else
            Row(mainAxisSize: MainAxisSize.min, children: controls),
        ],
      ),
    );
  }
}

class _PreferenceMenu<T> extends StatelessWidget {
  const _PreferenceMenu({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.values,
    required this.label,
    this.onSelected,
  });
  final String tooltip;
  final IconData icon;
  final T selected;
  final List<T> values;
  final String Function(T) label;
  final ValueChanged<T>? onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<T>(
    tooltip: tooltip,
    initialValue: selected,
    icon: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
    onSelected: onSelected,
    itemBuilder: (context) => [
      for (final value in values)
        PopupMenuItem<T>(
          value: value,
          child: Semantics(
            selected: selected == value,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: selected == value
                      ? const Icon(Icons.check, size: 18)
                      : null,
                ),
                const SizedBox(width: 12),
                Flexible(child: Text(label(value))),
              ],
            ),
          ),
        ),
    ],
  );
}

class EmptySearch extends StatelessWidget {
  const EmptySearch({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noCountries,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).searchHelp,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
