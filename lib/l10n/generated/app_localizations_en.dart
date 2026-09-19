// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'AllFlag';

  @override
  String get tagline => 'Your country. Your flag.';

  @override
  String get chooseCountry =>
      'Choose a country, then turn your phone sideways.';

  @override
  String get searchCountries => 'Search countries...';

  @override
  String get favorites => 'Favorites';

  @override
  String get recent => 'Recent';

  @override
  String get allCountries => 'All Countries';

  @override
  String get noCountries => 'No countries found';

  @override
  String get searchHelp => 'Try a different name or check the spelling.';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get switchToDarkMode => 'Switch to dark mode';

  @override
  String get switchToLightMode => 'Switch to light mode';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String addFavorite(String country) {
    return 'Add $country to favorites';
  }

  @override
  String removeFavorite(String country) {
    return 'Remove $country from favorites';
  }

  @override
  String get loadError => 'Could not load countries or saved choices.';

  @override
  String get retry => 'Retry';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get saveError => 'Could not save your choices. Retry';

  @override
  String countrySelected(String country) {
    return '$country selected. Rotate your device horizontally to display its flag.';
  }

  @override
  String get selected => 'Selected';

  @override
  String flagLabel(String country) {
    return 'Flag of $country';
  }

  @override
  String get flagUnavailable =>
      'Flag unavailable. Rotate back to choose a country.';

  @override
  String countryName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AF': 'Afghanistan',
      'AL': 'Albania',
      'DZ': 'Algeria',
      'AD': 'Andorra',
      'AO': 'Angola',
      'AG': 'Antigua and Barbuda',
      'AR': 'Argentina',
      'AM': 'Armenia',
      'AU': 'Australia',
      'AT': 'Austria',
      'AZ': 'Azerbaijan',
      'BS': 'Bahamas',
      'BH': 'Bahrain',
      'BD': 'Bangladesh',
      'BB': 'Barbados',
      'BY': 'Belarus',
      'BE': 'Belgium',
      'BZ': 'Belize',
      'BJ': 'Benin',
      'BT': 'Bhutan',
      'BO': 'Bolivia',
      'BA': 'Bosnia and Herzegovina',
      'BW': 'Botswana',
      'BR': 'Brazil',
      'BN': 'Brunei',
      'BG': 'Bulgaria',
      'BF': 'Burkina Faso',
      'BI': 'Burundi',
      'KH': 'Cambodia',
      'CM': 'Cameroon',
      'CA': 'Canada',
      'CV': 'Cape Verde',
      'CF': 'Central African Republic',
      'TD': 'Chad',
      'CL': 'Chile',
      'CN': 'China',
      'CO': 'Colombia',
      'KM': 'Comoros',
      'CR': 'Costa Rica',
      'HR': 'Croatia',
      'CU': 'Cuba',
      'CY': 'Cyprus',
      'CZ': 'Czechia',
      'DK': 'Denmark',
      'DJ': 'Djibouti',
      'DM': 'Dominica',
      'DO': 'Dominican Republic',
      'CD': 'DR Congo',
      'EC': 'Ecuador',
      'EG': 'Egypt',
      'SV': 'El Salvador',
      'GQ': 'Equatorial Guinea',
      'ER': 'Eritrea',
      'EE': 'Estonia',
      'SZ': 'Eswatini',
      'ET': 'Ethiopia',
      'FJ': 'Fiji',
      'FI': 'Finland',
      'FR': 'France',
      'GA': 'Gabon',
      'GM': 'Gambia',
      'GE': 'Georgia',
      'DE': 'Germany',
      'GH': 'Ghana',
      'GR': 'Greece',
      'GD': 'Grenada',
      'GT': 'Guatemala',
      'GN': 'Guinea',
      'GW': 'Guinea-Bissau',
      'GY': 'Guyana',
      'HT': 'Haiti',
      'HN': 'Honduras',
      'HU': 'Hungary',
      'IS': 'Iceland',
      'IN': 'India',
      'ID': 'Indonesia',
      'IR': 'Iran',
      'IQ': 'Iraq',
      'IE': 'Ireland',
      'IL': 'Israel',
      'IT': 'Italy',
      'CI': 'Ivory Coast',
      'JM': 'Jamaica',
      'JP': 'Japan',
      'JO': 'Jordan',
      'KZ': 'Kazakhstan',
      'KE': 'Kenya',
      'KI': 'Kiribati',
      'KW': 'Kuwait',
      'KG': 'Kyrgyzstan',
      'LA': 'Laos',
      'LV': 'Latvia',
      'LB': 'Lebanon',
      'LS': 'Lesotho',
      'LR': 'Liberia',
      'LY': 'Libya',
      'LI': 'Liechtenstein',
      'LT': 'Lithuania',
      'LU': 'Luxembourg',
      'MG': 'Madagascar',
      'MW': 'Malawi',
      'MY': 'Malaysia',
      'MV': 'Maldives',
      'ML': 'Mali',
      'MT': 'Malta',
      'MH': 'Marshall Islands',
      'MR': 'Mauritania',
      'MU': 'Mauritius',
      'MX': 'Mexico',
      'FM': 'Micronesia',
      'MD': 'Moldova',
      'MC': 'Monaco',
      'MN': 'Mongolia',
      'ME': 'Montenegro',
      'MA': 'Morocco',
      'MZ': 'Mozambique',
      'MM': 'Myanmar',
      'NA': 'Namibia',
      'NR': 'Nauru',
      'NP': 'Nepal',
      'NL': 'Netherlands',
      'NZ': 'New Zealand',
      'NI': 'Nicaragua',
      'NE': 'Niger',
      'NG': 'Nigeria',
      'KP': 'North Korea',
      'MK': 'North Macedonia',
      'NO': 'Norway',
      'OM': 'Oman',
      'PK': 'Pakistan',
      'PW': 'Palau',
      'PS': 'Palestine',
      'PA': 'Panama',
      'PG': 'Papua New Guinea',
      'PY': 'Paraguay',
      'PE': 'Peru',
      'PH': 'Philippines',
      'PL': 'Poland',
      'PT': 'Portugal',
      'QA': 'Qatar',
      'CG': 'Republic of the Congo',
      'RO': 'Romania',
      'RU': 'Russia',
      'RW': 'Rwanda',
      'KN': 'Saint Kitts and Nevis',
      'LC': 'Saint Lucia',
      'VC': 'Saint Vincent and the Grenadines',
      'WS': 'Samoa',
      'SM': 'San Marino',
      'ST': 'Sao Tome and Principe',
      'SA': 'Saudi Arabia',
      'SN': 'Senegal',
      'RS': 'Serbia',
      'SC': 'Seychelles',
      'SL': 'Sierra Leone',
      'SG': 'Singapore',
      'SK': 'Slovakia',
      'SI': 'Slovenia',
      'SB': 'Solomon Islands',
      'SO': 'Somalia',
      'ZA': 'South Africa',
      'KR': 'South Korea',
      'SS': 'South Sudan',
      'ES': 'Spain',
      'LK': 'Sri Lanka',
      'SD': 'Sudan',
      'SR': 'Suriname',
      'SE': 'Sweden',
      'CH': 'Switzerland',
      'SY': 'Syria',
      'TJ': 'Tajikistan',
      'TZ': 'Tanzania',
      'TH': 'Thailand',
      'TL': 'Timor-Leste',
      'TG': 'Togo',
      'TO': 'Tonga',
      'TT': 'Trinidad and Tobago',
      'TN': 'Tunisia',
      'TR': 'Turkey',
      'TM': 'Turkmenistan',
      'TV': 'Tuvalu',
      'UG': 'Uganda',
      'UA': 'Ukraine',
      'AE': 'United Arab Emirates',
      'GB': 'United Kingdom',
      'US': 'United States',
      'UY': 'Uruguay',
      'UZ': 'Uzbekistan',
      'VU': 'Vanuatu',
      'VA': 'Vatican City',
      'VE': 'Venezuela',
      'VN': 'Vietnam',
      'YE': 'Yemen',
      'ZM': 'Zambia',
      'ZW': 'Zimbabwe',
      'other': 'Unknown country',
    });
    return '$_temp0';
  }

  @override
  String get quickFlagHint => 'Use a country\'s menu to set a Quick Flag.';

  @override
  String get quickFlagUnavailable =>
      'Flag unavailable. Tap to show the exit button, then close Flag Mode.';

  @override
  String get quickFlag => 'Quick Flag';

  @override
  String get revealFlagControls => 'Show exit control';

  @override
  String countryActions(String country) {
    return 'Actions for $country';
  }

  @override
  String get removeQuickFlag => 'Remove Quick Flag';

  @override
  String get showFlag => 'Show flag';

  @override
  String get exitFlag => 'Exit Flag Mode';

  @override
  String get setQuickFlag => 'Set as Quick Flag';

  @override
  String showFlagLabel(String country) {
    return 'Show $country flag';
  }

  @override
  String get readyToDisplay => 'Ready to display';

  @override
  String setQuickFlagLabel(String country) {
    return 'Set $country as Quick Flag';
  }
}
