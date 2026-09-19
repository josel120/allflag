// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'AllFlag';

  @override
  String get tagline => 'Tu país. Tu bandera.';

  @override
  String get chooseCountry => 'Elige un país y luego gira tu teléfono.';

  @override
  String get searchCountries => 'Buscar países...';

  @override
  String get favorites => 'Favoritos';

  @override
  String get recent => 'Recientes';

  @override
  String get allCountries => 'Todos los países';

  @override
  String get noCountries => 'No se encontraron países';

  @override
  String get searchHelp => 'Prueba con otro nombre o revisa la ortografía.';

  @override
  String get system => 'Sistema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get switchToDarkMode => 'Cambiar a modo oscuro';

  @override
  String get switchToLightMode => 'Cambiar a modo claro';

  @override
  String get theme => 'Tema';

  @override
  String get language => 'Idioma';

  @override
  String get english => 'Inglés';

  @override
  String get spanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String addFavorite(String country) {
    return 'Agregar $country a favoritos';
  }

  @override
  String removeFavorite(String country) {
    return 'Quitar $country de favoritos';
  }

  @override
  String get loadError =>
      'No se pudieron cargar los países o tus preferencias.';

  @override
  String get retry => 'Reintentar';

  @override
  String get clearSearch => 'Borrar búsqueda';

  @override
  String get saveError => 'No se pudieron guardar tus preferencias. Reintentar';

  @override
  String countrySelected(String country) {
    return 'Has seleccionado $country. Gira tu teléfono horizontalmente para mostrar su bandera.';
  }

  @override
  String get selected => 'Seleccionado';

  @override
  String flagLabel(String country) {
    return 'Bandera de $country';
  }

  @override
  String get flagUnavailable =>
      'Bandera no disponible. Gira el teléfono para elegir un país.';

  @override
  String countryName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AF': 'Afganistán',
      'AL': 'Albania',
      'DZ': 'Argelia',
      'AD': 'Andorra',
      'AO': 'Angola',
      'AG': 'Antigua y Barbuda',
      'AR': 'Argentina',
      'AM': 'Armenia',
      'AU': 'Australia',
      'AT': 'Austria',
      'AZ': 'Azerbaiyán',
      'BS': 'Bahamas',
      'BH': 'Baréin',
      'BD': 'Bangladés',
      'BB': 'Barbados',
      'BY': 'Bielorrusia',
      'BE': 'Bélgica',
      'BZ': 'Belice',
      'BJ': 'Benín',
      'BT': 'Bután',
      'BO': 'Bolivia',
      'BA': 'Bosnia y Herzegovina',
      'BW': 'Botsuana',
      'BR': 'Brasil',
      'BN': 'Brunéi',
      'BG': 'Bulgaria',
      'BF': 'Burkina Faso',
      'BI': 'Burundi',
      'KH': 'Camboya',
      'CM': 'Camerún',
      'CA': 'Canadá',
      'CV': 'Cabo Verde',
      'CF': 'República Centroafricana',
      'TD': 'Chad',
      'CL': 'Chile',
      'CN': 'China',
      'CO': 'Colombia',
      'KM': 'Comoras',
      'CR': 'Costa Rica',
      'HR': 'Croacia',
      'CU': 'Cuba',
      'CY': 'Chipre',
      'CZ': 'Chequia',
      'DK': 'Dinamarca',
      'DJ': 'Yibuti',
      'DM': 'Dominica',
      'DO': 'República Dominicana',
      'CD': 'República Democrática del Congo',
      'EC': 'Ecuador',
      'EG': 'Egipto',
      'SV': 'El Salvador',
      'GQ': 'Guinea Ecuatorial',
      'ER': 'Eritrea',
      'EE': 'Estonia',
      'SZ': 'Esuatini',
      'ET': 'Etiopía',
      'FJ': 'Fiyi',
      'FI': 'Finlandia',
      'FR': 'Francia',
      'GA': 'Gabón',
      'GM': 'Gambia',
      'GE': 'Georgia',
      'DE': 'Alemania',
      'GH': 'Ghana',
      'GR': 'Grecia',
      'GD': 'Granada',
      'GT': 'Guatemala',
      'GN': 'Guinea',
      'GW': 'Guinea-Bisáu',
      'GY': 'Guyana',
      'HT': 'Haití',
      'HN': 'Honduras',
      'HU': 'Hungría',
      'IS': 'Islandia',
      'IN': 'India',
      'ID': 'Indonesia',
      'IR': 'Irán',
      'IQ': 'Irak',
      'IE': 'Irlanda',
      'IL': 'Israel',
      'IT': 'Italia',
      'CI': 'Costa de Marfil',
      'JM': 'Jamaica',
      'JP': 'Japón',
      'JO': 'Jordania',
      'KZ': 'Kazajistán',
      'KE': 'Kenia',
      'KI': 'Kiribati',
      'KW': 'Kuwait',
      'KG': 'Kirguistán',
      'LA': 'Laos',
      'LV': 'Letonia',
      'LB': 'Líbano',
      'LS': 'Lesoto',
      'LR': 'Liberia',
      'LY': 'Libia',
      'LI': 'Liechtenstein',
      'LT': 'Lituania',
      'LU': 'Luxemburgo',
      'MG': 'Madagascar',
      'MW': 'Malaui',
      'MY': 'Malasia',
      'MV': 'Maldivas',
      'ML': 'Mali',
      'MT': 'Malta',
      'MH': 'Islas Marshall',
      'MR': 'Mauritania',
      'MU': 'Mauricio',
      'MX': 'México',
      'FM': 'Micronesia',
      'MD': 'Moldavia',
      'MC': 'Mónaco',
      'MN': 'Mongolia',
      'ME': 'Montenegro',
      'MA': 'Marruecos',
      'MZ': 'Mozambique',
      'MM': 'Myanmar (Birmania)',
      'NA': 'Namibia',
      'NR': 'Nauru',
      'NP': 'Nepal',
      'NL': 'Países Bajos',
      'NZ': 'Nueva Zelanda',
      'NI': 'Nicaragua',
      'NE': 'Níger',
      'NG': 'Nigeria',
      'KP': 'Corea del Norte',
      'MK': 'Macedonia del Norte',
      'NO': 'Noruega',
      'OM': 'Omán',
      'PK': 'Pakistán',
      'PW': 'Palaos',
      'PS': 'Palestina',
      'PA': 'Panamá',
      'PG': 'Papúa Nueva Guinea',
      'PY': 'Paraguay',
      'PE': 'Perú',
      'PH': 'Filipinas',
      'PL': 'Polonia',
      'PT': 'Portugal',
      'QA': 'Catar',
      'CG': 'República del Congo',
      'RO': 'Rumanía',
      'RU': 'Rusia',
      'RW': 'Ruanda',
      'KN': 'San Cristóbal y Nieves',
      'LC': 'Santa Lucía',
      'VC': 'San Vicente y las Granadinas',
      'WS': 'Samoa',
      'SM': 'San Marino',
      'ST': 'Santo Tomé y Príncipe',
      'SA': 'Arabia Saudí',
      'SN': 'Senegal',
      'RS': 'Serbia',
      'SC': 'Seychelles',
      'SL': 'Sierra Leona',
      'SG': 'Singapur',
      'SK': 'Eslovaquia',
      'SI': 'Eslovenia',
      'SB': 'Islas Salomón',
      'SO': 'Somalia',
      'ZA': 'Sudáfrica',
      'KR': 'Corea del Sur',
      'SS': 'Sudán del Sur',
      'ES': 'España',
      'LK': 'Sri Lanka',
      'SD': 'Sudán',
      'SR': 'Surinam',
      'SE': 'Suecia',
      'CH': 'Suiza',
      'SY': 'Siria',
      'TJ': 'Tayikistán',
      'TZ': 'Tanzania',
      'TH': 'Tailandia',
      'TL': 'Timor-Leste',
      'TG': 'Togo',
      'TO': 'Tonga',
      'TT': 'Trinidad y Tobago',
      'TN': 'Túnez',
      'TR': 'Turquía',
      'TM': 'Turkmenistán',
      'TV': 'Tuvalu',
      'UG': 'Uganda',
      'UA': 'Ucrania',
      'AE': 'Emiratos Árabes Unidos',
      'GB': 'Reino Unido',
      'US': 'Estados Unidos',
      'UY': 'Uruguay',
      'UZ': 'Uzbekistán',
      'VU': 'Vanuatu',
      'VA': 'Ciudad del Vaticano',
      'VE': 'Venezuela',
      'VN': 'Vietnam',
      'YE': 'Yemen',
      'ZM': 'Zambia',
      'ZW': 'Zimbabue',
      'other': 'País desconocido',
    });
    return '$_temp0';
  }

  @override
  String get quickFlagHint =>
      'Usa el menú de un país para fijar una bandera rápida.';

  @override
  String get quickFlagUnavailable =>
      'Bandera no disponible. Toca para mostrar el botón de salida y cerrar el modo bandera.';

  @override
  String get quickFlag => 'Bandera rápida';

  @override
  String get revealFlagControls => 'Mostrar control para salir';

  @override
  String countryActions(String country) {
    return 'Acciones para $country';
  }

  @override
  String get removeQuickFlag => 'Quitar bandera rápida';

  @override
  String get showFlag => 'Mostrar bandera';

  @override
  String get exitFlag => 'Salir del modo bandera';

  @override
  String get setQuickFlag => 'Usar como bandera rápida';

  @override
  String showFlagLabel(String country) {
    return 'Mostrar bandera de $country';
  }

  @override
  String get readyToDisplay => 'Lista para mostrar';

  @override
  String setQuickFlagLabel(String country) {
    return 'Usar $country como bandera rápida';
  }
}
