import 'package:flutter/material.dart';

import '../game.dart';
import '../i18n.dart';
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
                  tr('Buyers come at night when you end the day. The lower the price compared to the estimate, and the higher your reputation, the faster things sell.'),
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const TipCard('market',
                'Tip: pricing 10–30% above the estimate usually sells within a couple of nights. If a buyer offers less, decide before the day ends or the offer expires.'),
            if (game.offers.isNotEmpty) ...[
              const SectionTitle('Buyer offers'),
              for (final o in game.offers) _OfferCard(offer: o),
            ],
            SectionTitle('For sale', trailing: Text('${listed.length}')),
            if (listed.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(tr('Nothing listed. Pick an item in Storage and tap List for sale.'),
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
                    subtitle: Text(tr('Listed {0} · est. ~{1}', [_ago(game.day - i.listedDay), cash(i.estimate)])),
                    trailing: Text(cash(i.listPrice!), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
            const SectionTitle('Recent income'),
            if (sales.isEmpty)
              Text(tr('Nothing yet.'), style: TextStyle(color: cs.onSurfaceVariant))
            else
              for (final e in sales)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(width: 52, child: Text(tr('day {0}', [e.day]), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))),
                      Expanded(child: Text(e.text)),
                      Text('+${cash(e.amount!)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
          ],
        );
      },
    );
  }

  String _ago(int d) {
    if (d <= 0) return tr('today');
    if (d == 1) return tr('yesterday');
    return tr('{0} days ago', [d]);
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
                      Text(tr(offer.buyer), style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(tr('wants your {0} for {1}', [inlineName(item.def.name), cash(offer.price)])),
                      Text(tr('Your price: {0}. The offer expires at the end of the day.', [cash(item.listPrice ?? item.estimate)]),
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
                  child: FilledButton(onPressed: () => game.acceptOffer(offer), child: Text(tr('Sell'))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(onPressed: () => game.declineOffer(offer), child: Text(tr('Decline'))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
