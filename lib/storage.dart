import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static const _kHome = 'homeScore',
      _kAway = 'awayScore',
      _kHomeName = 'homeName',
      _kAwayName = 'awayName',
      _kTheme = 'themeKey',
      _kLocale = 'locale';

  static Future<void> saveScores(int home, int away) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kHome, home);
    await p.setInt(_kAway, away);
  }

  static Future<(int, int)> loadScores() async {
    final p = await SharedPreferences.getInstance();
    return (p.getInt(_kHome) ?? 0, p.getInt(_kAway) ?? 0);
  }

  static Future<void> saveNames(String home, String away) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kHomeName, home);
    await p.setString(_kAwayName, away);
  }

  static Future<(String, String)> loadNames() async {
    final p = await SharedPreferences.getInstance();
    return (
      p.getString(_kHomeName) ?? 'Home',
      p.getString(_kAwayName) ?? 'Away',
    );
  }

  static Future<void> saveTheme(String key) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kTheme, key);
  }

  static Future<String> loadTheme() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kTheme) ?? 'classic';
  }

  static Future<void> saveLocale(String code) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocale, code);
  }

  static Future<String> loadLocale() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kLocale) ?? 'en';
  }

  static Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kHome);
    await p.remove(_kAway);
    await p.remove(_kTheme);
  }
}
