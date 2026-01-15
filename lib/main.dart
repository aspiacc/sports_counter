import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helper.dart';
import 'storage.dart';
import 'l10n/app_localizations.dart';
// import 'package:flutter/services.dart'; // Opcional si querés HapticFeedback

bool get _adsSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

const _defaultThemeKey = 'classic';
const _languageCodes = ['en', 'es'];

class _ThemeOption {
  final String key;
  final Color seed;
  final Color background;
  const _ThemeOption(this.key, this.seed, this.background);
}

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12),
      ),
    );
  }
}

const List<_ThemeOption> _themeOptions = [
  _ThemeOption(_defaultThemeKey, Colors.red, Color(0xFFFFF4F5)),
  _ThemeOption('dark', Color(0xFF20232A), Color(0xFF111317)),
  _ThemeOption('green', Color(0xFF0F9D58), Color(0xFFE8F5E9)),
  _ThemeOption('blue', Color(0xFF2962FF), Color(0xFFE3F2FD)),
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_adsSupported) {
    // ✅ Marca tu dispositivo como "test" para que AdMob muestre Test Ads
    // Reemplazá ABCDEF0123456789 por el hash que verás en la consola/logcat
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: ['ABCDEF0123456789'],
      ), // TODO: put your real test device ID
    );

    await MobileAds.instance.initialize();
  }
  runApp(const ScoreApp());
}

class ScoreApp extends StatefulWidget {
  const ScoreApp({super.key});
  @override
  State<ScoreApp> createState() => _ScoreAppState();
}

class _ScoreAppState extends State<ScoreApp> {
  String _localeCode = 'en';

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final code = await Storage.loadLocale();
    if (!mounted) return;
    setState(() => _localeCode = code);
  }

  Future<void> _handleLocaleChanged(String code) async {
    await Storage.saveLocale(code);
    if (!mounted) return;
    setState(() => _localeCode = code);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: Locale(_localeCode),
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.red),
      home: ScoreHome(
        initialLocale: _localeCode,
        onLocaleChanged: _handleLocaleChanged,
      ),
    );
  }
}

class ScoreHome extends StatefulWidget {
  final ValueChanged<String> onLocaleChanged;
  final String initialLocale;
  const ScoreHome({
    super.key,
    required this.onLocaleChanged,
    required this.initialLocale,
  });
  @override
  State<ScoreHome> createState() => _ScoreHomeState();
}

class _ScoreHomeState extends State<ScoreHome> {
  int home = 0, away = 0;
  String homeName = 'Home', awayName = 'Away';
  String _themeKey = _defaultThemeKey;
  late String _localeCode;
  final List<(String, int)> _history = [];
  BannerAd? _banner;
  InterstitialAd? _interstitial;

  @override
  void initState() {
    super.initState();
    _localeCode = widget.initialLocale;
    _loadState();
    if (_adsSupported) {
      _loadBanner();
      _loadInterstitial();
    }
  }

  @override
  void didUpdateWidget(covariant ScoreHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLocale != widget.initialLocale) {
      setState(() {
        _localeCode = widget.initialLocale;
      });
    }
  }

  Future<void> _loadState() async {
    final scores = await Storage.loadScores();
    final names = await Storage.loadNames();
    final theme = await Storage.loadTheme();
    setState(() {
      home = scores.$1;
      away = scores.$2;
      homeName = names.$1;
      awayName = names.$2;
      _themeKey = theme;
    });
  }

  void _loadBanner() {
    final banner = BannerAd(
      size: AdSize.banner,
      adUnitId: AdHelper.bannerAdUnitId,
      listener: BannerAdListener(),
      request: const AdRequest(),
    )..load();
    setState(() => _banner = banner);
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  void _score(String team, int delta) {
    setState(() {
      if (team == 'home') {
        home = (home + delta).clamp(0, 999);
      } else {
        away = (away + delta).clamp(0, 999);
      }
      _history.add((team, delta));
    });
    Storage.saveScores(home, away);
    // Opcional: Haptic feedback
    // HapticFeedback.lightImpact();
  }

  void _undo() {
    if (_history.isEmpty) return;
    final last = _history.removeLast();
    _score(last.$1, -last.$2);
    _history.removeLast();
  }

  void _reset() async {
    setState(() {
      home = 0;
      away = 0;
      _history.clear();
      _themeKey = _defaultThemeKey;
    });
    await Storage.reset();
  }

  Future<void> _openSettings() async {
    final result = await showDialog<(String, String, String, String)>(
      context: context,
      builder: (ctx) {
        final hc = TextEditingController(text: homeName);
        final ac = TextEditingController(text: awayName);
        final l10n = AppLocalizations.of(ctx);
        var selectedLanguage = _localeCode;
        var selectedTheme = _themeKey;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.settingsTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: hc,
                    decoration: InputDecoration(labelText: l10n.homeNameLabel),
                  ),
                  TextField(
                    controller: ac,
                    decoration: InputDecoration(labelText: l10n.awayNameLabel),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTheme,
                    decoration: InputDecoration(
                      labelText: l10n.themeFieldLabel,
                    ),
                    items: _themeOptions.map((opt) {
                      return DropdownMenuItem(
                        value: opt.key,
                        child: Row(
                          children: [
                            _ColorDot(color: opt.background),
                            const SizedBox(width: 6),
                            _ColorDot(color: opt.seed),
                            const SizedBox(width: 8),
                            Text(l10n.themeName(opt.key)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedTheme = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedLanguage,
                    decoration: InputDecoration(
                      labelText: l10n.languageFieldLabel,
                    ),
                    items: _languageCodes
                        .map(
                          (code) => DropdownMenuItem(
                            value: code,
                            child: Text(l10n.languageName(code)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedLanguage = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, (
                    hc.text,
                    ac.text,
                    selectedTheme,
                    selectedLanguage,
                  )),
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        homeName = result.$1.trim().isEmpty ? 'Home' : result.$1.trim();
        awayName = result.$2.trim().isEmpty ? 'Away' : result.$2.trim();
        _themeKey = result.$3;
        _localeCode = result.$4;
      });
      await Storage.saveNames(homeName, awayName);
      await Storage.saveTheme(_themeKey);
      widget.onLocaleChanged(_localeCode);
    }

    _interstitial?.show();
    _interstitial?.dispose();
    _interstitial = null;
    _loadInterstitial();
  }

  Widget _teamColumn(String label, int score, void Function(int) onDelta) {
    return Expanded(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () => onDelta(1),
                child: const Text('+1'),
              ),
              FilledButton(
                onPressed: () => onDelta(2),
                child: const Text('+2'),
              ),
              FilledButton(
                onPressed: () => onDelta(3),
                child: const Text('+3'),
              ),
              OutlinedButton(
                onPressed: () => onDelta(-1),
                child: const Text('–1'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _banner?.dispose();
    _interstitial?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = _themeOptions.firstWhere(
      (opt) => opt.key == _themeKey,
      orElse: () => _themeOptions.first,
    );
    final colorScheme = ColorScheme.fromSeed(
      seedColor: theme.seed,
      brightness: theme.key == 'dark' ? Brightness.dark : Brightness.light,
    );
    final themedData = Theme.of(context).copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: theme.background,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
        ),
      ),
    );
    final bannerWidget = _banner == null
        ? const SizedBox(height: 0)
        : SizedBox(
            height: _banner!.size.height.toDouble(),
            child: AdWidget(ad: _banner!),
          );

    return Theme(
      data: themedData,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openSettings,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  _teamColumn(homeName, home, (d) => _score('home', d)),
                  const VerticalDivider(width: 1),
                  _teamColumn(awayName, away, (d) => _score('away', d)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: _undo,
                    icon: const Icon(Icons.undo),
                    label: Text(l10n.undo),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.restart_alt),
                    label: Text(l10n.reset),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            bannerWidget,
          ],
        ),
      ),
    );
  }
}
