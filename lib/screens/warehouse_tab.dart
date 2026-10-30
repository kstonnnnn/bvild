import 'package:flutter/material.dart';

import '../data.dart';
import '../game.dart';
import '../models.dart';
import '../settings.dart';
import '../widgets.dart';

enum _Sort { value, rarity, name, newest }

enum _Filter { all, listed, unchecked, broken, junk }

const _sortNames = {_Sort.value: 'По цене', _Sort.rarity: 'По редкости', _Sort.name: 'По названию', _Sort.newest: 'Сначала новые'};
const _filterNames = {
  _Filter.all: 'Все',
  _Filter.listed: 'На продаже',
  _Filter.unchecked: 'Не проверены',
  _Filter.broken: 'Сломаны',
  _Filter.junk: 'Хлам',
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
        _snack('Хлама на складе нет');
        return;
      }
      final sum = junk.fold<int>(0, (s, i) => s + game.quickPrice(i));
      final ok = await _confirm('Сдать весь хлам?', '${junk.length} шт. уйдут скупщику за ${rub(sum)}.');
      if (ok) {
        final r = game.sellAllJunk();
        _snack('Сдано ${r[0]} шт. за ${rub(r[1])}');
      }
    } else if (action == 'listall') {
      final n = game.items.where((i) => !i.listed && i.def.rarity != Rarity.junk).length;
      if (n == 0) {
        _snack('Всё уже выставлено');
        return;
      }
      final ok = await _confirm('Выставить всё?',
          '$n вещей будут выставлены по цене на 20% выше оценки. Непроверенные подделки могут вернуть.');
      if (ok) {
        final k = game.listAll(1.2);
        _snack('Выставлено: $k');
      }
    } else if (action == 'unlistall') {
      for (final i in game.items.where((i) => i.listed).toList()) {
        game.unlist(i);
      }
      _snack('Все вещи сняты с продажи');
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Да')),
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
                        Expanded(child: StatTile('Занято мест', '${game.items.length} из ${game.capacity}')),
                        Expanded(child: StatTile('Оценка склада', rub(game.inventoryValue))),
                        PopupMenuButton<String>(
                          tooltip: 'Массовые действия',
                          icon: const Icon(Icons.more_vert),
                          onSelected: _bulk,
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'junk', child: Text('Сдать весь хлам скупщику')),
                            PopupMenuItem(value: 'listall', child: Text('Выставить всё на продажу')),
                            PopupMenuItem(value: 'unlistall', child: Text('Снять всё с продажи')),
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
                        child: Text('Склад полон. Новые находки сразу уйдут скупщику за полцены.',
                            style: TextStyle(color: cs.error, fontSize: 13)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const TipCard('warehouse',
                'Нажми на вещь, чтобы проверить подлинность, починить, выставить на продажу или сдать скупщику. Меню с тремя точками выше — массовые действия.'),
            if (game.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 56, color: cs.onSurfaceVariant),
                    const SizedBox(height: 12),
                    const Text('Склад пуст', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Купи лот на аукционе и распакуй его.', style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              )
            else ...[
              TextField(
                decoration: InputDecoration(
                  hintText: 'Поиск по складу',
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
                'Находки · ${list.length}',
                trailing: PopupMenuButton<_Sort>(
                  tooltip: 'Сортировка',
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
                  child: Text('Ничего не найдено', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
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
        subtitle: Text(item.listed ? 'На продаже за ${rub(item.listPrice!)}' : itemStatus(item)),
        trailing: Text('~${rub(item.estimate)}', style: const TextStyle(fontWeight: FontWeight.w700)),
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
            child: Text('Этой вещи больше нет на складе.'),
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
                    Text('Оценка: ~${rub(item.estimate)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(itemStatus(item), style: TextStyle(color: cs.onSurfaceVariant)),
                    if (item.fakePossible && !item.appraised)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('Такие вещи часто подделывают. Без экспертизы цена может оказаться в разы ниже.',
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
                  label: Text('Экспертиза подлинности — ${rub(appraise)}'),
                ),
              ),
            if (item.broken && !item.repairTried)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton.tonalIcon(
                  onPressed: game.money >= repair ? () => game.repair(item) : null,
                  icon: const Icon(Icons.build),
                  label: Text('Отремонтировать — ${rub(repair)}'),
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
                  label: const Text('Выставить на продажу'),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton.icon(
                  onPressed: () => game.unlist(item),
                  icon: const Icon(Icons.remove_shopping_cart),
                  label: Text('Снять с продажи (${rub(item.listPrice!)})'),
                ),
              ),
            OutlinedButton.icon(
              onPressed: () async {
                if (settings.confirmQuickSell && item.estimate >= 1000) {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Сдать скупщику?'),
                      content: Text('«${item.def.name}» уйдёт за ${rub(quick)}. Оценка вещи — ~${rub(item.estimate)}.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сдать')),
                      ],
                    ),
                  );
                  if (ok != true) return;
                }
                if (context.mounted) Navigator.pop(context);
                game.quickSell(item);
              },
              icon: const Icon(Icons.payments),
              label: Text('Сдать скупщику за ${rub(quick)}'),
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
          hint = 'Уйдёт очень быстро';
        } else if (k < 1.3) {
          hint = 'Нормальная цена, продастся за пару ночей';
        } else if (k < 1.8) {
          hint = 'Дороговато, придётся подождать';
        } else {
          hint = 'Очень дорого, покупатель может и не найтись';
        }
        return AlertDialog(
          title: Text(item.def.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(rub(price), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
              Text('${(k * 100).round()}% от оценки', style: Theme.of(ctx).textTheme.bodySmall),
              Wrap(
                spacing: 6,
                children: [
                  for (final q in const [0.9, 1.2, 1.5, 2.0])
                    ChoiceChip(
                      label: Text('×${q.toString().replaceAll('.', ',')}'),
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
                  child: Text('Подлинность не проверена. Если это подделка, покупатель может её вернуть.',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Theme.of(ctx).colorScheme.error)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            FilledButton(onPressed: () => Navigator.pop(ctx, price), child: const Text('Выставить')),
          ],
        );
      },
    ),
  );
}
