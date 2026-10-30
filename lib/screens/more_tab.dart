import 'package:flutter/material.dart';

import '../data.dart';
import '../game.dart';
import '../widgets.dart';

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
            const SectionTitle('Улучшения'),
            for (final u in upgradeDefs) _UpgradeCard(u: u),
            const SectionTitle('Разное'),
            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.collections_bookmark),
                    title: const Text('Альбом находок'),
                    subtitle: Text('Редкие и легендарные: ${game.found.length} из $rareTotal'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const CollectionScreen())),
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: const Text('Журнал'),
                    subtitle: const Text('Все покупки, продажи и события'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const JournalScreen())),
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Как играть'),
                    onTap: () => showTutorial(context),
                  ),
                ],
              ),
            ),
            const SectionTitle('Статистика'),
            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(child: StatTile('Дней в деле', '${game.day}')),
                      Expanded(child: StatTile('Лотов куплено', '${game.lotsWon}')),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: StatTile('Заработано', rub(game.totalEarned))),
                      Expanded(child: StatTile('Потрачено', rub(game.totalSpent))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: StatTile('Лучшая находка', game.bestFindName.isEmpty ? '—' : game.bestFindName)),
                      Expanded(child: StatTile('Её оценка', game.bestFind == 0 ? '—' : rub(game.bestFind))),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => _confirmReset(context),
              icon: Icon(Icons.restart_alt, color: cs.error),
              label: Text('Начать заново', style: TextStyle(color: cs.error)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Начать заново?'),
        content: const Text('Весь прогресс, деньги и склад будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Начать заново')),
        ],
      ),
    );
    if (ok == true) game.reset();
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
        child: Text(rub(u.price)),
      );
    }
    String sub = u.desc;
    if (locked) {
      final req = upgradeDefs.firstWhere((x) => x.id == u.requires);
      sub = '$sub. Сначала: ${req.name}';
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
      appBar: AppBar(title: const Text('Альбом находок')),
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
      appBar: AppBar(title: const Text('Журнал')),
      body: game.journal.isEmpty
          ? const Center(child: Text('Пока пусто'))
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
                      SizedBox(width: 56, child: Text('день ${e.day}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))),
                      Expanded(child: Text(e.text)),
                      if (a != null)
                        Text('${a > 0 ? '+' : ''}${rub(a)}',
                            style: TextStyle(fontWeight: FontWeight.w700, color: a > 0 ? Colors.green : cs.onSurface)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
