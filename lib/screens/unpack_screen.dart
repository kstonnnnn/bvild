import 'package:flutter/material.dart';

import '../data.dart';
import '../game.dart';
import '../i18n.dart';
import '../models.dart';
import '../settings.dart';
import '../widgets.dart';

class UnpackScreen extends StatefulWidget {
  final Lot lot;
  const UnpackScreen({super.key, required this.lot});

  @override
  State<UnpackScreen> createState() => _UnpackScreenState();
}

class _UnpackScreenState extends State<UnpackScreen> {
  int shown = 0;

  Lot get lot => widget.lot;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final all = shown >= lot.items.length;
    final found = lot.items.take(shown).where((i) => !i.contraband).fold<int>(0, (s, i) => s + i.estimate);
    final paid = lot.finalPrice ?? 0;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Unpacking · {0} of {1}', [shown, lot.items.length]))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            elevation: 0,
            color: cs.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: StatTile('Paid', cash(paid))),
                  Expanded(child: StatTile('Found', cash(found))),
                  Expanded(child: StatTile('Profit', '${found - paid >= 0 ? '+' : ''}${cash(found - paid)}')),

                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const TipCard('unpack',
              'Items come out one at a time. The price is a rough estimate. If it says not authenticated, the real value could be much lower.'),
          for (var i = 0; i < lot.items.length; i++)
            if (i < shown) _RevealTile(key: ValueKey(lot.items[i].uid), item: lot.items[i]) else _HiddenTile(index: i),
          if (all) ...[
            const SizedBox(height: 8),
            Text(
              found >= paid ? tr('By the rough estimate, this lot paid off.') : tr('In the red for now. Something may turn out to be worth more after an appraisal.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: found >= paid ? Colors.green : cs.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: all
              ? FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: () {
                    game.storeLot(lot);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.inventory),
                  label: Text(tr('Move to storage')),
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                        onPressed: () {
                          final nx = lot.items[shown];
                          if (nx.def.rarity.index >= Rarity.rare.index) {
                            settings.bump();
                          } else {
                            settings.tap();
                          }
                          setState(() => shown++);
                        },
                        child: Text(tr('Take out next')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                        onPressed: () => setState(() => shown = lot.items.length),
                        child: Text(tr('All at once')),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HiddenTile extends StatelessWidget {
  final int index;
  const _HiddenTile({required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Text(tr('Item {0}', [index + 1]), style: TextStyle(color: cs.onSurfaceVariant)),
    );
  }
}

class _RevealTile extends StatelessWidget {
  final Item item;
  const _RevealTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = item.contraband ? Colors.red : rarityColors[item.def.rarity.index];
    final big = item.def.rarity.index >= Rarity.rare.index;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: big ? 700 : 350),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0).toDouble(),
        child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.withAlpha(big ? 45 : 20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withAlpha(big ? 200 : 90), width: big ? 2 : 1),
        ),
        child: Row(
          children: [
            ItemAvatar(item: item),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.def.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(item.contraband ? tr('No paperwork. Customs will seize this.') : itemStatus(item),
                      style: TextStyle(fontSize: 12.5, color: item.contraband ? Colors.red : cs.onSurfaceVariant)),
                ],
              ),
            ),
            if (!item.contraband)
              Text('~${cash(item.estimate)}', style: TextStyle(fontWeight: FontWeight.w800, color: c)),
          ],
        ),
      ),
    );
  }
}
