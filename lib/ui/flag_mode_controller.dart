import 'package:flutter/widgets.dart';

import '../platform/flag_mode_platform.dart';

/// Serializes platform transitions and keeps the last requested presentation authoritative.
class FlagModeController {
  FlagModeController(this._platform, {this.onError});

  final FlagModePlatform _platform;
  final void Function(Object error, StackTrace stack)? onError;
  Future<void> _pending = Future.value();
  bool? _requested;
  bool _landscapeRequested = false;
  bool _disposed = false;
  int _revision = 0;

  Future<void> get settled => _pending;

  void update({
    required bool presenting,
    required AppLifecycleState lifecycle,
    bool programmatic = false,
  }) {
    if (_disposed) return;
    final active = presenting && lifecycle == AppLifecycleState.resumed;
    _request(active, landscape: active && programmatic);
  }

  void _request(bool active, {bool landscape = false}) {
    if (_requested == active && _landscapeRequested == landscape) return;
    final orientationChanged = _landscapeRequested != landscape;
    _requested = active;
    _landscapeRequested = landscape;
    final revision = ++_revision;
    _pending = _pending.then((_) async {
      // A rotation/background/disposal can supersede an update before it starts.
      if (revision != _revision) return;
      // Always release on inactive transitions, including a superseded entry.
      if (orientationChanged || !active) {
        try {
          await _platform.setLandscapeRequested(landscape);
        } catch (error) {
          // Orientation is best-effort; the same flag remains usable by rotation.
          debugPrint('Flag Mode orientation request failed: $error');
        }
      }
      try {
        await _platform.setActive(active);
      } catch (error, stack) {
        // A partially applied enable must never leave the screen awake.
        // A later lifecycle/rotation transition can retry; do not spin on rebuilds.
        try {
          await _platform.setActive(false);
        } catch (_) {
          // Native pause/disconnect cleanup remains the final safety net.
        }
        try {
          await _platform.setLandscapeRequested(false);
        } catch (_) {}
        if (onError != null) {
          onError!(error, stack);
        } else {
          debugPrint('Flag Mode platform transition failed: $error');
        }
      }
    });
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _request(false);
  }
}
