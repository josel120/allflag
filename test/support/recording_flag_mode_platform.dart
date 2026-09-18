import 'package:allflag/platform/flag_mode_platform.dart';

class RecordingFlagModePlatform implements FlagModePlatform {
  final calls = <bool>[];
  bool awake = false;
  bool immersive = false;
  final orientationRequests = <bool>[];
  bool landscapeRequested = false;

  @override
  Future<void> setLandscapeRequested(bool requested) async {
    orientationRequests.add(requested);
    landscapeRequested = requested;
  }

  @override
  Future<void> setActive(bool active) async {
    calls.add(active);
    awake = active;
    immersive = active;
  }
}
