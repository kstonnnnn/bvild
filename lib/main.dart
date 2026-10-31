import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'game.dart';
import 'screens/shell.dart';
import 'screens/splash.dart';
import 'settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Settings are tiny and hold the language, so the loading screen needs them first.
  await settings.load();
  runApp(const LuggageApp());
}

class LuggageApp extends StatelessWidget {
  const LuggageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final seed = settings.seed;
        return MaterialApp(
          title: 'Lost Luggage',
          debugShowCheckedModeBanner: false,
          locale: Locale(settings.lang),
          supportedLocales: const [Locale('en'), Locale('ru')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seed), useMaterial3: true),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
            useMaterial3: true,
          ),
          themeMode: settings.themeMode,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(textScaler: TextScaler.linear(mq.textScaler.scale(1.0) * settings.textScale)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const Boot(),
        );
      },
    );
  }
}

/// Shows the loading screen while the save loads, then fades into the game.
class Boot extends StatefulWidget {
  const Boot({super.key});

  @override
  State<Boot> createState() => _BootState();
}

class _BootState extends State<Boot> {
  bool _loaded = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final minShow = Future<void>.delayed(const Duration(milliseconds: 2400));
    await game.load();
    if (game.tutorialSeen && !settings.onboarded) {
      settings.onboarded = true;
      settings.save();
    }
    if (mounted) setState(() => _loaded = true);
    await minShow;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _done ? const Shell() : SplashScreen(key: const ValueKey('splash'), ready: _loaded),
    );
  }
}
