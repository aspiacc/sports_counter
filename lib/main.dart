import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helper.dart';
import 'storage.dart';
// import 'package:flutter/services.dart'; // Opcional si querés HapticFeedback

bool get _adsSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_adsSupported) {
    // ✅ Marca tu dispositivo como "test" para que AdMob muestre Test Ads
    // Reemplazá ABCDEF0123456789 por el hash que verás en la consola/logcat
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: ['ABCDEF0123456789']), // TODO: put your real test device ID
    );

    await MobileAds.instance.initialize();
  }
  runApp(const ScoreApp());
}

class ScoreApp extends StatelessWidget {
  const ScoreApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sports Counter',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.red),
      home: const ScoreHome(),
    );
  }
}

class ScoreHome extends StatefulWidget {
  const ScoreHome({super.key});
  @override
  State<ScoreHome> createState() => _ScoreHomeState();
}

class _ScoreHomeState extends State<ScoreHome> {
  int home = 0, away = 0;
  String homeName = 'Home', awayName = 'Away';
  final List<(String, int)> _history = [];
  BannerAd? _banner;
  InterstitialAd? _interstitial;

  @override
  void initState() {
    super.initState();
    _loadState();
    if (_adsSupported) {
      _loadBanner();
      _loadInterstitial();
    }
  }

  Future<void> _loadState() async {
    final scores = await Storage.loadScores();
    final names = await Storage.loadNames();
    setState(() {
      home = scores.$1;
      away = scores.$2;
      homeName = names.$1;
      awayName = names.$2;
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
    });
    await Storage.reset();
  }

  Future<void> _openSettings() async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (ctx) {
        final hc = TextEditingController(text: homeName);
        final ac = TextEditingController(text: awayName);
        return AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: hc, decoration: const InputDecoration(labelText: 'Home name')),
              TextField(controller: ac, decoration: const InputDecoration(labelText: 'Away name')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, (hc.text, ac.text)), child: const Text('Save')),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        homeName = result.$1.trim().isEmpty ? 'Home' : result.$1.trim();
        awayName = result.$2.trim().isEmpty ? 'Away' : result.$2.trim();
      });
      await Storage.saveNames(homeName, awayName);
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
          Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('$score', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(onPressed: () => onDelta(1), child: const Text('+1')),
              FilledButton(onPressed: () => onDelta(2), child: const Text('+2')),
              FilledButton(onPressed: () => onDelta(3), child: const Text('+3')),
              OutlinedButton(onPressed: () => onDelta(-1), child: const Text('–1')),
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
    final bannerWidget = _banner == null
        ? const SizedBox(height: 0)
        : SizedBox(height: _banner!.size.height.toDouble(), child: AdWidget(ad: _banner!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sports Counter'),
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: _openSettings)],
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
                FilledButton.icon(onPressed: _undo, icon: const Icon(Icons.undo), label: const Text('Undo')),
                const SizedBox(width: 8),
                OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.restart_alt), label: const Text('Reset')),
                const Spacer(),
              ],
            ),
          ),
          bannerWidget,
        ],
      ),
    );
  }
}
