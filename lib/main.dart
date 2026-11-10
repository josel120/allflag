import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/country_flag_catalog.dart';
import 'data/shared_preferences_flag_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Unicode CLDR country names',
    ], await rootBundle.loadString('docs/UNICODE_LICENSE.txt'));
  });
  final preferencesStore = SharedPreferencesFlagStore();
  // The native launch screen stays up meanwhile: no light/dark flash.
  final initialPreferences = await loadInitialPreferences(preferencesStore);
  runApp(
    AllFlagApp(
      repository: const CountryFlagCatalog(),
      preferencesStore: preferencesStore,
      initialPreferences: initialPreferences,
    ),
  );
}
