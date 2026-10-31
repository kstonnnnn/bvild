import 'package:flutter/widgets.dart';

import 'l10n_ru.dart';
import 'settings.dart';

/// Language codes the game ships with, in the order shown in Settings.
const List<String> languageCodes = ['en', 'ru'];
const List<String> languageNames = ['English', 'Русский'];

/// Translates an English source string into the current language.
/// Placeholders {0}, {1}… are filled from [args] in both languages.
String tr(String en, [List<Object?> args = const []]) {
  var s = en;
  if (settings.lang == 'ru') s = ru[en] ?? en;
  for (var i = 0; i < args.length; i++) {
    s = s.replaceAll('{$i}', '${args[i]}');
  }
  return s;
}

/// Item name used inside a sentence: lower case in English, quoted in Russian.
String inlineName(String name) => settings.lang == 'ru' ? '«$name»' : name.toLowerCase();

/// Picks the system language on first launch.
String systemLanguage() {
  final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return languageCodes.contains(code) ? code : 'en';
}

/// Forces every widget to rebuild so new strings show up right away.
void rebuildAllWidgets() {
  final root = WidgetsBinding.instance.rootElement;
  if (root == null) return;
  void visit(Element e) {
    e.markNeedsBuild();
    e.visitChildren(visit);
  }

  visit(root);
}
