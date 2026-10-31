import 'dart:async';

import 'package:flutter/material.dart';

import '../data.dart';
import '../game.dart';
import '../i18n.dart';
import '../models.dart';
import '../settings.dart';
import '../widgets.dart';
import 'auction_tab.dart';
import 'unpack_screen.dart';

class LotScreen extends StatefulWidget {
  final Lot lot;
  const LotScreen({super.key, required this.lot});

  @override
  State<LotScreen> createState() => _LotScreenState();
}

class _LotScreenState extends State<LotScreen> {
  double get roundTime => settings.roundTime;
  int? autoMax;

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
    who = game.attendees(lot);
    price = lot.start;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String nameOf(String id) => id == 'me' ? tr('You') : bidderById(id).name;
  int get next => leader == null ? price : price + game.bidStep(price);

  void start() {
    maxes = game.bidderMaxes(lot, who);
    setState(() {
      phase = 'bidding';
      timeLeft = roundTime + 2;
      feed.insert(0, tr('Bidding is open, starting at {0}', [cash(price)]));
    });
    timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _bid(String id) {
    final n = next;
    price = n;
    leader = id;
    timeLeft = roundTime;
    feed.insert(0, '${nameOf(id)}: ${cash(n)}');
  }

  void _tick() {
    if (!mounted || phase != 'bidding') return;
    setState(() {
      timeLeft -= 0.1;
      final am = autoMax;
      if (am != null && leader != 'me' && next <= am && next <= game.money && rng.nextDouble() < 0.18) {
        _bid('me');
        settings.tap();
      }
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Not enough cash for this bid'))));
      return;
    }
    settings.tap();
    setState(() => _bid('me'));
  }

  Future<void> setAutoBid() async {
    final lo = next;
    final hi = game.money;
    if (hi < lo) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Not enough cash even for the next bid'))));
      return;
    }
    double v = (autoMax ?? (lo + (hi - lo) * 0.3)).clamp(lo, hi).toDouble();
    final res = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(tr('Auto-bid')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr('The game will outbid rivals for you until the price reaches this amount.')),
              const SizedBox(height: 16),
              Text(cash(game.roundVal(v.round())), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              if (hi > lo)
                Slider(
                  value: v,
                  min: lo.toDouble(),
                  max: hi.toDouble(),
                  onChanged: (x) => setS(() => v = x),
                ),
            ],
          ),
          actions: [
            if (autoMax != null) TextButton(onPressed: () => Navigator.pop(ctx, -1), child: Text(tr('Turn off'))),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, game.roundVal(v.round())), child: Text(tr('Turn on'))),
          ],
        ),
      ),
    );
    if (res == null || !mounted) return;
    setState(() => autoMax = res < 0 ? null : res);
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
      settings.bump();
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
                      Text(tr('Flight from {0} ({1})', [tr(lot.origin), lot.code]), style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _kv(context, tr('Weight'), tr('{0} kg', [lot.weight.toStringAsFixed(1)]))),
                Expanded(child: _kv(context, tr('Start'), cash(lot.start))),
                Expanded(child: _kv(context, tr('Items'), lot.xray ? '${lot.items.length}' : '?')),
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
                      label: Text(tr(t)),
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
      if (lot.training)
        const TipCard('lot_training',
            'This is a training lot. Only Gus is bidding against you, and he won\'t push the price much. Tap Start bidding and place a couple of bids.',
            icon: Icons.school)
      else
        const TipCard('lot_preview',
            'Check the tags and departure city before bidding. An X-ray shows what kinds of things are inside, but not whether they\'re real. Your rivals are listed below, each with their own style.'),
      Text(tr('X-ray'), style: Theme.of(context).textTheme.titleMedium),
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
          label: Text(game.xrayCost == 0 ? tr('X-ray (free)') : tr('X-ray for {0}', [cash(game.xrayCost)])),
        ),
      if (lot.xray)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(tr('The X-ray shows what\'s inside, but not whether it\'s authentic or working.'),
              style: Theme.of(context).textTheme.bodySmall),
        ),
      const SizedBox(height: 20),
      Text(tr('Bidding today'), style: Theme.of(context).textTheme.titleMedium),
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
        label: Text(tr('Start bidding')),
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
              Text(leader == null ? tr('No bids yet') : tr('Leading: {0}', [nameOf(leader!)]),
                  style: TextStyle(fontWeight: FontWeight.w600, color: mine ? cs.onPrimaryContainer : cs.onSurface)),
              const SizedBox(height: 6),
              Text(cash(price),
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
              Text(timeLeft < 1.5 ? tr('Going once… going twice…') : tr('Every bid resets the timer'),
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
              child: Text(mine ? tr('Your bid') : tr('Bid {0}', [cash(next)]), style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              onPressed: mine ? null : pass,
              child: Text(tr('Pass')),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: setAutoBid,
        icon: Icon(autoMax == null ? Icons.smart_toy_outlined : Icons.smart_toy),
        label: Text(autoMax == null ? tr('Auto-bid') : tr('Auto-bid up to {0}', [cash(autoMax!)])),
      ),
      if (!canAfford && !mine)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(tr('Not enough cash: you have {0}', [cash(game.money)]), style: TextStyle(color: cs.error)),
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
                Text(tr('You won it for {0}', [cash(price)]),
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
          label: Text(tr('Unpack')),
        ),
      ];
    }
    final text = leader == null ? tr('Nobody bid. The lot was withdrawn.') : tr('{0} won the lot for {1}.', [nameOf(leader!), cash(price)]);
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
          label: Text(tr('See what was inside')),
        ),
      const SizedBox(height: 8),
      TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Back to lots'))),
    ];
  }
}
