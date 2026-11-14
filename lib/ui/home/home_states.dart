import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../brand_theme.dart';

/// Matches the launch screen (brand mark on the canvas). The progress line and
/// label only fade in if loading takes noticeably long, so a fast local load
/// never flashes a spinner.
class HomeLoading extends StatelessWidget {
  const HomeLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final reduced = AllFlagMotion.reduced(context);
    return Center(
      key: const ValueKey('home-loading'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/branding/allflag-icon.png',
              width: 64,
              height: 64,
              cacheWidth: (64 * MediaQuery.devicePixelRatioOf(context)).ceil(),
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: reduced ? 1 : 0, end: 1),
            duration: reduced
                ? Duration.zero
                : const Duration(milliseconds: 700),
            curve: const Interval(0.6, 1, curve: Curves.easeOut),
            builder: (context, opacity, child) =>
                Opacity(opacity: opacity, child: child),
            child: Semantics(
              liveRegion: true,
              label: l10n.loadingCountries,
              child: Column(
                children: [
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ExcludeSemantics(
                    child: Text(
                      l10n.loadingCountries,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeLoadError extends StatelessWidget {
  const HomeLoadError({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      key: const ValueKey('home-error'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.loadError,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
