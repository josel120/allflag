import 'flag_id.dart';
import 'flag_preferences.dart';

abstract interface class FlagPreferencesStore {
  Future<FlagPreferences> load({Set<FlagId>? availableIds});
  Future<void> save(FlagPreferences preferences);
}
