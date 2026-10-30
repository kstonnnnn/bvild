import 'package:flutter/material.dart';

import '../data.dart';
import '../game.dart';
import '../models.dart';
import '../widgets.dart';
import 'lot_screen.dart';
import 'unpack_screen.dart';

class AuctionTab extends StatelessWidget {
  const AuctionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final open = game.lots.where((l) => l.status == 'open').length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const CapitalCard(),
            const SizedBox(height: 12),
            const TipCard('auction',
                'These are today\'s lots. Tap one to inspect it and start bidding. When you\'re done, tap End day at the bottom — buyers come at night.'),
            SectionTitle('Today\'s auction', trailing: Text('${game.lots.length} lots')),
            for (final l in game.lots) LotCard(lot: l),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: () => _endDay(context),
              icon: const Icon(Icons.nightlight_round),
              label: Text(open > 0 ? 'End day ($open lots skipped)' : 'End day'),
            ),
            const SizedBox(height: 8),
            Text(
              'Tonight you pay ${cash(game.rent)} in rent, and buyers check out your listed items.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }

  Future<void> _endDay(BuildContext context) async {
    final s = game.nextDay();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Day ${game.day}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Warehouse rent: −${cash(s.rent)}'),
              if (s.salesTotal > 0) Text('Overnight sales: +${cash(s.salesTotal)}'),
              const SizedBox(height: 8),
              if (s.lines.isEmpty) const Text('No buyers showed up overnight.'),
              for (final l in s.lines)
                Padding(padding: const EdgeInsets.only(top: 6), child: Text('• $l')),
            ],
          ),
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('To the auction'))],
      ),
    );
  }
}

class LotCard extends StatelessWidget {
  final Lot lot;
  const LotCard({super.key, required this.lot});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final k = lot.kind;
    String sub = 'Flight from ${lot.origin} (${lot.code}) · ${lot.weight.toStringAsFixed(1)} kg';
    Widget trailing;
    switch (lot.status) {
      case 'open':
        trailing = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('start', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            Text(cash(lot.start), style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        );
        break;
      case 'won':
        trailing = FilledButton.tonal(
          onPressed: () => _open(context),
          child: const Text('Unpack'),
        );
        break;
      case 'stored':
        trailing = Text('won\n${cash(lot.finalPrice ?? 0)}',
            textAlign: TextAlign.right, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600));
        break;
      case 'lost':
        trailing = Text('lost\n${cash(lot.finalPrice ?? 0)}',
            textAlign: TextAlign.right, style: TextStyle(color: cs.onSurfaceVariant));
        break;
      default:
        trailing = Text('no sale', style: TextStyle(color: cs.onSurfaceVariant));
    }
    final done = lot.status == 'lost' || lot.status == 'unsold';
    return Opacity(
      opacity: done ? 0.6 : 1,
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerHighest,
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(14)),
                  child: Icon(k.icon, color: cs.onSecondaryContainer, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(k.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(sub, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                      if (lot.tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [for (final t in lot.tags) _TagChip(t)],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    if (lot.status == 'open') {
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => LotScreen(lot: lot)));
    } else if (lot.status == 'won') {
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => UnpackScreen(lot: lot)));
    } else if (lot.status == 'lost' || lot.status == 'stored') {
      showLotReveal(context, lot);
    }
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip(this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: cs.tertiaryContainer, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11.5, color: cs.onTertiaryContainer, fontWeight: FontWeight.w600)),
    );
  }
}

Future<void> showLotReveal(BuildContext context, Lot lot) {
  final who = lot.winner == null
      ? 'Nobody'
      : lot.winner == 'me'
          ? 'You'
          : bidderById(lot.winner!).name;
  final real = lot.items.where((i) => !i.contraband).fold<int>(0, (s, i) => s + i.trueValue);
  final paid = lot.finalPrice ?? 0;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (ctx, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(lot.title, style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${who == 'You' ? 'You' : who} paid ${cash(paid)}. The contents were actually worth ${cash(real)}.'),
          const SizedBox(height: 4),
          Text(
            real >= paid ? 'That was a good deal.' : 'The buyer overpaid by ${cash(paid - real)}.',
            style: TextStyle(color: real >= paid ? Colors.green : Colors.red, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          for (final i in lot.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ItemAvatar(item: i, size: 40),
              title: Text(i.def.name),
              subtitle: Text(i.contraband
                  ? 'seized by customs'
                  : [
                      rarityLabels[i.def.rarity.index],
                      if (i.fake) 'fake',
                      if (i.broken) 'broken',
                    ].join(' · ')),
              trailing: Text(i.contraband ? '—' : cash(i.trueValue), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    ),
  );
}
