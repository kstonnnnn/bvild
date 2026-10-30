import 'dart:math';

import 'data.dart';

class Item {
  final String uid;
  final String defId;
  int value;
  bool fake;
  bool broken;
  bool appraised;
  bool repairTried;
  int? listPrice;
  int listedDay;

  Item({
    required this.uid,
    required this.defId,
    required this.value,
    this.fake = false,
    this.broken = false,
    this.appraised = false,
    this.repairTried = false,
    this.listPrice,
    this.listedDay = 0,
  });

  ItemDef get def => defById[defId]!;
  bool get fakePossible => def.fake > 0;
  bool get listed => listPrice != null;
  bool get contraband => def.cat == 'contraband';

  int get _brokenValue => (value * (repairTried ? 0.15 : 0.3)).round();

  /// Real worth of the thing.
  int get trueValue {
    if (fake) return max(10, (value * 0.04).round());
    if (broken) return _brokenValue;
    return value;
  }

  /// What the player believes it is worth.
  int get estimate {
    if (appraised || !fakePossible) return trueValue;
    return broken ? _brokenValue : value;
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'd': defId,
        'v': value,
        'f': fake,
        'b': broken,
        'a': appraised,
        'r': repairTried,
        'lp': listPrice,
        'ld': listedDay,
      };

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        uid: j['uid'] as String,
        defId: j['d'] as String,
        value: (j['v'] as num).toInt(),
        fake: j['f'] == true,
        broken: j['b'] == true,
        appraised: j['a'] == true,
        repairTried: j['r'] == true,
        listPrice: j['lp'] == null ? null : (j['lp'] as num).toInt(),
        listedDay: j['ld'] == null ? 0 : (j['ld'] as num).toInt(),
      );
}

class Lot {
  final String id;
  final String kindId;
  final String origin;
  final String code;
  final double weight;
  final List<String> tags;
  final List<Item> items;
  final int start;
  bool xray;

  /// open, won, stored, lost, unsold
  String status;
  int? finalPrice;
  String? winner;

  Lot({
    required this.id,
    required this.kindId,
    required this.origin,
    required this.code,
    required this.weight,
    required this.tags,
    required this.items,
    required this.start,
    this.xray = false,
    this.status = 'open',
    this.finalPrice,
    this.winner,
  });

  LotKind get kind => kindById(kindId);
  String get title => '${kind.name} · $origin';
  int get nominal => items.fold<int>(0, (s, i) => s + i.value);
  int get realValue => items.fold<int>(0, (s, i) => s + i.trueValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'k': kindId,
        'o': origin,
        'c': code,
        'w': weight,
        't': tags,
        'i': items.map((e) => e.toJson()).toList(),
        's': start,
        'x': xray,
        'st': status,
        'fp': finalPrice,
        'win': winner,
      };

  factory Lot.fromJson(Map<String, dynamic> j) => Lot(
        id: j['id'] as String,
        kindId: j['k'] as String,
        origin: j['o'] as String,
        code: j['c'] as String,
        weight: (j['w'] as num).toDouble(),
        tags: (j['t'] as List).map((e) => e as String).toList(),
        items: (j['i'] as List)
            .map((e) => Item.fromJson(e as Map<String, dynamic>))
            .where((i) => defById.containsKey(i.defId))
            .toList(),
        start: (j['s'] as num).toInt(),
        xray: j['x'] == true,
        status: j['st'] as String,
        finalPrice: j['fp'] == null ? null : (j['fp'] as num).toInt(),
        winner: j['win'] as String?,
      );
}

class Offer {
  final String uid;
  final int price;
  final String buyer;
  final int expires;
  Offer(this.uid, this.price, this.buyer, this.expires);

  Map<String, dynamic> toJson() => {'u': uid, 'p': price, 'b': buyer, 'e': expires};
  factory Offer.fromJson(Map<String, dynamic> j) =>
      Offer(j['u'] as String, (j['p'] as num).toInt(), j['b'] as String, (j['e'] as num).toInt());
}

class Complaint {
  final Map<String, dynamic> item;
  final int price;
  final String buyer;
  final int due;
  Complaint(this.item, this.price, this.buyer, this.due);

  Map<String, dynamic> toJson() => {'i': item, 'p': price, 'b': buyer, 'd': due};
  factory Complaint.fromJson(Map<String, dynamic> j) => Complaint(
      Map<String, dynamic>.from(j['i'] as Map), (j['p'] as num).toInt(), j['b'] as String, (j['d'] as num).toInt());
}

class JournalEntry {
  final int day;
  final String text;
  final int? amount;
  JournalEntry(this.day, this.text, this.amount);

  Map<String, dynamic> toJson() => {'d': day, 't': text, 'a': amount};
  factory JournalEntry.fromJson(Map<String, dynamic> j) =>
      JournalEntry((j['d'] as num).toInt(), j['t'] as String, j['a'] == null ? null : (j['a'] as num).toInt());
}
