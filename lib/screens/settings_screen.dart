import 'package:flutter/material.dart';

import '../game.dart';
import '../settings.dart';
import '../widgets.dart';
import 'onboarding.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name = TextEditingController(text: settings.storeName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          final cs = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              const SectionTitle('Профиль'),
              TextField(
                controller: _name,
                maxLength: 24,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Название склада',
                  hintText: 'Мой склад',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => settings.set((s) => s.storeName = v),
              ),
              const SectionTitle('Оформление'),
              _label(context, 'Тема'),
              _choices(themeNames, settings.theme, (i) => settings.set((s) => s.theme = i)),
              const SizedBox(height: 14),
              _label(context, 'Цвет интерфейса'),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < accentSeeds.length; i++)
                    Tooltip(
                      message: accentNames[i],
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => settings.set((s) => s.accent = i),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: accentSeeds[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: settings.accent == i ? cs.onSurface : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: settings.accent == i ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _label(context, 'Размер текста'),
              _choices(textSizeNames, settings.textSize, (i) => settings.set((s) => s.textSize = i)),
              const SectionTitle('Игра'),
              _label(context, 'Скорость торгов'),
              _choices(speedNames, settings.auctionSpeed, (i) => settings.set((s) => s.auctionSpeed = i)),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Сколько секунд даётся на ответ после каждой ставки: 6, 4 или 2,6.',
                    style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
              ),
              const SizedBox(height: 14),
              _label(context, 'Сложность'),
              _choices(difficultyNames, settings.difficulty, (i) => settings.set((s) => s.difficulty = i)),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                    '${difficultyHints[settings.difficulty]}. Стартовые деньги (${rub(settings.startMoney)}) меняются только в новой игре.',
                    style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Спрашивать перед продажей скупщику'),
                subtitle: const Text('Чтобы случайно не отдать ценную вещь за полцены'),
                value: settings.confirmQuickSell,
                onChanged: (v) => settings.set((s) => s.confirmQuickSell = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Вибрация'),
                subtitle: const Text('Отклик на ставки, победы и находки'),
                value: settings.haptics,
                onChanged: (v) => settings.set((s) => s.haptics = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Подсказки на экранах'),
                subtitle: const Text('Короткие советы, которые можно закрыть'),
                value: settings.tips,
                onChanged: (v) => settings.set((s) => s.tips = v),
              ),
              const SectionTitle('Обучение'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.school),
                title: const Text('Пройти вводное обучение'),
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const OnboardingScreen())),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lightbulb_outline),
                title: const Text('Показать все подсказки заново'),
                onTap: () {
                  settings.resetTips();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Подсказки снова включены')));
                },
              ),
              const SectionTitle('Данные'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.restart_alt, color: cs.error),
                title: Text('Начать новую игру', style: TextStyle(color: cs.error)),
                subtitle: Text('С текущей сложностью: ${difficultyNames[settings.difficulty].toLowerCase()}'),
                onTap: () => confirmNewGame(context),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text('Потерянный багаж · версия 1.1',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _label(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
      );

  Widget _choices(List<String> names, int selected, void Function(int) onPick) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < names.length; i++)
          ChoiceChip(
            label: Text(names[i]),
            selected: selected == i,
            onSelected: (_) => onPick(i),
          ),
      ],
    );
  }
}

Future<void> confirmNewGame(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Начать заново?'),
      content: const Text('Весь прогресс, деньги и склад будут удалены. Настройки сохранятся.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Начать заново')),
      ],
    ),
  );
  if (ok == true) game.reset();
}
