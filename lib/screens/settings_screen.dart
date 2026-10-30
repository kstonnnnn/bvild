import 'package:flutter/material.dart';

import '../game.dart';
import '../settings.dart';
import '../widgets.dart';
import '../updates.dart';
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
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          final cs = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              const SectionTitle('Profile'),
              TextField(
                controller: _name,
                maxLength: 24,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Warehouse name',
                  hintText: 'My Warehouse',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => settings.set((s) => s.storeName = v),
              ),
              const SectionTitle('Appearance'),
              _label(context, 'Theme'),
              _choices(themeNames, settings.theme, (i) => settings.set((s) => s.theme = i)),
              const SizedBox(height: 14),
              _label(context, 'Accent color'),
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
              _label(context, 'Text size'),
              _choices(textSizeNames, settings.textSize, (i) => settings.set((s) => s.textSize = i)),
              const SectionTitle('Gameplay'),
              _label(context, 'Auction speed'),
              _choices(speedNames, settings.auctionSpeed, (i) => settings.set((s) => s.auctionSpeed = i)),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('How many seconds you get to respond after each bid: 6, 4 or 2.6.',
                    style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
              ),
              const SizedBox(height: 14),
              _label(context, 'Difficulty'),
              _choices(difficultyNames, settings.difficulty, (i) => settings.set((s) => s.difficulty = i)),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                    '${difficultyHints[settings.difficulty]}. Starting cash (${cash(settings.startMoney)}) only applies to a new game.',
                    style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Confirm before pawning'),
                subtitle: const Text('So you don\'t sell something valuable for half by accident'),
                value: settings.confirmQuickSell,
                onChanged: (v) => settings.set((s) => s.confirmQuickSell = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vibration'),
                subtitle: const Text('Feedback on bids, wins and finds'),
                value: settings.haptics,
                onChanged: (v) => settings.set((s) => s.haptics = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('On-screen tips'),
                subtitle: const Text('Short hints you can dismiss'),
                value: settings.tips,
                onChanged: (v) => settings.set((s) => s.tips = v),
              ),
              const SectionTitle('Tutorial'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.school),
                title: const Text('Replay the intro'),
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const OnboardingScreen())),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lightbulb_outline),
                title: const Text('Show all tips again'),
                onTap: () {
                  settings.resetTips();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tips are back on')));
                },
              ),
              const SectionTitle('About'),
              if (updatesSupported)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.system_update),
                  title: const Text('Check for updates'),
                  subtitle: Text('Installed: $appVersion (build $appBuild)'),
                  onTap: () => checkForUpdates(context),
                ),
              if (itchUrl.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.storefront),
                  title: const Text('Game page on itch.io'),
                  subtitle: const Text('Leave a rating or a comment'),
                  onTap: () => openLink(itchUrl),
                ),
              const SectionTitle('Data'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.restart_alt, color: cs.error),
                title: Text('Start a new game', style: TextStyle(color: cs.error)),
                subtitle: Text('Difficulty: ${difficultyNames[settings.difficulty].toLowerCase()}'),
                onTap: () => confirmNewGame(context),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text('Lost Luggage · version $appVersion',
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
      title: const Text('Start over?'),
      content: const Text('All progress, cash and storage will be wiped. Your settings stay.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Start over')),
      ],
    ),
  );
  if (ok == true) game.reset();
}
