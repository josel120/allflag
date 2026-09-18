import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'AllFlag'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Your country. Your flag.'**
  String get tagline;

  /// No description provided for @chooseCountry.
  ///
  /// In en, this message translates to:
  /// **'Choose a country, then turn your phone sideways.'**
  String get chooseCountry;

  /// No description provided for @searchCountries.
  ///
  /// In en, this message translates to:
  /// **'Search countries...'**
  String get searchCountries;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @allCountries.
  ///
  /// In en, this message translates to:
  /// **'All Countries'**
  String get allCountries;

  /// No description provided for @noCountries.
  ///
  /// In en, this message translates to:
  /// **'No countries found'**
  String get noCountries;

  /// No description provided for @searchHelp.
  ///
  /// In en, this message translates to:
  /// **'Try a different name or check the spelling.'**
  String get searchHelp;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add {country} to favorites'**
  String addFavorite(String country);

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove {country} from favorites'**
  String removeFavorite(String country);

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load countries or saved choices.'**
  String get loadError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your choices. Retry'**
  String get saveError;

  /// No description provided for @countrySelected.
  ///
  /// In en, this message translates to:
  /// **'{country} selected. Rotate your device horizontally to display its flag.'**
  String countrySelected(String country);

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @flagLabel.
  ///
  /// In en, this message translates to:
  /// **'Flag of {country}'**
  String flagLabel(String country);

  /// No description provided for @flagUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Flag unavailable. Rotate back to choose a country.'**
  String get flagUnavailable;

  /// Bundled ISO alpha-2 display names. Keep every catalog code in every locale.
  ///
  /// In en, this message translates to:
  /// **'{code, select, AF{Afghanistan} AL{Albania} DZ{Algeria} AD{Andorra} AO{Angola} AG{Antigua and Barbuda} AR{Argentina} AM{Armenia} AU{Australia} AT{Austria} AZ{Azerbaijan} BS{Bahamas} BH{Bahrain} BD{Bangladesh} BB{Barbados} BY{Belarus} BE{Belgium} BZ{Belize} BJ{Benin} BT{Bhutan} BO{Bolivia} BA{Bosnia and Herzegovina} BW{Botswana} BR{Brazil} BN{Brunei} BG{Bulgaria} BF{Burkina Faso} BI{Burundi} KH{Cambodia} CM{Cameroon} CA{Canada} CV{Cape Verde} CF{Central African Republic} TD{Chad} CL{Chile} CN{China} CO{Colombia} KM{Comoros} CR{Costa Rica} HR{Croatia} CU{Cuba} CY{Cyprus} CZ{Czechia} DK{Denmark} DJ{Djibouti} DM{Dominica} DO{Dominican Republic} CD{DR Congo} EC{Ecuador} EG{Egypt} SV{El Salvador} GQ{Equatorial Guinea} ER{Eritrea} EE{Estonia} SZ{Eswatini} ET{Ethiopia} FJ{Fiji} FI{Finland} FR{France} GA{Gabon} GM{Gambia} GE{Georgia} DE{Germany} GH{Ghana} GR{Greece} GD{Grenada} GT{Guatemala} GN{Guinea} GW{Guinea-Bissau} GY{Guyana} HT{Haiti} HN{Honduras} HU{Hungary} IS{Iceland} IN{India} ID{Indonesia} IR{Iran} IQ{Iraq} IE{Ireland} IL{Israel} IT{Italy} CI{Ivory Coast} JM{Jamaica} JP{Japan} JO{Jordan} KZ{Kazakhstan} KE{Kenya} KI{Kiribati} KW{Kuwait} KG{Kyrgyzstan} LA{Laos} LV{Latvia} LB{Lebanon} LS{Lesotho} LR{Liberia} LY{Libya} LI{Liechtenstein} LT{Lithuania} LU{Luxembourg} MG{Madagascar} MW{Malawi} MY{Malaysia} MV{Maldives} ML{Mali} MT{Malta} MH{Marshall Islands} MR{Mauritania} MU{Mauritius} MX{Mexico} FM{Micronesia} MD{Moldova} MC{Monaco} MN{Mongolia} ME{Montenegro} MA{Morocco} MZ{Mozambique} MM{Myanmar} NA{Namibia} NR{Nauru} NP{Nepal} NL{Netherlands} NZ{New Zealand} NI{Nicaragua} NE{Niger} NG{Nigeria} KP{North Korea} MK{North Macedonia} NO{Norway} OM{Oman} PK{Pakistan} PW{Palau} PS{Palestine} PA{Panama} PG{Papua New Guinea} PY{Paraguay} PE{Peru} PH{Philippines} PL{Poland} PT{Portugal} QA{Qatar} CG{Republic of the Congo} RO{Romania} RU{Russia} RW{Rwanda} KN{Saint Kitts and Nevis} LC{Saint Lucia} VC{Saint Vincent and the Grenadines} WS{Samoa} SM{San Marino} ST{Sao Tome and Principe} SA{Saudi Arabia} SN{Senegal} RS{Serbia} SC{Seychelles} SL{Sierra Leone} SG{Singapore} SK{Slovakia} SI{Slovenia} SB{Solomon Islands} SO{Somalia} ZA{South Africa} KR{South Korea} SS{South Sudan} ES{Spain} LK{Sri Lanka} SD{Sudan} SR{Suriname} SE{Sweden} CH{Switzerland} SY{Syria} TJ{Tajikistan} TZ{Tanzania} TH{Thailand} TL{Timor-Leste} TG{Togo} TO{Tonga} TT{Trinidad and Tobago} TN{Tunisia} TR{Turkey} TM{Turkmenistan} TV{Tuvalu} UG{Uganda} UA{Ukraine} AE{United Arab Emirates} GB{United Kingdom} US{United States} UY{Uruguay} UZ{Uzbekistan} VU{Vanuatu} VA{Vatican City} VE{Venezuela} VN{Vietnam} YE{Yemen} ZM{Zambia} ZW{Zimbabwe} other{Unknown country}}'**
  String countryName(String code);

  /// No description provided for @quickFlag.
  ///
  /// In en, this message translates to:
  /// **'Quick Flag'**
  String get quickFlag;

  /// No description provided for @revealFlagControls.
  ///
  /// In en, this message translates to:
  /// **'Show exit control'**
  String get revealFlagControls;

  /// No description provided for @countryActions.
  ///
  /// In en, this message translates to:
  /// **'Actions for {country}'**
  String countryActions(String country);

  /// No description provided for @removeQuickFlag.
  ///
  /// In en, this message translates to:
  /// **'Remove Quick Flag'**
  String get removeQuickFlag;

  /// No description provided for @showFlag.
  ///
  /// In en, this message translates to:
  /// **'Show flag'**
  String get showFlag;

  /// No description provided for @exitFlag.
  ///
  /// In en, this message translates to:
  /// **'Exit Flag Mode'**
  String get exitFlag;

  /// No description provided for @setQuickFlag.
  ///
  /// In en, this message translates to:
  /// **'Set as Quick Flag'**
  String get setQuickFlag;

  /// No description provided for @showFlagLabel.
  ///
  /// In en, this message translates to:
  /// **'Show {country} flag'**
  String showFlagLabel(String country);

  /// No description provided for @readyToDisplay.
  ///
  /// In en, this message translates to:
  /// **'Ready to display'**
  String get readyToDisplay;

  /// No description provided for @setQuickFlagLabel.
  ///
  /// In en, this message translates to:
  /// **'Set {country} as Quick Flag'**
  String setQuickFlagLabel(String country);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
