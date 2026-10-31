import 'package:flutter/material.dart';

import '../data.dart';
import '../game.dart';
import '../i18n.dart';
import '../widgets.dart';
import 'onboarding.dart';
import 'settings_screen.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final rareTotal = itemDefs.where((d) => d.rarity.index >= Rarity.rare.index).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const SectionTitle('Net worth by day'),
            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CapitalChart(values: [...game.capitalHistory, game.capital]),
              ),
            ),
            const SectionTitle('Upgrades'),
            const TipCard('upgrades',
                'Most players buy Shelving first: more space means fewer forced half-price sales. The X-ray scanner pays off if you bid on suitcases a lot.'),
            for (final u in upgradeDefs) _UpgradeCard(u: u),
            const SectionTitle('Other'),
            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.collections_bookmark),
                    title: Text(tr('Collection')),
                    subtitle: Text(tr('Rare and legendary finds: {0} of {1}', [game.found.length, rareTotal])),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const CollectionScreen())),
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text(tr('Ledger')),
                    subtitle: Text(tr('Every purchase, sale and event')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const JournalScreen())),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: Text(tr('Settings')),
                    subtitle: Text(tr('Language, theme, difficulty, auction speed, tips')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
                  ),
                  ListTile(
                    leading: const Icon(Icons.school),
                    title: Text(tr('Tutorial')),
                    subtitle: Text(tr('Replay the intro tutorial')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const OnboardingScreen())),
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: Text(tr('Quick reference')),
                    onTap: () => showTutorial(context),
                  ),
                ],
              ),
            ),
            const SectionTitle('Stats'),
            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(child: StatTile('Days in business', '${game.day}')),
                      Expanded(child: StatTile('Lots won', '${game.lotsWon}')),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: StatTile('Earned', cash(game.totalEarned))),
                      Expanded(child: StatTile('Spent', cash(game.totalSpent))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: StatTile('Best find', game.bestFindName.isEmpty ? '—' : tr(game.bestFindName))),
                      Expanded(child: StatTile('Its value', game.bestFind == 0 ? '—' : cash(game.bestFind))),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => confirmNewGame(context),
              icon: Icon(Icons.restart_alt, color: cs.error),
              label: Text(tr('Start over'), style: TextStyle(color: cs.error)),
            ),
          ],
        );
      },
    );
  }

}

class _UpgradeCard extends StatelessWidget {
  final UpgradeDef u;
  const _UpgradeCard({required this.u});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final owned = game.has(u.id);
    final locked = u.requires != null && !game.has(u.requires!);
    Widget trailing;
    if (owned) {
      trailing = Icon(Icons.check_circle, color: cs.primary);
    } else {
      trailing = FilledButton.tonal(
        onPressed: game.canBuy(u) ? () => game.buy(u) : null,
        child: Text(cash(u.price)),
      );
    }
    String sub = u.desc;
    if (locked) {
      final req = upgradeDefs.firstWhere((x) => x.id == u.requires);
      sub = '$sub. ${tr('Requires: {0}', [req.name])}';
    }
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: owned ? cs.primaryContainer.withAlpha(120) : cs.surfaceContainerLow,
      child: ListTile(
        leading: Icon(u.icon),
        title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sub),
        trailing: trailing,
      ),
    );
  }
}

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final defs = itemDefs.where((d) => d.rarity.index >= Rarity.rare.index).toList()
      ..sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
    return Scaffold(
      appBar: AppBar(title: Text(tr('Collection'))),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: defs.length,
        itemBuilder: (context, i) {
          final d = defs[i];
          final got = game.found.contains(d.id);
          final c = rarityColors[d.rarity.index];
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: got ? c.withAlpha(35) : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: got ? c : cs.outlineVariant),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(got ? d.iconData : Icons.help_outline, size: 36, color: got ? c : cs.onSurfaceVariant),
                const SizedBox(height: 8),
                Text(
                  got ? d.name : '???',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: got ? null : cs.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(rarityLabels[d.rarity.index], style: TextStyle(fontSize: 11, color: c)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Ledger'))),
      body: game.journal.isEmpty
          ? Center(child: Text(tr('Nothing yet')))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: game.journal.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final e = game.journal[i];
                final a = e.amount;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(width: 56, child: Text(tr('day {0}', [e.day]), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))),
                      Expanded(child: Text(e.text)),
                      if (a != null)
                        Text('${a > 0 ? '+' : ''}${cash(a)}',
                            style: TextStyle(fontWeight: FontWeight.w700, color: a > 0 ? Colors.green : cs.onSurface)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
