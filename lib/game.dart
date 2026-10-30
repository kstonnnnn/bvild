import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';
import 'models.dart';
import 'settings.dart';

final Random rng = Random();
final GameState game = GameState();

int rint(int a, int b) => a + rng.nextInt(b - a + 1);
double rd(double a, double b) => a + rng.nextDouble() * (b - a);
T pick<T>(List<T> l) => l[rng.nextInt(l.length)];
int round100(num v) => (v / 100).round() * 100;

String rub(num v) {
  final n = v.round();
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '${n < 0 ? '−' : ''}$b ₽';
}

class EventChoice {
  final String label;
  final void Function() act;
  EventChoice(this.label, this.act);
}

class GameEvent {
  final String title;
  final String text;
  final List<EventChoice> choices;
  GameEvent(this.title, this.text, this.choices);
}

class DaySummary {
  int rent = 0;
  int salesTotal = 0;
  final List<String> lines = [];
}

class GameState extends ChangeNotifier {
  static const _key = 'lost_luggage_save_v1';
  static const List<int> milestones = [100000, 500000, 1000000];
  static const List<String> milestoneTitles = ['Перекупщик', 'Скупщик года', 'Король багажа'];

  int day = 1;
  int money = 30000;
  int reputation = 50;
  List<Lot> lots = [];
  List<Item> items = [];
  List<Offer> offers = [];
  List<Complaint> complaints = [];
  List<JournalEntry> journal = [];
  Set<String> found = {};
  Set<String> upgrades = {};
  Set<int> milestonesShown = {};
  int totalEarned = 0;
  int totalSpent = 0;
  int lotsWon = 0;
  int bestFind = 0;
  String bestFindName = '';
  bool tutorialSeen = false;
  List<int> capitalHistory = [];

  // Per-day modifiers, not saved.
  double quickRate = 0.5;
  double buyerBoost = 1.0;
  Set<String> absent = {};
  GameEvent? event;
  final List<String> toasts = [];
  int? milestoneToShow;
  int _uid = 0;

  String nextUid() => '${DateTime.now().microsecondsSinceEpoch}-${_uid++}';

  bool has(String u) => upgrades.contains(u);
  int get capacity => 20 + (has('storage1') ? 15 : 0) + (has('storage2') ? 25 : 0);
  int get rent => ((300 + capacity * 15) * settings.rentMult).round();
  int get inventoryValue => items.fold<int>(0, (s, i) => s + i.estimate);
  int get capital => money + inventoryValue;
  int get xrayCost => has('xray') ? 0 : 1500;
  int get nextMilestone {
    for (final m in milestones) {
      if (capital < m) return m;
    }
    return milestones.last;
  }

  Item? itemByUid(String uid) {
    for (final x in items) {
      if (x.uid == uid) return x;
    }
    return null;
  }

  void toast(String t) => toasts.add(t);

  void log(String t, {int? amount}) {
    journal.insert(0, JournalEntry(day, t, amount));
    if (journal.length > 150) journal.removeLast();
  }

  void changed() {
    for (var k = 0; k < milestones.length; k++) {
      final m = milestones[k];
      if (capital >= m && !milestonesShown.contains(m)) {
        milestonesShown.add(m);
        milestoneToShow = k;
      }
    }
    notifyListeners();
    save();
  }

  // ---------------------------------------------------------------- generation

  int _weighted(List<double> w) {
    final total = w.fold<double>(0, (a, b) => a + b);
    var r = rng.nextDouble() * total;
    for (var i = 0; i < w.length; i++) {
      r -= w[i];
      if (r <= 0) return i;
    }
    return w.length - 1;
  }

  int roundVal(int v) => v < 1000 ? (v / 10).round() * 10 : (v / 100).round() * 100;

  void startDay() {
    quickRate = 0.5;
    buyerBoost = 1.0;
    absent = {};
    lots = List.generate(day == 1 ? 4 : 5, (_) => _genLot());
    if (has('van') && rng.nextDouble() < 0.5) lots.add(_genLot(forceKind: 'container'));
    event = _rollEvent();
  }

  Lot _genLot({String? forceKind}) {
    LotKind kind;
    if (forceKind != null) {
      kind = kindById(forceKind);
    } else {
      final avail = lotKinds.where((k) => !k.van && k.minDay <= day).toList();
      final w = avail.map((k) => k.id == 'case' ? 0.45 : (k.id == 'suitcase' ? 1.4 : 1.0)).toList();
      kind = avail[_weighted(w)];
    }
    final origin = pick(origins);
    final pool = List<LotTag>.from(lotTags)..shuffle(rng);
    final r = rng.nextDouble();
    final tagN = r < 0.35 ? 0 : (r < 0.8 ? 1 : 2);
    final tags = pool.take(tagN).toList();
    final n = rint(kind.minN, kind.maxN);
    final list = List.generate(n, (_) => _genItem(kind, origin, tags));
    final nominal = list.fold<int>(0, (s, i) => s + i.value);
    final weight = (rd(kind.wMin, kind.wMax) * 10).round() / 10;
    final start = max(300, round100(nominal * rd(0.06, 0.12)));
    return Lot(
      id: nextUid(),
      kindId: kind.id,
      origin: origin.city,
      code: origin.code,
      weight: weight,
      tags: tags.map((t) => t.label).toList(),
      items: list,
      start: start,
    );
  }

  Item _genItem(LotKind kind, Origin origin, List<LotTag> tags) {
    if (rng.nextDouble() < 0.025) {
      final d = pick(itemDefs.where((d) => d.cat == 'contraband').toList());
      return Item(uid: nextUid(), defId: d.id, value: 0);
    }
    var rareMul = kind.rare;
    for (final t in tags) {
      rareMul *= t.rare;
    }
    final double junkW = 0.34 / rareMul.clamp(0.5, 3.0);
    final List<double> rw = [junkW, 0.42, 0.19 * rareMul, 0.045 * rareMul, 0.005 * rareMul];
    final rarity = Rarity.values[_weighted(rw)];
    final cands = itemDefs.where((d) => d.rarity == rarity && d.cat != 'contraband').toList();
    final cw = cands.map((d) {
      var w = origin.w[d.cat] ?? 1.0;
      for (final t in tags) {
        w *= t.w[d.cat] ?? 1.0;
      }
      return w;
    }).toList();
    final def = cands[_weighted(cw)];
    return Item(
      uid: nextUid(),
      defId: def.id,
      value: roundVal(rint(def.minV, def.maxV)),
      fake: rng.nextDouble() < def.fake,
      broken: rng.nextDouble() < def.broken,
    );
  }

  // ---------------------------------------------------------------- auction

  List<BidderDef> attendees(Lot lot) {
    if (lot.training) return [bidderById('gena')];
    final pool = bidders.where((b) => !absent.contains(b.id)).toList()..shuffle(rng);
    final n = min(pool.length, rint(2, 3));
    return pool.take(n).toList();
  }

  Map<String, int> bidderMaxes(Lot lot, List<BidderDef> who) {
    final nominal = lot.nominal;
    final res = <String, int>{};
    if (lot.training) {
      for (final b in who) {
        res[b.id] = lot.start + 400;
      }
      return res;
    }
    for (final b in who) {
      var v = nominal * rd(0.5, 1.1) * b.mult * settings.botMult;
      if (b.specials.isNotEmpty) {
        final sv = lot.items.where((i) => b.specials.contains(i.def.cat)).fold<int>(0, (s, i) => s + i.value);
        if (sv > nominal * 0.3) v *= 1.25;
      }
      res[b.id] = max(lot.start, v.round());
    }
    return res;
  }

  int bidStep(int price) {
    if (price < 2000) return 100;
    if (price < 10000) return 500;
    if (price < 50000) return 2000;
    if (price < 200000) return 5000;
    return 20000;
  }

  void xray(Lot lot) {
    final c = xrayCost;
    money -= c;
    totalSpent += c;
    lot.xray = true;
    changed();
  }

  void winLot(Lot lot, int price) {
    lot.status = 'won';
    lot.finalPrice = price;
    lot.winner = 'me';
    money -= price;
    totalSpent += price;
    lotsWon++;
    log('Куплен лот «${lot.title}»', amount: -price);
    changed();
  }

  void loseLot(Lot lot, String? winner, int price) {
    lot.status = winner == null ? 'unsold' : 'lost';
    lot.winner = winner;
    lot.finalPrice = price;
    changed();
  }

  void storeLot(Lot lot) {
    if (lot.status != 'won') return;
    for (final it in lot.items) {
      if (it.contraband) {
        toast('Таможня изъяла: ${it.def.name}');
        log('Таможня изъяла: ${it.def.name}');
        continue;
      }
      if (it.def.rarity.index >= Rarity.rare.index) found.add(it.defId);
      if (it.estimate > bestFind) {
        bestFind = it.estimate;
        bestFindName = it.def.name;
      }
      if (items.length >= capacity) {
        final p = max(5, (it.trueValue * quickRate).round());
        money += p;
        totalEarned += p;
        toast('Склад полон: «${it.def.name}» ушёл скупщику за ${rub(p)}');
        log('Склад полон, скупщику: ${it.def.name}', amount: p);
        continue;
      }
      items.add(it);
    }
    lot.status = 'stored';
    changed();
  }

  // ---------------------------------------------------------------- items

  int appraiseCost(Item i) {
    final c = max(500, (i.value * 0.04).round());
    return has('appraiser') ? (c / 2).round() : c;
  }

  void appraise(Item i) {
    final c = appraiseCost(i);
    money -= c;
    totalSpent += c;
    i.appraised = true;
    if (i.fake) {
      toast('Подделка. Реальная цена ${rub(i.trueValue)}');
      log('Экспертиза: «${i.def.name}» — подделка', amount: -c);
    } else {
      toast('Подлинник! Стоимость ${rub(i.trueValue)}');
      log('Экспертиза: «${i.def.name}» — подлинник', amount: -c);
    }
    changed();
  }

  int repairCost(Item i) {
    final c = max(200, (i.value * 0.2).round());
    return has('workshop') ? (c * 0.6).round() : c;
  }

  void repair(Item i) {
    final c = repairCost(i);
    money -= c;
    totalSpent += c;
    final ok = rng.nextDouble() < (has('workshop') ? 0.95 : 0.85);
    if (ok) {
      i.broken = false;
      toast('Починено: ${i.def.name}');
      log('Ремонт удался: ${i.def.name}', amount: -c);
    } else {
      i.repairTried = true;
      toast('Не получилось. «${i.def.name}» теперь только на запчасти');
      log('Ремонт не удался: ${i.def.name}', amount: -c);
    }
    changed();
  }

  int quickPrice(Item i) => max(5, (i.trueValue * quickRate).round());

  void quickSell(Item i) {
    final p = quickPrice(i);
    items.remove(i);
    offers.removeWhere((o) => o.uid == i.uid);
    money += p;
    totalEarned += p;
    log('Продано скупщику: ${i.def.name}', amount: p);
    changed();
  }

  void listItem(Item i, int price) {
    i.listPrice = price;
    i.listedDay = day;
    changed();
  }

  void unlist(Item i) {
    i.listPrice = null;
    offers.removeWhere((o) => o.uid == i.uid);
    changed();
  }

  void _sell(Item i, int price, String buyer) {
    items.remove(i);
    offers.removeWhere((o) => o.uid == i.uid);
    money += price;
    totalEarned += price;
    log('Продано: ${i.def.name} ($buyer)', amount: price);
    if (i.fake && !i.appraised && price > i.trueValue * 3) {
      final snap = i.toJson();
      snap['lp'] = null;
      complaints.add(Complaint(snap, price, buyer, day + rint(1, 3)));
    }
  }

  void acceptOffer(Offer o) {
    final i = itemByUid(o.uid);
    offers.remove(o);
    if (i != null) _sell(i, o.price, o.buyer);
    changed();
  }

  void declineOffer(Offer o) {
    offers.remove(o);
    changed();
  }

  // ---------------------------------------------------------------- upgrades

  bool canBuy(UpgradeDef u) => !has(u.id) && money >= u.price && (u.requires == null || has(u.requires!));

  void buy(UpgradeDef u) {
    if (!canBuy(u)) return;
    money -= u.price;
    totalSpent += u.price;
    upgrades.add(u.id);
    log('Улучшение: ${u.name}', amount: -u.price);
    changed();
  }

  // ---------------------------------------------------------------- day cycle

  DaySummary nextDay() {
    final s = DaySummary();
    for (final l in List<Lot>.from(lots)) {
      if (l.status == 'won') storeLot(l);
    }
    final r = rent;
    money -= r;
    totalSpent += r;
    s.rent = r;
    log('Аренда склада', amount: -r);

    offers.removeWhere((o) => o.expires <= day);

    final siteK = has('site') ? 1.35 : 1.0;
    for (final i in items.where((x) => x.listed).toList()) {
      final price = i.listPrice!;
      final ratio = max(1, i.estimate) / max(1, price);
      final double p =
          (0.5 * pow(ratio, 2.2) * (0.6 + reputation / 125) * siteK * buyerBoost).clamp(0.02, 0.9).toDouble();
      if (rng.nextDouble() < p) {
        final buyer = pick(buyerNames);
        if (rng.nextDouble() < 0.6) {
          _sell(i, price, buyer);
          s.salesTotal += price;
          s.lines.add('Продано: ${i.def.name} за ${rub(price)}');
        } else if (!offers.any((o) => o.uid == i.uid)) {
          final op = roundVal((price * rd(0.72, 0.95)).round());
          offers.add(Offer(i.uid, op, buyer, day + 1));
          s.lines.add('Предложение за «${i.def.name}»: ${rub(op)}');
        }
      }
    }

    for (final c in List<Complaint>.from(complaints)) {
      if (c.due <= day + 1) {
        complaints.remove(c);
        if (rng.nextDouble() < settings.complaintChance) {
          final it = Item.fromJson(c.item);
          it.appraised = true;
          money -= c.price;
          reputation = max(0, reputation - 8);
          items.add(it);
          s.lines.add('${c.buyer} вернул «${it.def.name}»: это подделка. Возврат ${rub(c.price)}, репутация −8');
          log('Возврат подделки: ${it.def.name}', amount: -c.price);
        }
      }
    }

    capitalHistory.add(capital);
    if (capitalHistory.length > 365) capitalHistory.removeAt(0);
    if (reputation > 50) reputation--;
    if (reputation < 50 && rng.nextBool()) reputation++;

    day++;
    startDay();
    changed();
    return s;
  }

  // ---------------------------------------------------------------- events

  void resolveEvent(EventChoice c) {
    c.act();
    event = null;
    changed();
  }

  GameEvent? _rollEvent() {
    if (day == 1 || rng.nextDouble() > 0.45) return null;
    final opts = <GameEvent Function()>[];
    final sent = items.where((i) => i.def.sentimental && !i.listed).toList();
    if (sent.isNotEmpty) {
      opts.add(() => _ownerEvent(pick(sent)));
      opts.add(() => _ownerEvent(pick(sent)));
    }
    final valuable = items.where((i) => i.def.rarity.index >= 2 && !(i.appraised && i.fake) && !i.broken).toList();
    if (valuable.isNotEmpty) opts.add(() => _collectorEvent(pick(valuable)));
    final proto = items.where((i) => i.defId == 'prototype').toList();
    if (proto.isNotEmpty) opts.add(() => _protoEvent(proto.first));
    opts.add(() {
      quickRate = 0.65;
      return GameEvent('Гена в хорошем настроении', 'Скупщик сегодня платит 65% от стоимости вместо обычных 50%.',
          [EventChoice('Отлично', () {})]);
    });
    opts.add(() {
      absent.add('timur');
      return GameEvent('Тимур не пришёл', 'Самый азартный перекупщик сегодня пропускает торги. Конкуренция ниже.',
          [EventChoice('Понятно', () {})]);
    });
    opts.add(() {
      buyerBoost = 1.5;
      return GameEvent('Сезон распродаж', 'Этой ночью покупатели активнее: шанс продать выставленные вещи выше.',
          [EventChoice('Хорошо', () {})]);
    });
    return pick(opts)();
  }

  GameEvent _ownerEvent(Item i) {
    final owners = [
      ['Нина Аркадьевна, 81 год,', 'узнала'],
      ['Отставной лётчик Пётр Ильич', 'узнал'],
      ['Студентка Аня из Самары', 'узнала'],
      ['Учитель на пенсии Марк Семёнович', 'узнал'],
    ];
    final o = pick(owners);
    final half = max(100, (i.estimate / 2).round());
    final note = i.def.note.isNotEmpty ? i.def.note : 'Для человека это память.';
    return GameEvent(
      'Нашёлся владелец',
      '${o[0]} ${o[1]} свою вещь «${i.def.name}» на фото с вашего склада. $note',
      [
        EventChoice('Вернуть бесплатно', () {
          items.remove(i);
          reputation = min(100, reputation + 12);
          log('Вернули владельцу: ${i.def.name}');
          toast('Репутация +12');
        }),
        EventChoice('Продать за ${rub(half)}', () {
          items.remove(i);
          money += half;
          totalEarned += half;
          reputation = min(100, reputation + 3);
          log('Продали владельцу: ${i.def.name}', amount: half);
        }),
        EventChoice('Отказать', () {
          reputation = max(0, reputation - 4);
          log('Отказали владельцу: ${i.def.name}');
        }),
      ],
    );
  }

  GameEvent _collectorEvent(Item i) {
    final price = roundVal((i.estimate * rd(1.15, 1.5)).round());
    return GameEvent(
      'Коллекционер',
      'Коллекционер из Петербурга увидел «${i.def.name}» и предлагает ${rub(price)}. Сделка только сегодня, без торга.',
      [
        EventChoice('Продать', () => _sell(i, price, 'Коллекционер')),
        EventChoice('Отказаться', () {}),
      ],
    );
  }

  GameEvent _protoEvent(Item i) {
    const p = 350000;
    return GameEvent(
      'Звонок от производителя',
      'Компания, чей прототип смартфона лежит у вас на складе, предлагает ${rub(p)} за возврат и молчание. Иначе обещают юристов.',
      [
        EventChoice('Вернуть за ${rub(p)}', () {
          items.remove(i);
          money += p;
          totalEarned += p;
          log('Вернули прототип производителю', amount: p);
        }),
        EventChoice('Оставить себе', () {
          reputation = max(0, reputation - 5);
        }),
      ],
    );
  }

  // ---------------------------------------------------------------- save/load

  void newGame() {
    day = 1;
    money = settings.startMoney;
    capitalHistory = [];
    reputation = 50;
    lots = [];
    items = [];
    offers = [];
    complaints = [];
    journal = [];
    found = {};
    upgrades = {};
    milestonesShown = {};
    totalEarned = 0;
    totalSpent = 0;
    lotsWon = 0;
    bestFind = 0;
    bestFindName = '';
    startDay();
    lots[0] = _trainingLot();
    event = null;
  }

  Lot _trainingLot() {
    Item mk(String id, int v) => Item(uid: nextUid(), defId: id, value: v);
    return Lot(
      id: nextUid(),
      kindId: 'backpack',
      origin: 'Москва',
      code: 'SVO',
      weight: 4.2,
      tags: const ['Учебный лот'],
      items: [mk('hoodie', 1200), mk('thermos', 800), mk('console', 14000), mk('magazine', 20)],
      start: 300,
      training: true,
    );
  }

  /// Sells every junk item to the dealer. Returns (count, sum).
  List<int> sellAllJunk() {
    final junk = items.where((i) => i.def.rarity == Rarity.junk && !i.listed).toList();
    var sum = 0;
    for (final i in junk) {
      final p = quickPrice(i);
      items.remove(i);
      money += p;
      totalEarned += p;
      sum += p;
    }
    if (junk.isNotEmpty) log('Сдан весь хлам: ${junk.length} шт.', amount: sum);
    changed();
    return [junk.length, sum];
  }

  /// Lists every unlisted non-junk item at estimate * k.
  int listAll(double k) {
    var n = 0;
    for (final i in items) {
      if (i.listed || i.def.rarity == Rarity.junk) continue;
      i.listPrice = roundVal(max(10, (i.estimate * k).round()));
      i.listedDay = day;
      n++;
    }
    changed();
    return n;
  }

  void reset() {
    newGame();
    tutorialSeen = true;
    changed();
  }

  void markTutorialSeen() {
    tutorialSeen = true;
    save();
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'money': money,
        'rep': reputation,
        'lots': lots.map((l) => l.toJson()).toList(),
        'items': items.map((i) => i.toJson()).toList(),
        'offers': offers.map((o) => o.toJson()).toList(),
        'complaints': complaints.map((c) => c.toJson()).toList(),
        'journal': journal.map((e) => e.toJson()).toList(),
        'found': found.toList(),
        'up': upgrades.toList(),
        'ms': milestonesShown.toList(),
        'earned': totalEarned,
        'spent': totalSpent,
        'won': lotsWon,
        'best': bestFind,
        'bestName': bestFindName,
        'tut': tutorialSeen,
        'hist': capitalHistory,
      };

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_key);
      if (s == null) {
        newGame();
        return;
      }
      final j = jsonDecode(s) as Map<String, dynamic>;
      day = (j['day'] as num).toInt();
      money = (j['money'] as num).toInt();
      reputation = (j['rep'] as num).toInt();
      lots = (j['lots'] as List).map((e) => Lot.fromJson(e as Map<String, dynamic>)).toList();
      items = (j['items'] as List)
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .where((i) => defById.containsKey(i.defId))
          .toList();
      offers = (j['offers'] as List).map((e) => Offer.fromJson(e as Map<String, dynamic>)).toList();
      complaints = (j['complaints'] as List).map((e) => Complaint.fromJson(e as Map<String, dynamic>)).toList();
      journal = (j['journal'] as List).map((e) => JournalEntry.fromJson(e as Map<String, dynamic>)).toList();
      found = (j['found'] as List).map((e) => e as String).toSet();
      upgrades = (j['up'] as List).map((e) => e as String).toSet();
      milestonesShown = (j['ms'] as List).map((e) => (e as num).toInt()).toSet();
      totalEarned = (j['earned'] as num).toInt();
      totalSpent = (j['spent'] as num).toInt();
      lotsWon = (j['won'] as num).toInt();
      bestFind = (j['best'] as num).toInt();
      bestFindName = j['bestName'] as String;
      tutorialSeen = j['tut'] == true;
      capitalHistory = ((j['hist'] as List?) ?? const []).map((e) => (e as num).toInt()).toList();
      if (lots.isEmpty) startDay();
      event = null;
    } catch (e) {
      debugPrint('load failed: $e');
      newGame();
    }
  }

  Future<void> save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode(toJson()));
    } catch (e) {
      debugPrint('save failed: $e');
    }
  }
}
