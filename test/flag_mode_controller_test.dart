import 'dart:async';

import 'package:allflag/platform/flag_mode_platform.dart';
import 'package:allflag/ui/flag_mode_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/recording_flag_mode_platform.dart';

class DelayedPlatform extends RecordingFlagModePlatform {
  final started = Completer<void>();
  final finish = Completer<void>();

  @override
  Future<void> setActive(bool active, {bool programmatic = false}) async {
    if (active) {
      started.complete();
      await finish.future;
    }
    await super.setActive(active, programmatic: programmatic);
  }
}

class FailingPlatform extends RecordingFlagModePlatform {
  bool fail = true;

  @override
  Future<void> setActive(bool active, {bool programmatic = false}) async {
    await super.setActive(active, programmatic: programmatic);
    if (active && fail) {
      fail = false;
      throw PlatformException(code: 'unavailable');
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('only foreground presentation enables awake and immersive; rebuilds deduplicate', () async {
    final platform = RecordingFlagModePlatform();
    final controller = FlagModeController(platform);
    for (var i = 0; i < 20; i++) {
      controller.update(
        presenting: false,
        lifecycle: AppLifecycleState.resumed,
      );
      await controller.settled;
    }
    expect(platform.calls, [false]);
    expect(platform.awake, isFalse);
    for (var i = 0; i < 20; i++) {
      controller.update(presenting: true, lifecycle: AppLifecycleState.resumed);
      await controller.settled;
    }
    expect(platform.calls, [false, true]);
    expect(platform.awake, isTrue);
    expect(platform.immersive, isTrue);
    controller.update(presenting: false, lifecycle: AppLifecycleState.resumed);
    await controller.settled;
    expect(platform.calls, [false, true, false]);
    expect(platform.awake, isFalse);
    controller.dispose();
    await controller.settled;
    expect(platform.calls, [false, true, false]);
  });

  for (final lifecycle in AppLifecycleState.values.where(
    (s) => s != AppLifecycleState.resumed,
  )) {
    test(
      '$lifecycle releases platform state and resumed Flag Mode restores it',
      () async {
        final platform = RecordingFlagModePlatform();
        final controller = FlagModeController(platform);
        controller.update(
          presenting: true,
          lifecycle: AppLifecycleState.resumed,
        );
        await controller.settled;
        controller.update(presenting: true, lifecycle: lifecycle);
        await controller.settled;
        expect(platform.awake, isFalse);
        expect(platform.immersive, isFalse);
        controller.update(presenting: true, lifecycle: lifecycle);
        await controller.settled;
        expect(platform.calls, [true, false]);
        controller.update(
          presenting: true,
          lifecycle: AppLifecycleState.resumed,
        );
        await controller.settled;
        expect(platform.calls, [true, false, true]);
        controller.dispose();
        await controller.settled;
        expect(platform.calls.last, isFalse);
      },
    );
  }

  test(
    'background rotation does not re-enable Flag Mode on portrait resume',
    () async {
      final platform = RecordingFlagModePlatform();
      final controller = FlagModeController(platform);
      controller.update(presenting: true, lifecycle: AppLifecycleState.resumed);
      await controller.settled;
      controller.update(
        presenting: true,
        lifecycle: AppLifecycleState.inactive,
      );
      await controller.settled;
      controller.update(presenting: false, lifecycle: AppLifecycleState.paused);
      controller.update(
        presenting: false,
        lifecycle: AppLifecycleState.resumed,
      );
      await controller.settled;
      expect(platform.calls, [true, false]);
      controller.dispose();
    },
  );

  test(
    'superseded transitions are coalesced before platform invocation',
    () async {
      final platform = RecordingFlagModePlatform();
      final controller = FlagModeController(platform);
      controller.update(presenting: true, lifecycle: AppLifecycleState.resumed);
      controller.update(
        presenting: false,
        lifecycle: AppLifecycleState.resumed,
      );
      await controller.settled;
      expect(platform.calls, [false]);
      controller.dispose();
    },
  );

  test('dispose restores state after an in-flight enable and ignores future updates', () async {
    final platform = DelayedPlatform();
    final controller = FlagModeController(platform);
    controller.update(presenting: true, lifecycle: AppLifecycleState.resumed);
    await platform.started.future;
    controller.dispose();
    controller.dispose();
    controller.update(presenting: true, lifecycle: AppLifecycleState.resumed);
    platform.finish.complete();
    await controller.settled;
    expect(platform.calls, [true, false]);
    expect(platform.awake, isFalse);
  });

  test('partial platform failure cleans up without retry storms; later entry works', () async {
    final platform = FailingPlatform();
    final errors = <Object>[];
    final controller = FlagModeController(
      platform,
      onError: (error, _) => errors.add(error),
    );
    controller.update(presenting: true, lifecycle: AppLifecycleState.resumed);
    await controller.settled;
    expect(errors, hasLength(1));
    expect(platform.calls, [true, false]);
    expect(platform.awake, isFalse);
    controller.update(presenting: true, lifecycle: AppLifecycleState.resumed);
    await controller.settled;
    expect(platform.calls, [true, false]);
    controller.update(presenting: false, lifecycle: AppLifecycleState.resumed);
    await controller.settled;
    controller.update(presenting: true, lifecycle: AppLifecycleState.resumed);
    await controller.settled;
    expect(platform.awake, isTrue);
    controller.dispose();
    await controller.settled;
    expect(platform.awake, isFalse);
  });

  test('Android adapter uses native insets channel, not ignored legacy system modes', () async {
    final native = <MethodCall>[];
    final flutter = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(NativeFlagModePlatform.channel, (
      call,
    ) async {
      native.add(call);
      return null;
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      flutter.add(call);
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(NativeFlagModePlatform.channel, null);
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });
    const platform = NativeFlagModePlatform(operatingSystem: 'android');
    await platform.setActive(true);
    await platform.setActive(false);
    expect(native.map((call) => call.method), ['setFlagMode', 'setFlagMode']);
    expect(native.map((call) => call.arguments), [true, false]);
    expect(flutter, isEmpty);
  });

  test(
    'iOS adapter scopes idle timer and restores supported overlays',
    () async {
      final native = <Object?>[];
      final modes = <Object?>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(NativeFlagModePlatform.channel, (
        call,
      ) async {
        native.add(call.arguments);
        return null;
      });
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        expect(call.method, 'SystemChrome.setEnabledSystemUIMode');
        modes.add(call.arguments);
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(
          NativeFlagModePlatform.channel,
          null,
        );
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });
      const platform = NativeFlagModePlatform(operatingSystem: 'ios');
      await platform.setActive(true);
      await platform.setActive(false);
      expect(native, [true, false]);
      expect(modes, [
        'SystemUiMode.immersiveSticky',
        'SystemUiMode.edgeToEdge',
      ]);
    },
  );
}
