import 'dart:async';

import 'package:flutter/material.dart';

import '../data.dart';
import '../game.dart';
import '../models.dart';
import 'auction_tab.dart';
import 'unpack_screen.dart';

class LotScreen extends StatefulWidget {
  final Lot lot;
  const LotScreen({super.key, required this.lot});

  @override
  State<LotScreen> createState() => _LotScreenState();
}

class _LotScreenState extends State<LotScreen> {
  static const double roundTime = 4.0;

  String phase = 'preview'; // preview, bidding, done
  late final List<BidderDef> who;
  Map<String, int> maxes = {};
  int price = 0;
  String? leader;
  double timeLeft = 0;
  Timer? timer;
  final List<String> feed = [];

  Lot get lot => widget.lot;

  @override
  void initState() {
    super.initState();
    who = game.attendees();
    price = lot.start;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String nameOf(String id) => id == 'me' ? 'Вы' : bidderById(id).name;
  int get next => leader == null ? price : price + game.bidStep(price);

  void start() {
    maxes = game.bidderMaxes(lot, who);
    setState(() {
      phase = 'bidding';
      timeLeft = 6;
      feed.insert(0, 'Торги открыты, стартовая цена ${rub(price)}');
    });
    timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _bid(String id) {
    final n = next;
    price = n;
    leader = id;
    timeLeft = roundTime;
    feed.insert(0, '${nameOf(id)}: ${rub(n)}');
  }

  void _tick() {
    if (!mounted || phase != 'bidding') return;
    setState(() {
      timeLeft -= 0.1;
      final order = List<BidderDef>.from(who)..shuffle(rng);
      final urgency = timeLeft < 1.5 ? 3.0 : 1.0;
      for (final b in order) {
        if (leader == b.id) continue;
        if (next > (maxes[b.id] ?? 0)) continue;
        if (rng.nextDouble() < 0.03 * b.eager * urgency) {
          _bid(b.id);
          break;
        }
      }
      if (timeLeft <= 0) _finish();
    });
  }

  void playerBid() {
    final n = next;
    if (n > game.money) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не хватает денег на эту ставку')));
      return;
    }
    setState(() => _bid('me'));
  }

  void pass() {
    setState(() {
      while (true) {
        final can = who.where((b) => b.id != leader && next <= (maxes[b.id] ?? 0)).toList();
        if (can.isEmpty) break;
        _bid(pick(can).id);
      }
      _finish();
    });
  }

  void _finish() {
    timer?.cancel();
    timer = null;
    phase = 'done';
    if (leader == 'me') {
      game.winLot(lot, price);
    } else {
      game.loseLot(lot, leader, price);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: phase != 'bidding',
      child: Scaffold(
        appBar: AppBar(title: Text(lot.kind.name)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _header(context),
            const SizedBox(height: 16),
            if (phase == 'preview') ..._preview(context),
            if (phase == 'bidding') ..._bidding(context),
            if (phase == 'done') ..._done(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(18)),
                  child: Icon(lot.kind.icon, size: 36, color: cs.onSecondaryContainer),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lot.kind.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      Text('Рейс из ${lot.origin} (${lot.code})', style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _kv(context, 'Вес', '${lot.weight.toStringAsFixed(1)} кг')),
                Expanded(child: _kv(context, 'Старт', rub(lot.start))),
                Expanded(child: _kv(context, 'Предметов', lot.xray ? '${lot.items.length}' : '?')),
              ],
            ),
            if (lot.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in lot.tags)
                    Chip(
                      label: Text(t),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: cs.tertiaryContainer,
                      side: BorderSide.none,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ],
    );
  }

  List<Widget> _preview(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final counts = <String, int>{};
    for (final i in lot.items) {
      counts[i.def.cat] = (counts[i.def.cat] ?? 0) + 1;
    }
    return [
      Text('Рентген', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      if (lot.xray)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in counts.entries)
              Chip(
                avatar: Icon(cats[e.key]!.icon, size: 18),
                label: Text('${cats[e.key]!.label} ×${e.value}'),
                side: BorderSide.none,
                backgroundColor: e.key == 'contraband' ? Colors.red.withAlpha(50) : cs.secondaryContainer,
              ),
          ],
        )
      else
        OutlinedButton.icon(
          onPressed: game.money >= game.xrayCost
              ? () {
                  game.xray(lot);
                  setState(() {});
                }
              : null,
          icon: const Icon(Icons.document_scanner),
          label: Text(game.xrayCost == 0 ? 'Просветить (бесплатно)' : 'Просветить за ${rub(game.xrayCost)}'),
        ),
      if (lot.xray)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('Рентген показывает, что внутри, но не говорит, подлинное ли это и работает ли.',
              style: Theme.of(context).textTheme.bodySmall),
        ),
      const SizedBox(height: 20),
      Text('На торгах', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      for (final b in who)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Text(b.name.substring(0, 1))),
          title: Text(b.name),
          subtitle: Text(b.desc),
        ),
      const SizedBox(height: 16),
      FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: start,
        icon: const Icon(Icons.gavel),
        label: const Text('Начать торги'),
      ),
    ];
  }

  List<Widget> _bidding(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mine = leader == 'me';
    final canAfford = next <= game.money;
    return [
      Card(
        elevation: 0,
        color: mine ? cs.primaryContainer : cs.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Text(leader == null ? 'Ставок пока нет' : 'Лидирует: ${nameOf(leader!)}',
                  style: TextStyle(fontWeight: FontWeight.w600, color: mine ? cs.onPrimaryContainer : cs.onSurface)),
              const SizedBox(height: 6),
              Text(rub(price),
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: mine ? cs.onPrimaryContainer : cs.onSurface)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (timeLeft / roundTime).clamp(0.0, 1.0).toDouble(),
                  minHeight: 10,
                  color: timeLeft < 1.5 ? cs.error : cs.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(timeLeft < 1.5 ? 'Раз… два…' : 'Таймер обнуляется после каждой ставки',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            flex: 3,
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              onPressed: mine || !canAfford ? null : playerBid,
              child: Text(mine ? 'Ваша ставка' : 'Ставка ${rub(next)}', style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              onPressed: mine ? null : pass,
              child: const Text('Пас'),
            ),
          ),
        ],
      ),
      if (!canAfford && !mine)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Денег не хватает: у вас ${rub(game.money)}', style: TextStyle(color: cs.error)),
        ),
      const SizedBox(height: 16),
      for (final f in feed.take(8))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(f, style: TextStyle(color: cs.onSurfaceVariant)),
        ),
    ];
  }

  List<Widget> _done(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (leader == 'me') {
      return [
        Card(
          elevation: 0,
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Icon(Icons.check_circle, size: 44, color: cs.onPrimaryContainer),
                const SizedBox(height: 8),
                Text('Лот ваш за ${rub(price)}',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cs.onPrimaryContainer)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () => Navigator.pushReplacement(
              context, MaterialPageRoute<void>(builder: (_) => UnpackScreen(lot: lot))),
          icon: const Icon(Icons.inventory_2),
          label: const Text('Распаковать'),
        ),
      ];
    }
    final text = leader == null ? 'Никто не сделал ставку. Лот снят с торгов.' : 'Лот забрал ${nameOf(leader!)} за ${rub(price)}.';
    return [
      Card(
        elevation: 0,
        color: cs.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(height: 12),
      if (leader != null)
        OutlinedButton.icon(
          onPressed: () => showLotReveal(context, lot),
          icon: const Icon(Icons.visibility),
          label: const Text('Посмотреть, что было внутри'),
        ),
      const SizedBox(height: 8),
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('К списку лотов')),
    ];
  }
}
