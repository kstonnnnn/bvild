import 'package:flutter/material.dart';

import 'game.dart';
import 'screens/shell.dart';
import 'settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await settings.load();
  await game.load();
  if (game.tutorialSeen && !settings.onboarded) {
    settings.onboarded = true;
    settings.save();
  }
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
          home: const Shell(),
        );
      },
    );
  }
}
