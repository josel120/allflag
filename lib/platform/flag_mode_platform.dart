import 'dart:io';

import 'package:flutter/services.dart';

/// One transition owns both system overlays and the foreground screen-awake flag.
abstract interface class FlagModePlatform {
  Future<void> setActive(bool active);
  Future<void> setLandscapeRequested(bool requested);
}

class NativeFlagModePlatform implements FlagModePlatform {
  const NativeFlagModePlatform({this.operatingSystem});

  // Injectable for channel tests; use the actual host, not Flutter's UI theme platform.
  final String? operatingSystem;
  static const channel = MethodChannel('com.allflag.allflag/flag_mode');

  @override
  Future<void> setLandscapeRequested(bool requested) =>
      SystemChrome.setPreferredOrientations(
        requested
            ? [
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]
            : [],
      );

  @override
  Future<void> setActive(bool active) async {
    final system = operatingSystem ?? Platform.operatingSystem;
    if (system == 'android') {
      // Flutter's legacy immersive modes are ignored with target SDK 36.
      // The host uses WindowInsetsControllerCompat, keeping edge-to-edge enabled.
      await channel.invokeMethod<void>('setFlagMode', active);
      return;
    }
    if (system == 'ios') {
      await channel.invokeMethod<void>('setFlagMode', active);
    }
    // iOS supports hiding its status bar and auto-hiding its home indicator.
    // Desktop widget tests retain the framework overlay path without a mobile host.
    await SystemChrome.setEnabledSystemUIMode(
      active ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }
}
