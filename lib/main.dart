import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/country_flag_catalog.dart';
import 'data/shared_preferences_flag_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Unicode CLDR country names',
    ], await rootBundle.loadString('docs/UNICODE_LICENSE.txt'));
  });
  runApp(
    AllFlagApp(
      repository: const CountryFlagCatalog(),
      preferencesStore: SharedPreferencesFlagStore(),
    ),
  );
}
