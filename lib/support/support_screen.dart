import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../ui/brand_theme.dart';
import 'support_ad_service.dart';
import 'supporter_store.dart';

enum SupportPhase {
  preparing,
  loading,
  ready,
  showing,
  thanks,
  noReward,
  unavailable,
  offline,
  error,
  consentDenied,
}

/// Opt-in rewarded ad. The reward (a thank-you and +1 on the supporter badge)
/// is stated before the ad, as AdMob requires; nothing is ever gated on it.
class SupportScreen extends StatefulWidget {
  const SupportScreen({
    super.key,
    required this.adService,
    required this.supporterStore,
  });
  final SupportAdService adService;
  final SupporterStore supporterStore;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  SupportPhase _phase = SupportPhase.preparing;
  int _count = 0;
  bool _privacyOptions = false;

  @override
  void initState() {
    super.initState();
    widget.supporterStore.load().then((value) {
      if (mounted) setState(() => _count = value);
    }, onError: (_) {});
    _start();
  }

  @override
  void dispose() {
    widget.adService.dispose();
    super.dispose();
  }

  void _fail(Object error) {
    if (!mounted) return;
    setState(
      () => _phase = switch (error) {
        SupportAdException(failure: SupportAdFailure.unavailable) =>
          SupportPhase.unavailable,
        SupportAdException(failure: SupportAdFailure.offline) =>
          SupportPhase.offline,
        SupportAdException(failure: SupportAdFailure.consentDenied) =>
          SupportPhase.consentDenied,
        _ => SupportPhase.error,
      },
    );
  }

  Future<void> _start() async {
    setState(() => _phase = SupportPhase.preparing);
    try {
      await widget.adService.prepare();
    } catch (error) {
      await _refreshPrivacyOptions();
      _fail(error);
      return;
    }
    await _refreshPrivacyOptions();
    await _load();
  }

  Future<void> _refreshPrivacyOptions() async {
    try {
      final required = await widget.adService.privacyOptionsRequired();
      if (mounted) setState(() => _privacyOptions = required);
    } catch (_) {}
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _phase = SupportPhase.loading);
    try {
      await widget.adService.load();
      if (mounted) setState(() => _phase = SupportPhase.ready);
    } catch (error) {
      _fail(error);
    }
  }

  Future<void> _watch() async {
    setState(() => _phase = SupportPhase.showing);
    try {
      final earned = await widget.adService.show();
      if (!mounted) return;
      if (earned) {
        final next = _count + 1;
        setState(() {
          _count = next;
          _phase = SupportPhase.thanks;
        });
        try {
          await widget.supporterStore.save(next);
        } catch (_) {}
      } else {
        setState(() => _phase = SupportPhase.noReward);
      }
    } catch (error) {
      _fail(error);
    }
  }

  Future<void> _openPrivacyOptions() async {
    try {
      await widget.adService.showPrivacyOptions();
    } catch (_) {}
    await _start();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final busy = switch (_phase) {
      SupportPhase.preparing ||
      SupportPhase.loading ||
      SupportPhase.showing => true,
      _ => false,
    };
    final (IconData icon, String? message) = switch (_phase) {
      SupportPhase.preparing => (
        Icons.hourglass_top_rounded,
        l10n.supportPreparing,
      ),
      SupportPhase.loading => (
        Icons.hourglass_top_rounded,
        l10n.supportLoading,
      ),
      SupportPhase.showing => (Icons.hourglass_top_rounded, null),
      SupportPhase.ready => (Icons.play_circle_outline_rounded, null),
      SupportPhase.thanks => (Icons.favorite_rounded, l10n.supportThanks),
      SupportPhase.noReward => (
        Icons.info_outline_rounded,
        l10n.supportNoReward,
      ),
      SupportPhase.unavailable => (
        Icons.hourglass_empty_rounded,
        l10n.supportUnavailable,
      ),
      SupportPhase.offline => (Icons.wifi_off_rounded, l10n.supportOffline),
      SupportPhase.error => (Icons.error_outline_rounded, l10n.supportError),
      SupportPhase.consentDenied => (
        Icons.privacy_tip_outlined,
        l10n.supportConsentDenied,
      ),
    };
    final canWatch = _phase == SupportPhase.ready;
    final canRetry = switch (_phase) {
      SupportPhase.thanks ||
      SupportPhase.noReward ||
      SupportPhase.unavailable ||
      SupportPhase.offline ||
      SupportPhase.error => true,
      _ => false,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(BrandTokens.pagePadding),
          children: [
            Text(l10n.supportIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            Card(
              key: const ValueKey('support-reward'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.volunteer_activism_rounded,
                      color: scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.supportReward,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Row(
                key: const ValueKey('supporter-count'),
                children: [
                  Icon(
                    _count > 0
                        ? Icons.workspace_premium_rounded
                        : Icons.workspace_premium_outlined,
                    color: _count > 0
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.supportCount(_count),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: AllFlagMotion.duration(context, AllFlagMotion.reveal),
              child: message == null
                  ? const SizedBox(width: double.infinity)
                  : Semantics(
                      key: ValueKey(_phase),
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(
                            BrandTokens.radius,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              icon,
                              color: _phase == SupportPhase.thanks
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(message)),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            if (busy) const LinearProgressIndicator(),
            if (busy) const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('support-watch'),
              onPressed: canWatch ? _watch : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.supportWatchAd),
            ),
            if (canRetry) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('support-retry'),
                onPressed:
                    _phase == SupportPhase.thanks ||
                        _phase == SupportPhase.noReward
                    ? _load
                    : _start,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  _phase == SupportPhase.thanks ||
                          _phase == SupportPhase.noReward
                      ? l10n.supportAgain
                      : l10n.retry,
                ),
              ),
            ],
            if (_privacyOptions || _phase == SupportPhase.consentDenied) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                key: const ValueKey('support-privacy-options'),
                onPressed: _openPrivacyOptions,
                icon: const Icon(Icons.privacy_tip_outlined),
                label: Text(l10n.privacyOptions),
              ),
            ],
            const SizedBox(height: 16),
            Text(l10n.supportNetworkNote, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
