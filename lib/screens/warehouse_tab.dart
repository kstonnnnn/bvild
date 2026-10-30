import 'package:flutter/material.dart';

import '../data.dart';
import '../game.dart';
import '../models.dart';
import '../settings.dart';
import '../widgets.dart';

enum _Sort { value, rarity, name, newest }

enum _Filter { all, listed, unchecked, broken, junk }

const _sortNames = {_Sort.value: 'By value', _Sort.rarity: 'By rarity', _Sort.name: 'By name', _Sort.newest: 'Newest first'};
const _filterNames = {
  _Filter.all: 'All',
  _Filter.listed: 'For sale',
  _Filter.unchecked: 'Unchecked',
  _Filter.broken: 'Broken',
  _Filter.junk: 'Junk',
};

class WarehouseTab extends StatefulWidget {
  const WarehouseTab({super.key});

  @override
  State<WarehouseTab> createState() => _WarehouseTabState();
}

class _WarehouseTabState extends State<WarehouseTab> {
  _Sort sort = _Sort.value;
  _Filter filter = _Filter.all;
  String query = '';

  bool _match(Item i) {
    if (query.isNotEmpty && !i.def.name.toLowerCase().contains(query.toLowerCase())) return false;
    return switch (filter) {
      _Filter.all => true,
      _Filter.listed => i.listed,
      _Filter.unchecked => i.fakePossible && !i.appraised,
      _Filter.broken => i.broken,
      _Filter.junk => i.def.rarity == Rarity.junk,
    };
  }

  List<Item> _sorted() {
    final idx = <String, int>{};
    for (var k = 0; k < game.items.length; k++) {
      idx[game.items[k].uid] = k;
    }
    final list = game.items.where(_match).toList();
    switch (sort) {
      case _Sort.value:
        list.sort((a, b) => b.estimate.compareTo(a.estimate));
        break;
      case _Sort.rarity:
        list.sort((a, b) {
          final r = b.def.rarity.index.compareTo(a.def.rarity.index);
          return r != 0 ? r : b.estimate.compareTo(a.estimate);
        });
        break;
      case _Sort.name:
        list.sort((a, b) => a.def.name.compareTo(b.def.name));
        break;
      case _Sort.newest:
        list.sort((a, b) => (idx[b.uid] ?? 0).compareTo(idx[a.uid] ?? 0));
        break;
    }
    return list;
  }

  Future<void> _bulk(String action) async {
    if (action == 'junk') {
      final junk = game.items.where((i) => i.def.rarity == Rarity.junk && !i.listed).toList();
      if (junk.isEmpty) {
        _snack('No junk in storage');
        return;
      }
      final sum = junk.fold<int>(0, (s, i) => s + game.quickPrice(i));
      final ok = await _confirm('Pawn all junk?', '${junk.length} items will go to the pawnbroker for ${cash(sum)}.');
      if (ok) {
        final r = game.sellAllJunk();
        _snack('Pawned ${r[0]} items for ${cash(r[1])}');
      }
    } else if (action == 'listall') {
      final n = game.items.where((i) => !i.listed && i.def.rarity != Rarity.junk).length;
      if (n == 0) {
        _snack('Everything is already listed');
        return;
      }
      final ok = await _confirm('List everything?',
          '$n items will be listed at 20% above their estimate. Unchecked fakes may be returned.');
      if (ok) {
        final k = game.listAll(1.2);
        _snack('Listed: $k');
      }
    } else if (action == 'unlistall') {
      for (final i in game.items.where((i) => i.listed).toList()) {
        game.unlist(i);
      }
      _snack('Everything taken off sale');
    }
  }

  void _snack(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<bool> _confirm(String title, String text) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );
    return r == true;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final list = _sorted();
        final fill = (game.items.length / game.capacity).clamp(0.0, 1.0).toDouble();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Card(
              elevation: 0,
              color: cs.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: StatTile('Slots used', '${game.items.length} / ${game.capacity}')),
                        Expanded(child: StatTile('Storage value', cash(game.inventoryValue))),
                        PopupMenuButton<String>(
                          tooltip: 'Bulk actions',
                          icon: const Icon(Icons.more_vert),
                          onSelected: _bulk,
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'junk', child: Text('Pawn all junk')),
                            PopupMenuItem(value: 'listall', child: Text('List everything for sale')),
                            PopupMenuItem(value: 'unlistall', child: Text('Take everything off sale')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: fill,
                        minHeight: 8,
                        color: fill >= 1 ? cs.error : cs.primary,
                      ),
                    ),
                    if (fill >= 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('Storage is full. New finds will go straight to the pawnbroker at half price.',
                            style: TextStyle(color: cs.error, fontSize: 13)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const TipCard('warehouse',
                'Tap an item to authenticate, repair, list or pawn it. The three-dot menu above has bulk actions.'),
            if (game.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 56, color: cs.onSurfaceVariant),
                    const SizedBox(height: 12),
                    const Text('Storage is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Win a lot at the auction and unpack it.', style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              )
            else ...[
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search storage',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                onChanged: (v) => setState(() => query = v.trim()),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in _Filter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(_filterNames[f]!),
                          selected: filter == f,
                          onSelected: (_) => setState(() => filter = f),
                        ),
                      ),
                  ],
                ),
              ),
              SectionTitle(
                'Finds · ${list.length}',
                trailing: PopupMenuButton<_Sort>(
                  tooltip: 'Sort',
                  initialValue: sort,
                  onSelected: (v) => setState(() => sort = v),
                  itemBuilder: (_) => [
                    for (final v in _Sort.values) PopupMenuItem(value: v, child: Text(_sortNames[v]!)),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_sortNames[sort]!, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
                      Icon(Icons.arrow_drop_down, color: cs.primary),
                    ],
                  ),
                ),
              ),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('Nothing found', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
                ),
              for (final i in list) ItemRow(item: i),
            ],
          ],
        );
      },
    );
  }
}

class ItemRow extends StatelessWidget {
  final Item item;
  const ItemRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: cs.surfaceContainerLow,
      child: ListTile(
        onTap: () => showItemSheet(context, item),
        leading: ItemAvatar(item: item),
        title: Text(item.def.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(item.listed ? 'For sale at ${cash(item.listPrice!)}' : itemStatus(item)),
        trailing: Text('~${cash(item.estimate)}', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

Future<void> showItemSheet(BuildContext context, Item item) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => ListenableBuilder(
      listenable: game,
      builder: (ctx, _) {
        if (game.itemByUid(item.uid) == null) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Text('This item is no longer in storage.'),
          );
        }
        return _ItemSheetBody(item: item);
      },
    ),
  );
}

class _ItemSheetBody extends StatelessWidget {
  final Item item;
  const _ItemSheetBody({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = item.def;
    final appraise = game.appraiseCost(item);
    final repair = game.repairCost(item);
    final quick = game.quickPrice(item);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ItemAvatar(item: item, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      Text('${cats[d.cat]!.label} · ${rarityLabels[d.rarity.index]}',
                          style: TextStyle(color: rarityColors[d.rarity.index], fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: cs.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimate: ~${cash(item.estimate)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(itemStatus(item), style: TextStyle(color: cs.onSurfaceVariant)),
                    if (item.fakePossible && !item.appraised)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('Items like this are often faked. Without an appraisal, the real value could be a fraction of this.',
                            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                      ),
                    if (d.note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(d.note, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (item.fakePossible && !item.appraised)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton.tonalIcon(
                  onPressed: game.money >= appraise ? () => game.appraise(item) : null,
                  icon: const Icon(Icons.verified),
                  label: Text('Authenticate — ${cash(appraise)}'),
                ),
              ),
            if (item.broken && !item.repairTried)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton.tonalIcon(
                  onPressed: game.money >= repair ? () => game.repair(item) : null,
                  icon: const Icon(Icons.build),
                  label: Text('Repair — ${cash(repair)}'),
                ),
              ),
            if (!item.listed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton.icon(
                  onPressed: () async {
                    final p = await askPrice(context, item);
                    if (p != null) game.listItem(item, p);
                  },
                  icon: const Icon(Icons.sell),
                  label: const Text('List for sale'),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton.icon(
                  onPressed: () => game.unlist(item),
                  icon: const Icon(Icons.remove_shopping_cart),
                  label: Text('Take off sale (${cash(item.listPrice!)})'),
                ),
              ),
            OutlinedButton.icon(
              onPressed: () async {
                if (settings.confirmQuickSell && item.estimate >= 1000) {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Pawn it?'),
                      content: Text('${item.def.name} will go for ${cash(quick)}. Its estimate is ~${cash(item.estimate)}.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Pawn')),
                      ],
                    ),
                  );
                  if (ok != true) return;
                }
                if (context.mounted) Navigator.pop(context);
                game.quickSell(item);
              },
              icon: const Icon(Icons.payments),
              label: Text('Pawn for ${cash(quick)}'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<int?> askPrice(BuildContext context, Item item) {
  final base = item.estimate < 10 ? 10 : item.estimate;
  double k = 1.2;
  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        final price = game.roundVal((base * k).round());
        String hint;
        if (k < 0.9) {
          hint = 'Will sell very fast';
        } else if (k < 1.3) {
          hint = 'Fair price, should sell in a couple of nights';
        } else if (k < 1.8) {
          hint = 'A bit pricey, expect to wait';
        } else {
          hint = 'Very pricey, a buyer may never show up';
        }
        return AlertDialog(
          title: Text(item.def.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(cash(price), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
              Text('${(k * 100).round()}% of estimate', style: Theme.of(ctx).textTheme.bodySmall),
              Wrap(
                spacing: 6,
                children: [
                  for (final q in const [0.9, 1.2, 1.5, 2.0])
                    ChoiceChip(
                      label: Text('×$q'),
                      selected: (k - q).abs() < 0.01,
                      onSelected: (_) => setS(() => k = q),
                    ),
                ],
              ),
              Slider(
                value: k,
                min: 0.5,
                max: 2.5,
                divisions: 40,
                onChanged: (v) => setS(() => k = v),
              ),
              Text(hint, textAlign: TextAlign.center),
              if (item.fakePossible && !item.appraised)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('Not authenticated. If it turns out to be fake, the buyer may return it.',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Theme.of(ctx).colorScheme.error)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, price), child: const Text('List')),
          ],
        );
      },
    ),
  );
}
