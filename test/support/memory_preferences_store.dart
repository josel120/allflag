import 'package:allflag/domain/flag_id.dart';
import 'package:allflag/domain/flag_preferences.dart';
import 'package:allflag/domain/flag_preferences_store.dart';

class MemoryPreferencesStore implements FlagPreferencesStore {
  MemoryPreferencesStore([FlagPreferences? initial])
    : value = initial ?? FlagPreferences();
  FlagPreferences value;
  bool failWrites = false;

  @override
  Future<FlagPreferences> load({Set<FlagId>? availableIds}) async =>
      availableIds == null ? value : value.validFor(availableIds);

  @override
  Future<void> save(FlagPreferences preferences) async {
    if (failWrites) throw StateError('Storage unavailable');
    value = preferences;
  }
}
