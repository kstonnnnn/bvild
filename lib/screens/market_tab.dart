import 'package:flutter/material.dart';

import '../game.dart';
import '../models.dart';
import '../widgets.dart';
import 'warehouse_tab.dart';

class MarketTab extends StatelessWidget {
  const MarketTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final listed = game.items.where((i) => i.listed).toList();
        final sales = game.journal.where((e) => (e.amount ?? 0) > 0).take(20).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Card(
              elevation: 0,
              color: cs.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Покупатели приходят ночью, когда заканчиваешь день. Чем ниже цена относительно оценки и выше репутация, тем быстрее продаётся.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            ),
            if (game.offers.isNotEmpty) ...[
              const SectionTitle('Предложения покупателей'),
              for (final o in game.offers) _OfferCard(offer: o),
            ],
            SectionTitle('На продаже', trailing: Text('${listed.length}')),
            if (listed.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Ничего не выставлено. Выбери вещь на складе и нажми «Выставить на продажу».',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              )
            else
              for (final i in listed)
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  color: cs.surfaceContainerLow,
                  child: ListTile(
                    onTap: () => showItemSheet(context, i),
                    leading: ItemAvatar(item: i),
                    title: Text(i.def.name),
                    subtitle: Text('Выставлено ${_ago(game.day - i.listedDay)} · оценка ~${rub(i.estimate)}'),
                    trailing: Text(rub(i.listPrice!), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
            const SectionTitle('Последние поступления'),
            if (sales.isEmpty)
              Text('Пока пусто.', style: TextStyle(color: cs.onSurfaceVariant))
            else
              for (final e in sales)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(width: 52, child: Text('день ${e.day}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))),
                      Expanded(child: Text(e.text)),
                      Text('+${rub(e.amount!)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
          ],
        );
      },
    );
  }

  String _ago(int d) {
    if (d <= 0) return 'сегодня';
    if (d == 1) return 'вчера';
    return '$d дн. назад';
  }
}

class _OfferCard extends StatelessWidget {
  final Offer offer;
  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final item = game.itemByUid(offer.uid);
    if (item == null) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: cs.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ItemAvatar(item: item, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offer.buyer, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('хочет «${item.def.name}» за ${rub(offer.price)}'),
                      Text('Ваша цена ${rub(item.listPrice ?? item.estimate)}. Предложение действует до конца дня.',
                          style: TextStyle(fontSize: 12, color: cs.onSecondaryContainer.withAlpha(180))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(onPressed: () => game.acceptOffer(offer), child: const Text('Продать')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(onPressed: () => game.declineOffer(offer), child: const Text('Отказать')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
