import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('en'), Locale('es')];

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Sports Counter',
      'settingsTitle': 'Settings',
      'homeNameLabel': 'Home name',
      'awayNameLabel': 'Away name',
      'themeFieldLabel': 'Color theme',
      'languageFieldLabel': 'Language',
      'cancel': 'Cancel',
      'save': 'Save',
      'undo': 'Undo',
      'reset': 'Reset',
      'themeClassic': 'Classic red',
      'themeDark': 'Dark',
      'themeGreen': 'Field green',
      'themeBlue': 'Midnight blue',
      'languageEnglish': 'English',
      'languageSpanish': 'Spanish',
    },
    'es': {
      'appTitle': 'Contador Deportivo',
      'settingsTitle': 'Configuración',
      'homeNameLabel': 'Nombre local',
      'awayNameLabel': 'Nombre visitante',
      'themeFieldLabel': 'Tema de colores',
      'languageFieldLabel': 'Idioma',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'undo': 'Deshacer',
      'reset': 'Reiniciar',
      'themeClassic': 'Rojo clásico',
      'themeDark': 'Oscuro',
      'themeGreen': 'Verde cancha',
      'themeBlue': 'Azul nocturno',
      'languageEnglish': 'Inglés',
      'languageSpanish': 'Español',
    },
  };

  String _text(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key] ??
        '';
  }

  String get appTitle => _text('appTitle');
  String get settingsTitle => _text('settingsTitle');
  String get homeNameLabel => _text('homeNameLabel');
  String get awayNameLabel => _text('awayNameLabel');
  String get themeFieldLabel => _text('themeFieldLabel');
  String get languageFieldLabel => _text('languageFieldLabel');
  String get cancel => _text('cancel');
  String get save => _text('save');
  String get undo => _text('undo');
  String get reset => _text('reset');

  String themeName(String key) {
    switch (key) {
      case 'dark':
        return _text('themeDark');
      case 'green':
        return _text('themeGreen');
      case 'blue':
        return _text('themeBlue');
      case 'classic':
      default:
        return _text('themeClassic');
    }
  }

  String languageName(String code) {
    switch (code) {
      case 'es':
        return _text('languageSpanish');
      case 'en':
      default:
        return _text('languageEnglish');
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
