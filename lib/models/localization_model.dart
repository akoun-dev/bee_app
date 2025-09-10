import 'package:flutter/material.dart';

// Modèle pour la gestion de l'internationalisation et de la localisation
class LocalizationModel {
  final String userId;
  final AppLanguage language;
  final AppRegion region;
  final TimeZone timeZone;
  final DateFormat dateFormat;
  final TimeFormat timeFormat;
  final NumberFormat numberFormat;
  final CurrencyFormat currencyFormat;
  final MeasurementSystem measurementSystem;
  final DateTime lastUpdated;

  LocalizationModel({
    required this.userId,
    required this.language,
    required this.region,
    required this.timeZone,
    required this.dateFormat,
    required this.timeFormat,
    required this.numberFormat,
    required this.currencyFormat,
    required this.measurementSystem,
    required this.lastUpdated,
  });

  // Conversion depuis Map
  factory LocalizationModel.fromMap(Map<String, dynamic> map) {
    return LocalizationModel(
      userId: map['userId'] ?? '',
      language: AppLanguage.values.firstWhere(
        (e) => e.code == (map['language'] ?? 'fr'),
        orElse: () => AppLanguage.french,
      ),
      region: AppRegion.values.firstWhere(
        (e) => e.code == (map['region'] ?? 'FR'),
        orElse: () => AppRegion.france,
      ),
      timeZone: TimeZone.values.firstWhere(
        (e) => e.id == (map['timeZone'] ?? 'Europe/Paris'),
        orElse: () => TimeZone.europeParis,
      ),
      dateFormat: DateFormat.values.firstWhere(
        (e) => e.name == (map['dateFormat'] ?? 'dd/MM/yyyy'),
        orElse: () => DateFormat.ddMMyyyy,
      ),
      timeFormat: TimeFormat.values.firstWhere(
        (e) => e.name == (map['timeFormat'] ?? 'HH:mm'),
        orElse: () => TimeFormat.hhMm24,
      ),
      numberFormat: NumberFormat.values.firstWhere(
        (e) => e.name == (map['numberFormat'] ?? 'space_comma'),
        orElse: () => NumberFormat.spaceComma,
      ),
      currencyFormat: CurrencyFormat.values.firstWhere(
        (e) => e.name == (map['currencyFormat'] ?? 'EUR_symbol_before'),
        orElse: () => CurrencyFormat.eurSymbolBefore,
      ),
      measurementSystem: MeasurementSystem.values.firstWhere(
        (e) => e.name == (map['measurementSystem'] ?? 'metric'),
        orElse: () => MeasurementSystem.metric,
      ),
      lastUpdated: DateTime.parse(map['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Conversion vers Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'language': language.code,
      'region': region.code,
      'timeZone': timeZone.id,
      'dateFormat': dateFormat.name,
      'timeFormat': timeFormat.name,
      'numberFormat': numberFormat.name,
      'currencyFormat': currencyFormat.name,
      'measurementSystem': measurementSystem.name,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Créer une configuration par défaut selon la locale
  factory LocalizationModel.createDefault(String userId, Locale locale) {
    // Détecter la langue à partir de la locale
    AppLanguage language = AppLanguage.french;
    for (final lang in AppLanguage.values) {
      if (lang.code == locale.languageCode) {
        language = lang;
        break;
      }
    }

    // Détecter la région à partir de la locale
    AppRegion region = AppRegion.france;
    for (final reg in AppRegion.values) {
      if (reg.code == locale.countryCode) {
        region = reg;
        break;
      }
    }

    // Configurer les formats par défaut selon la région
    DateFormat dateFormat = DateFormat.ddMMyyyy;
    TimeFormat timeFormat = TimeFormat.hhMm24;
    NumberFormat numberFormat = NumberFormat.spaceComma;
    CurrencyFormat currencyFormat = CurrencyFormat.eurSymbolBefore;
    MeasurementSystem measurementSystem = MeasurementSystem.metric;

    // Adapter selon la région
    if (region == AppRegion.unitedStates || region == AppRegion.unitedKingdom) {
      dateFormat = DateFormat.mmDDyyyy;
      numberFormat = NumberFormat.commaPeriod;
      measurementSystem = MeasurementSystem.imperial;
    }

    if (region == AppRegion.unitedStates) {
      currencyFormat = CurrencyFormat.usdSymbolBefore;
      timeFormat = TimeFormat.hhmmA12;
    } else if (region == AppRegion.unitedKingdom) {
      currencyFormat = CurrencyFormat.gbpSymbolBefore;
      timeFormat = TimeFormat.hhMm24;
    }

    // Détecter le fuseau horaire par défaut
    TimeZone timeZone = TimeZone.europeParis;
    if (region == AppRegion.unitedStates) {
      timeZone = TimeZone.americaNewYork;
    } else if (region == AppRegion.unitedKingdom) {
      timeZone = TimeZone.europeLondon;
    }

    return LocalizationModel(
      userId: userId,
      language: language,
      region: region,
      timeZone: timeZone,
      dateFormat: dateFormat,
      timeFormat: timeFormat,
      numberFormat: numberFormat,
      currencyFormat: currencyFormat,
      measurementSystem: measurementSystem,
      lastUpdated: DateTime.now(),
    );
  }

  // Mettre à jour la langue
  LocalizationModel updateLanguage(AppLanguage newLanguage) {
    return copyWith(
      language: newLanguage,
      lastUpdated: DateTime.now(),
    );
  }

  // Mettre à jour la région
  LocalizationModel updateRegion(AppRegion newRegion) {
    // Mettre à jour les formats associés à la région
    DateFormat newDateFormat = dateFormat;
    TimeFormat newTimeFormat = timeFormat;
    NumberFormat newNumberFormat = numberFormat;
    CurrencyFormat newCurrencyFormat = currencyFormat;
    MeasurementSystem newMeasurementSystem = measurementSystem;

    if (newRegion == AppRegion.unitedStates || newRegion == AppRegion.unitedKingdom) {
      newDateFormat = DateFormat.mmDDyyyy;
      newNumberFormat = NumberFormat.commaPeriod;
      newMeasurementSystem = MeasurementSystem.imperial;
    } else {
      newDateFormat = DateFormat.ddMMyyyy;
      newNumberFormat = NumberFormat.spaceComma;
      newMeasurementSystem = MeasurementSystem.metric;
    }

    if (newRegion == AppRegion.unitedStates) {
      newCurrencyFormat = CurrencyFormat.usdSymbolBefore;
      newTimeFormat = TimeFormat.hhmmA12;
    } else if (newRegion == AppRegion.unitedKingdom) {
      newCurrencyFormat = CurrencyFormat.gbpSymbolBefore;
      newTimeFormat = TimeFormat.hhMm24;
    } else {
      newCurrencyFormat = CurrencyFormat.eurSymbolBefore;
      newTimeFormat = TimeFormat.hhMm24;
    }

    return copyWith(
      region: newRegion,
      dateFormat: newDateFormat,
      timeFormat: newTimeFormat,
      numberFormat: newNumberFormat,
      currencyFormat: newCurrencyFormat,
      measurementSystem: newMeasurementSystem,
      lastUpdated: DateTime.now(),
    );
  }

  // Mettre à jour le fuseau horaire
  LocalizationModel updateTimeZone(TimeZone newTimeZone) {
    return copyWith(
      timeZone: newTimeZone,
      lastUpdated: DateTime.now(),
    );
  }

  // Formater une date selon les préférences
  String formatDate(DateTime date) {
    switch (dateFormat) {
      case DateFormat.ddMMyyyy:
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      case DateFormat.mmDDyyyy:
        return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
      case DateFormat.yyyyMMdd:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      case DateFormat.mmDDyy:
        return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
      case DateFormat.ddMMyy:
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
    }
  }

  // Formater une heure selon les préférences
  String formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;

    switch (timeFormat) {
      case TimeFormat.hhMm24:
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      case TimeFormat.hhMm12:
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
      case TimeFormat.hhmmA12:
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
      case TimeFormat.hhMm24Alt:
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
  }

  // Formater un nombre selon les préférences
  String formatNumber(double number) {
    final parts = number.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += numberFormat.thousandsSeparator;
      }
      formattedInteger += integerPart[i];
    }

    switch (numberFormat) {
      case NumberFormat.commaPeriod:
        return '$formattedInteger.$decimalPart';
      case NumberFormat.periodComma:
        return '$formattedInteger,$decimalPart';
      case NumberFormat.spaceComma:
        return '$formattedInteger,$decimalPart';
      case NumberFormat.spacePeriod:
        return '$formattedInteger.$decimalPart';
      case NumberFormat.apostropheComma:
        return '$formattedInteger,$decimalPart';
    }
  }

  // Formater un prix selon les préférences
  String formatCurrency(double amount) {
    final formattedNumber = formatNumber(amount);
    
    switch (currencyFormat) {
      case CurrencyFormat.eurSymbolBefore:
        return '€$formattedNumber';
      case CurrencyFormat.eurSymbolAfter:
        return '$formattedNumber€';
      case CurrencyFormat.eurCodeBefore:
        return 'EUR $formattedNumber';
      case CurrencyFormat.eurCodeAfter:
        return '$formattedNumber EUR';
      case CurrencyFormat.usdSymbolBefore:
        return '\$$formattedNumber';
      case CurrencyFormat.usdSymbolAfter:
        return '$formattedNumber\$';
      case CurrencyFormat.usdCodeBefore:
        return 'USD $formattedNumber';
      case CurrencyFormat.usdCodeAfter:
        return '$formattedNumber USD';
      case CurrencyFormat.gbpSymbolBefore:
        return '£$formattedNumber';
      case CurrencyFormat.gbpSymbolAfter:
        return '$formattedNumber£';
      case CurrencyFormat.gbpCodeBefore:
        return 'GBP $formattedNumber';
      case CurrencyFormat.gbpCodeAfter:
        return '$formattedNumber GBP';
    }
  }

  // Obtenir le symbole monétaire
  String getCurrencySymbol() {
    switch (currencyFormat) {
      case CurrencyFormat.eurSymbolBefore:
      case CurrencyFormat.eurSymbolAfter:
      case CurrencyFormat.eurCodeBefore:
      case CurrencyFormat.eurCodeAfter:
        return '€';
      case CurrencyFormat.usdSymbolBefore:
      case CurrencyFormat.usdSymbolAfter:
      case CurrencyFormat.usdCodeBefore:
      case CurrencyFormat.usdCodeAfter:
        return '\$';
      case CurrencyFormat.gbpSymbolBefore:
      case CurrencyFormat.gbpSymbolAfter:
      case CurrencyFormat.gbpCodeBefore:
      case CurrencyFormat.gbpCodeAfter:
        return '£';
    }
  }

  // Obtenir le code monétaire
  String getCurrencyCode() {
    switch (currencyFormat) {
      case CurrencyFormat.eurSymbolBefore:
      case CurrencyFormat.eurSymbolAfter:
      case CurrencyFormat.eurCodeBefore:
      case CurrencyFormat.eurCodeAfter:
        return 'EUR';
      case CurrencyFormat.usdSymbolBefore:
      case CurrencyFormat.usdSymbolAfter:
      case CurrencyFormat.usdCodeBefore:
      case CurrencyFormat.usdCodeAfter:
        return 'USD';
      case CurrencyFormat.gbpSymbolBefore:
      case CurrencyFormat.gbpSymbolAfter:
      case CurrencyFormat.gbpCodeBefore:
      case CurrencyFormat.gbpCodeAfter:
        return 'GBP';
    }
  }

  // Copie avec modification
  LocalizationModel copyWith({
    String? userId,
    AppLanguage? language,
    AppRegion? region,
    TimeZone? timeZone,
    DateFormat? dateFormat,
    TimeFormat? timeFormat,
    NumberFormat? numberFormat,
    CurrencyFormat? currencyFormat,
    MeasurementSystem? measurementSystem,
    DateTime? lastUpdated,
  }) {
    return LocalizationModel(
      userId: userId ?? this.userId,
      language: language ?? this.language,
      region: region ?? this.region,
      timeZone: timeZone ?? this.timeZone,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      numberFormat: numberFormat ?? this.numberFormat,
      currencyFormat: currencyFormat ?? this.currencyFormat,
      measurementSystem: measurementSystem ?? this.measurementSystem,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// Énumération pour les langues supportées
enum AppLanguage {
  french(
    code: 'fr',
    name: 'Français',
    nativeName: 'Français',
    flag: '🇫🇷',
    rtl: false,
  ),
  english(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    flag: '🇬🇧',
    rtl: false,
  ),
  spanish(
    code: 'es',
    name: 'Español',
    nativeName: 'Español',
    flag: '🇪🇸',
    rtl: false,
  ),
  german(
    code: 'de',
    name: 'Deutsch',
    nativeName: 'Deutsch',
    flag: '🇩🇪',
    rtl: false,
  ),
  italian(
    code: 'it',
    name: 'Italiano',
    nativeName: 'Italiano',
    flag: '🇮🇹',
    rtl: false,
  ),
  portuguese(
    code: 'pt',
    name: 'Português',
    nativeName: 'Português',
    flag: '🇵🇹',
    rtl: false,
  ),
  arabic(
    code: 'ar',
    name: 'العربية',
    nativeName: 'العربية',
    flag: '🇸🇦',
    rtl: true,
  ),
  chinese(
    code: 'zh',
    name: '中文',
    nativeName: '中文',
    flag: '🇨🇳',
    rtl: false,
  ),
  japanese(
    code: 'ja',
    name: '日本語',
    nativeName: '日本語',
    flag: '🇯🇵',
    rtl: false,
  ),
  russian(
    code: 'ru',
    name: 'Русский',
    nativeName: 'Русский',
    flag: '🇷🇺',
    rtl: false,
  );

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.rtl,
  });

  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool rtl;

  // Obtenir une langue par son code
  static AppLanguage? getByCode(String code) {
    try {
      return AppLanguage.values.firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }

  // Obtenir la locale Flutter
  Locale get flutterLocale {
    if (rtl) {
      return Locale(code, 'AR'); // Forcer RTL pour l'arabe
    }
    return Locale(code);
  }
}

// Énumération pour les régions supportées
enum AppRegion {
  france(
    code: 'FR',
    name: 'France',
    currency: 'EUR',
    phoneCode: '+33',
    flag: '🇫🇷',
  ),
  belgium(
    code: 'BE',
    name: 'Belgique',
    currency: 'EUR',
    phoneCode: '+32',
    flag: '🇧🇪',
  ),
  switzerland(
    code: 'CH',
    name: 'Suisse',
    currency: 'CHF',
    phoneCode: '+41',
    flag: '🇨🇭',
  ),
  canada(
    code: 'CA',
    name: 'Canada',
    currency: 'CAD',
    phoneCode: '+1',
    flag: '🇨🇦',
  ),
  unitedStates(
    code: 'US',
    name: 'États-Unis',
    currency: 'USD',
    phoneCode: '+1',
    flag: '🇺🇸',
  ),
  unitedKingdom(
    code: 'GB',
    name: 'Royaume-Uni',
    currency: 'GBP',
    phoneCode: '+44',
    flag: '🇬🇧',
  ),
  germany(
    code: 'DE',
    name: 'Allemagne',
    currency: 'EUR',
    phoneCode: '+49',
    flag: '🇩🇪',
  ),
  spain(
    code: 'ES',
    name: 'Espagne',
    currency: 'EUR',
    phoneCode: '+34',
    flag: '🇪🇸',
  ),
  italy(
    code: 'IT',
    name: 'Italie',
    currency: 'EUR',
    phoneCode: '+39',
    flag: '🇮🇹',
  ),
  portugal(
    code: 'PT',
    name: 'Portugal',
    currency: 'EUR',
    phoneCode: '+351',
    flag: '🇵🇹',
  );

  const AppRegion({
    required this.code,
    required this.name,
    required this.currency,
    required this.phoneCode,
    required this.flag,
  });

  final String code;
  final String name;
  final String currency;
  final String phoneCode;
  final String flag;

  // Obtenir une région par son code
  static AppRegion? getByCode(String code) {
    try {
      return AppRegion.values.firstWhere((region) => region.code == code);
    } catch (e) {
      return null;
    }
  }
}

// Énumération pour les fuseaux horaires
enum TimeZone {
  europeParis(
    id: 'Europe/Paris',
    name: 'Paris',
    offset: '+1',
    country: 'France',
  ),
  europeLondon(
    id: 'Europe/London',
    name: 'Londres',
    offset: '+0',
    country: 'Royaume-Uni',
  ),
  europeBerlin(
    id: 'Europe/Berlin',
    name: 'Berlin',
    offset: '+1',
    country: 'Allemagne',
  ),
  americaNewYork(
    id: 'America/New_York',
    name: 'New York',
    offset: '-5',
    country: 'États-Unis',
  ),
  americaLosAngeles(
    id: 'America/Los_Angeles',
    name: 'Los Angeles',
    offset: '-8',
    country: 'États-Unis',
  ),
  americaToronto(
    id: 'America/Toronto',
    name: 'Toronto',
    offset: '-5',
    country: 'Canada',
  ),
  asiaTokyo(
    id: 'Asia/Tokyo',
    name: 'Tokyo',
    offset: '+9',
    country: 'Japon',
  ),
  asiaShanghai(
    id: 'Asia/Shanghai',
    name: 'Shanghai',
    offset: '+8',
    country: 'Chine',
  ),
  australiaSydney(
    id: 'Australia/Sydney',
    name: 'Sydney',
    offset: '+11',
    country: 'Australie',
  );

  const TimeZone({
    required this.id,
    required this.name,
    required this.offset,
    required this.country,
  });

  final String id;
  final String name;
  final String offset;
  final String country;

  // Obtenir un fuseau horaire par son ID
  static TimeZone? getById(String id) {
    try {
      return TimeZone.values.firstWhere((tz) => tz.id == id);
    } catch (e) {
      return null;
    }
  }
}

// Énumération pour les formats de date
enum DateFormat {
  ddMMyyyy(name: 'dd/MM/yyyy', example: '25/12/2023'),
  mmDDyyyy(name: 'MM/dd/yyyy', example: '12/25/2023'),
  yyyyMMdd(name: 'yyyy-MM-dd', example: '2023-12-25'),
  mmDDyy(name: 'MM/dd/yy', example: '12/25/23'),
  ddMMyy(name: 'dd/MM/yy', example: '25/12/23');

  const DateFormat({required this.name, required this.example});

  final String name;
  final String example;
}

// Énumération pour les formats d'heure
enum TimeFormat {
  hhMm24(name: 'HH:mm', example: '14:30'),
  hhMm12(name: 'HH:mm', example: '14:30'),
  hhmmA12(name: 'hh:mm A', example: '02:30 PM'),
  hhMm24Alt(name: 'HH:mm', example: '14:30');

  const TimeFormat({required this.name, required this.example});

  final String name;
  final String example;

  bool get is12Hour => this == TimeFormat.hhmmA12;
}

// Énumération pour les formats de nombre
enum NumberFormat {
  commaPeriod(
    name: 'comma_period',
    thousandsSeparator: ',',
    decimalSeparator: '.',
    example: '1,234.56',
  ),
  periodComma(
    name: 'period_comma',
    thousandsSeparator: '.',
    decimalSeparator: ',',
    example: '1.234,56',
  ),
  spaceComma(
    name: 'space_comma',
    thousandsSeparator: ' ',
    decimalSeparator: ',',
    example: '1 234,56',
  ),
  spacePeriod(
    name: 'space_period',
    thousandsSeparator: ' ',
    decimalSeparator: '.',
    example: '1 234.56',
  ),
  apostropheComma(
    name: 'apostrophe_comma',
    thousandsSeparator: '\'',
    decimalSeparator: ',',
    example: '1\'234,56',
  );

  const NumberFormat({
    required this.name,
    required this.thousandsSeparator,
    required this.decimalSeparator,
    required this.example,
  });

  final String name;
  final String thousandsSeparator;
  final String decimalSeparator;
  final String example;
}

// Énumération pour les formats de devise
enum CurrencyFormat {
  eurSymbolBefore(name: 'EUR_symbol_before', example: '€1,234.56'),
  eurSymbolAfter(name: 'EUR_symbol_after', example: '1,234.56€'),
  eurCodeBefore(name: 'EUR_code_before', example: 'EUR 1,234.56'),
  eurCodeAfter(name: 'EUR_code_after', example: '1,234.56 EUR'),
  usdSymbolBefore(name: 'USD_symbol_before', example: '\$1,234.56'),
  usdSymbolAfter(name: 'USD_symbol_after', example: '1,234.56\$'),
  usdCodeBefore(name: 'USD_code_before', example: 'USD 1,234.56'),
  usdCodeAfter(name: 'USD_code_after', example: '1,234.56 USD'),
  gbpSymbolBefore(name: 'GBP_symbol_before', example: '£1,234.56'),
  gbpSymbolAfter(name: 'GBP_symbol_after', example: '1,234.56£'),
  gbpCodeBefore(name: 'GBP_code_before', example: 'GBP 1,234.56'),
  gbpCodeAfter(name: 'GBP_code_after', example: '1,234.56 GBP');

  const CurrencyFormat({required this.name, required this.example});

  final String name;
  final String example;
}

// Énumération pour les systèmes de mesure
enum MeasurementSystem {
  metric(name: 'metric', distanceUnit: 'km', weightUnit: 'kg', temperatureUnit: '°C'),
  imperial(name: 'imperial', distanceUnit: 'mi', weightUnit: 'lb', temperatureUnit: '°F');

  const MeasurementSystem({
    required this.name,
    required this.distanceUnit,
    required this.weightUnit,
    required this.temperatureUnit,
  });

  final String name;
  final String distanceUnit;
  final String weightUnit;
  final String temperatureUnit;
}
