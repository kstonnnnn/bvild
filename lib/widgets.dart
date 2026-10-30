import 'dart:math';

import 'package:flutter/material.dart';

import 'data.dart';
import 'game.dart';
import 'models.dart';
import 'settings.dart';

class ItemAvatar extends StatelessWidget {
  final Item item;
  final double size;
  const ItemAvatar({super.key, required this.item, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final c = item.contraband ? Colors.red : rarityColors[item.def.rarity.index];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withAlpha(38),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: c.withAlpha(140), width: 1.5),
      ),
      child: Icon(item.def.iconData, color: c, size: size * 0.55),
    );
  }
}

String itemStatus(Item i) {
  final parts = <String>[rarityLabels[i.def.rarity.index]];
  if (i.broken) parts.add(i.repairTried ? 'на запчасти' : 'сломано');
  if (i.fakePossible && !i.appraised) parts.add('подлинность не проверена');
  if (i.appraised && i.fake) parts.add('подделка');
  if (i.appraised && !i.fake && i.fakePossible) parts.add('подлинник');
  return parts.join(' · ');
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.1,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    )),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  const StatTile(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: t.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class CapitalCard extends StatelessWidget {
  const CapitalCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final goal = game.nextMilestone;
    final progress = (game.capital / goal).clamp(0.0, 1.0).toDouble();
    return Card(
      elevation: 0,
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Капитал', style: TextStyle(color: cs.onPrimaryContainer.withAlpha(180), fontSize: 13)),
            Text(rub(game.capital),
                style: TextStyle(color: cs.onPrimaryContainer, fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: cs.onPrimaryContainer.withAlpha(30),
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 6),
            Text('Цель: ${rub(goal)}',
                style: TextStyle(color: cs.onPrimaryContainer.withAlpha(200), fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _mini(context, 'Наличные', rub(game.money))),
                Expanded(child: _mini(context, 'Склад', '${game.items.length} из ${game.capacity}')),
                Expanded(child: _mini(context, 'Репутация', '${game.reputation}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(BuildContext context, String l, String v) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l, style: TextStyle(color: cs.onPrimaryContainer.withAlpha(170), fontSize: 12)),
        Text(v, style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w700, fontSize: 15)),
      ],
    );
  }
}

Future<void> showTutorial(BuildContext context) {
  const steps = [
    'Каждый день склад аэропорта продаёт невостребованный багаж. Внутри может быть что угодно: от носков до швейцарских часов.',
    'Изучай подсказки: откуда рейс, сколько весит, какие бирки. За деньги лот можно просветить рентгеном.',
    'Торгуйся с перекупщиками. После каждой ставки таймер начинается заново. Кто последний — тот и забрал.',
    'Распакуй лот и разбери находки: проверь подлинность, почини сломанное, выстави на продажу или сдай скупщику.',
    'Покупатели приходят ночью, когда заканчиваешь день. Продашь непроверенную подделку как оригинал — её могут вернуть.',
    'Цель — капитал в миллион рублей. Аренда склада списывается каждый день.',
  ];
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Как играть'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(radius: 12, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(steps[i])),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Понятно')),
      ],
    ),
  );
}

class TipCard extends StatelessWidget {
  final String id;
  final String text;
  final IconData icon;
  const TipCard(this.id, this.text, {super.key, this.icon = Icons.lightbulb_outline});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        if (!settings.showTip(id)) return const SizedBox.shrink();
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: cs.onTertiaryContainer, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(text, style: TextStyle(color: cs.onTertiaryContainer, fontSize: 14, height: 1.35)),
                ),
                IconButton(
                  tooltip: 'Скрыть подсказку',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => settings.hideTip(id),
                  icon: Icon(Icons.close, size: 18, color: cs.onTertiaryContainer),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CapitalChart extends StatelessWidget {
  final List<int> values;
  const CapitalChart({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (values.length < 2) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text('График появится после пары игровых дней', style: TextStyle(color: cs.onSurfaceVariant)),
        ),
      );
    }
    final lo = values.reduce(min);
    final hi = values.reduce(max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 140,
          width: double.infinity,
          child: CustomPaint(painter: _ChartPainter(values, cs.primary, cs.outlineVariant)),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('мин ${rub(lo)}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const Spacer(),
            Text('макс ${rub(hi)}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<int> v;
  final Color line;
  final Color grid;
  _ChartPainter(this.v, this.line, this.grid);

  @override
  void paint(Canvas canvas, Size size) {
    final lo = v.reduce(min).toDouble();
    final hi = v.reduce(max).toDouble();
    final range = (hi - lo).abs() < 1 ? 1.0 : hi - lo;
    final gp = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gp);
    }
    final path = Path();
    final fill = Path();
    for (var i = 0; i < v.length; i++) {
      final x = size.width * i / (v.length - 1);
      final y = size.height - 6 - (v[i] - lo) / range * (size.height - 12);
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();
    canvas.drawPath(fill, Paint()..color = line.withAlpha(40));
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    final lastY = size.height - 6 - (v.last - lo) / range * (size.height - 12);
    canvas.drawCircle(Offset(size.width, lastY), 4, Paint()..color = line);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => old.v != v || old.line != line;
}
