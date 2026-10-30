import 'package:flutter/material.dart';

import 'game.dart';
import 'screens/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await game.load();
  runApp(const LuggageApp());
}

class LuggageApp extends StatelessWidget {
  const LuggageApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFD9971E);
    return MaterialApp(
      title: 'Потерянный багаж',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const Shell(),
    );
  }
}
