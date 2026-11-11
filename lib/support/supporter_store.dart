import 'package:shared_preferences/shared_preferences.dart';

/// On-device count of earned rewards. Cosmetic only: it never unlocks anything.
abstract interface class SupporterStore {
  Future<int> load();
  Future<void> save(int count);
}

class SharedPreferencesSupporterStore implements SupporterStore {
  SharedPreferencesSupporterStore({SharedPreferencesAsync? storage})
    : _storage = storage ?? SharedPreferencesAsync();
  static const storageKey = 'allflag.supporter_count.v1';
  final SharedPreferencesAsync _storage;

  @override
  Future<int> load() async {
    final value = await _storage.getInt(storageKey);
    return value == null || value < 0 ? 0 : value;
  }

  @override
  Future<void> save(int count) => _storage.setInt(storageKey, count);
}

class MemorySupporterStore implements SupporterStore {
  MemorySupporterStore([this.count = 0]);
  int count;
  @override
  Future<int> load() async => count;
  @override
  Future<void> save(int count) async => this.count = count;
}
