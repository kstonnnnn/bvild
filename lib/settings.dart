import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'i18n.dart';

final AppSettings settings = AppSettings();

/// Filled in by the build pipeline with --dart-define.
const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.3.0');
const int appBuild = int.fromEnvironment('APP_BUILD', defaultValue: 0);
const String itchUrl = String.fromEnvironment('ITCH_URL', defaultValue: '');

const List<Color> accentSeeds = [
  Color(0xFFD9971E),
  Color(0xFF2F6BFF),
  Color(0xFF16A35A),
  Color(0xFFE5383B),
  Color(0xFF7A4DFF),
  Color(0xFF00A3A3),
];
List<String> get accentNames => ['Amber', 'Blue', 'Green', 'Red', 'Purple', 'Teal'].map(tr).toList();
List<String> get themeNames => ['System', 'Light', 'Dark'].map(tr).toList();
List<String> get speedNames => ['Slow', 'Normal', 'Fast'].map(tr).toList();
List<String> get difficultyNames => ['Easy', 'Normal', 'Hardcore'].map(tr).toList();
List<String> get difficultyHints => [
      'More starting cash, cautious rivals, cheaper rent',
      'A balanced game',
      'Little cash, greedy rivals, pricey rent, fakes get returned more often',
    ].map(tr).toList();
List<String> get textSizeNames => ['Small', 'Normal', 'Large'].map(tr).toList();

class AppSettings extends ChangeNotifier {
  static const _key = 'lost_luggage_settings_v1';

  int theme = 0;
  int accent = 0;
  int auctionSpeed = 1;
  int difficulty = 1;
  int textSize = 1;
  bool confirmQuickSell = true;
  bool tips = true;
  bool haptics = true;
  String storeName = '';
  Set<String> seenTips = {};
  bool onboarded = false;
  String lang = 'en';

  ThemeMode get themeMode => const [ThemeMode.system, ThemeMode.light, ThemeMode.dark][theme];
  Color get seed => accentSeeds[accent.clamp(0, accentSeeds.length - 1).toInt()];
  double get textScale => const [0.9, 1.0, 1.15][textSize];
  double get roundTime => const [6.0, 4.0, 2.6][auctionSpeed];
  double get botMult => const [0.85, 1.0, 1.12][difficulty];
  double get rentMult => const [0.7, 1.0, 1.3][difficulty];
  double get complaintChance => const [0.45, 0.65, 0.8][difficulty];
  int get startMoney => const [45000, 30000, 20000][difficulty];
  String get storeTitle => storeName.trim().isEmpty ? tr('My Warehouse') : storeName.trim();

  bool showTip(String id) => tips && !seenTips.contains(id);

  void hideTip(String id) {
    seenTips.add(id);
    changed();
  }

  void resetTips() {
    seenTips.clear();
    tips = true;
    changed();
  }

  void set(void Function(AppSettings s) f) {
    f(this);
    changed();
  }

  void setLang(String code) {
    if (code == lang) return;
    lang = code;
    changed();
    rebuildAllWidgets();
  }

  void tap() {
    if (haptics) HapticFeedback.selectionClick();
  }

  void bump() {
    if (haptics) HapticFeedback.mediumImpact();
  }

  void changed() {
    notifyListeners();
    save();
  }

  Map<String, dynamic> toJson() => {
        'theme': theme,
        'accent': accent,
        'speed': auctionSpeed,
        'diff': difficulty,
        'text': textSize,
        'confirm': confirmQuickSell,
        'tips': tips,
        'haptics': haptics,
        'name': storeName,
        'seen': seenTips.toList(),
        'onb': onboarded,
        'lang': lang,
      };

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_key);
      if (s == null) {
        lang = systemLanguage();
        return;
      }
      final j = jsonDecode(s) as Map<String, dynamic>;
      int gi(String k, int d) => j[k] is num ? (j[k] as num).toInt() : d;
      theme = gi('theme', 0).clamp(0, 2).toInt();
      accent = gi('accent', 0).clamp(0, accentSeeds.length - 1).toInt();
      auctionSpeed = gi('speed', 1).clamp(0, 2).toInt();
      difficulty = gi('diff', 1).clamp(0, 2).toInt();
      textSize = gi('text', 1).clamp(0, 2).toInt();
      confirmQuickSell = j['confirm'] != false;
      tips = j['tips'] != false;
      haptics = j['haptics'] != false;
      storeName = (j['name'] as String?) ?? '';
      seenTips = ((j['seen'] as List?) ?? const []).map((e) => e.toString()).toSet();
      onboarded = j['onb'] == true;
      final l = j['lang'];
      lang = l is String && languageCodes.contains(l) ? l : systemLanguage();
    } catch (e) {
      debugPrint('settings load failed: $e');
      lang = systemLanguage();
    }
  }

  Future<void> save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode(toJson()));
    } catch (e) {
      debugPrint('settings save failed: $e');
    }
  }
}
