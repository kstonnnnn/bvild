import 'package:flutter/material.dart';

import 'i18n.dart';

enum Rarity { junk, common, good, rare, legendary }

List<String> get rarityLabels => ['Junk', 'Common', 'Good', 'Rare', 'Legendary'].map(tr).toList();
const rarityColors = [
  Color(0xFF8A8F98),
  Color(0xFF4E9A63),
  Color(0xFF3B78DB),
  Color(0xFF9653CF),
  Color(0xFFE0A21B),
];

class Cat {
  final String en;
  final IconData icon;
  const Cat(this.en, this.icon);
  String get label => tr(en);
}

const Map<String, Cat> cats = {
  'clothes': Cat('Clothing', Icons.checkroom),
  'tech': Cat('Electronics', Icons.devices),
  'jewelry': Cat('Jewelry', Icons.diamond),
  'watch': Cat('Watches', Icons.watch),
  'books': Cat('Books & papers', Icons.menu_book),
  'toys': Cat('Toys', Icons.toys),
  'beauty': Cat('Beauty', Icons.spa),
  'art': Cat('Art', Icons.palette),
  'tools': Cat('Tools', Icons.handyman),
  'sport': Cat('Sports & outdoors', Icons.sports_soccer),
  'souvenir': Cat('Souvenirs', Icons.card_giftcard),
  'antique': Cat('Antiques', Icons.hourglass_bottom),
  'music': Cat('Music', Icons.music_note),
  'food': Cat('Food & drink', Icons.local_cafe),
  'contraband': Cat('Undocumented', Icons.report),
};

class ItemDef {
  final String id;
  final String en;
  final String cat;
  final Rarity rarity;
  final int minV;
  final int maxV;
  final double fake;
  final double broken;
  final bool sentimental;
  final IconData? icon;
  final String noteEn;
  const ItemDef(this.id, this.en, this.cat, this.rarity, this.minV, this.maxV,
      {this.fake = 0, this.broken = 0, this.sentimental = false, this.icon, this.noteEn = ''});
  String get name => tr(en);
  String get note => noteEn.isEmpty ? '' : tr(noteEn);
  IconData get iconData => icon ?? cats[cat]!.icon;
}

const List<ItemDef> itemDefs = [
  // junk
  ItemDef('socks', 'Odd sock', 'clothes', Rarity.junk, 10, 60),
  ItemDef('tshirt', 'Crumpled T-shirt', 'clothes', Rarity.junk, 50, 200),
  ItemDef('charger', 'Charger for who knows what', 'tech', Rarity.junk, 30, 150, icon: Icons.power),
  ItemDef('magazine', 'In-flight magazine', 'books', Rarity.junk, 10, 40),
  ItemDef('slippers', 'Hotel slippers', 'souvenir', Rarity.junk, 20, 70),
  ItemDef('umbrella', 'Broken umbrella', 'tools', Rarity.junk, 20, 90, icon: Icons.beach_access),
  ItemDef('magnet', 'Fridge magnet', 'souvenir', Rarity.junk, 20, 90),
  ItemDef('snacks', 'Expired bag of chips', 'food', Rarity.junk, 5, 30),
  ItemDef('pillow', 'Neck pillow', 'sport', Rarity.junk, 50, 250),
  // common
  ItemDef('jeans', 'Jeans', 'clothes', Rarity.common, 400, 1500),
  ItemDef('hoodie', 'Hoodie', 'clothes', Rarity.common, 500, 1800),
  ItemDef('book', 'Paperback novel', 'books', Rarity.common, 100, 450),
  ItemDef('headphones', 'Wired earphones', 'tech', Rarity.common, 200, 900, icon: Icons.headphones),
  ItemDef('powerbank', 'Power bank', 'tech', Rarity.common, 500, 1500, broken: .2, icon: Icons.battery_charging_full),
  ItemDef('cosmetics', 'Makeup kit', 'beauty', Rarity.common, 600, 2500),
  ItemDef('toycar', 'Toy car', 'toys', Rarity.common, 150, 600),
  ItemDef('plush', 'Teddy bear', 'toys', Rarity.common, 200, 900, sentimental: true, noteEn: 'A child fell asleep with it every night.'),
  ItemDef('sunglasses', 'Sunglasses', 'clothes', Rarity.common, 300, 1500, fake: .3),
  ItemDef('thermos', 'Thermos', 'sport', Rarity.common, 400, 1200),
  ItemDef('ball', 'Soccer ball', 'sport', Rarity.common, 400, 1500),
  ItemDef('wallet', 'Empty wallet', 'clothes', Rarity.common, 300, 1500),
  ItemDef('scarf', 'Wool scarf', 'clothes', Rarity.common, 300, 1200),
  ItemDef('tea', 'Box of fancy tea', 'food', Rarity.common, 400, 1600),
  ItemDef('figurine', 'Porcelain figurine', 'souvenir', Rarity.common, 300, 1400),
  ItemDef('drill', 'Cordless drill', 'tools', Rarity.common, 1200, 3500, broken: .25),
  ItemDef('album', 'Family photo album', 'books', Rarity.common, 100, 500, sentimental: true, noteEn: 'Three generations of one family are in these pages.'),
  // good
  ItemDef('phone', 'Smartphone', 'tech', Rarity.good, 6000, 25000, broken: .35, icon: Icons.smartphone),
  ItemDef('laptop', 'Laptop', 'tech', Rarity.good, 12000, 45000, broken: .3, icon: Icons.laptop),
  ItemDef('tablet', 'Tablet', 'tech', Rarity.good, 8000, 22000, broken: .3, icon: Icons.tablet_android),
  ItemDef('camera', 'Digital camera', 'tech', Rarity.good, 10000, 40000, broken: .25, icon: Icons.photo_camera),
  ItemDef('console', 'Handheld console', 'tech', Rarity.good, 9000, 20000, broken: .2, icon: Icons.sports_esports),
  ItemDef('earbuds', 'Wireless earbuds', 'tech', Rarity.good, 3000, 12000, fake: .35, icon: Icons.headphones),
  ItemDef('perfume', 'Bottle of designer perfume', 'beauty', Rarity.good, 4000, 12000, fake: .4),
  ItemDef('jacket', 'Leather jacket', 'clothes', Rarity.good, 4000, 15000),
  ItemDef('drone', 'Camera drone', 'tech', Rarity.good, 8000, 30000, broken: .35, icon: Icons.flight),
  ItemDef('wine', 'Vintage wine', 'food', Rarity.good, 3000, 15000, fake: .2),
  ItemDef('toolset', 'Pro tool set', 'tools', Rarity.good, 3000, 9000),
  ItemDef('sneakers', 'Limited-edition sneakers', 'clothes', Rarity.good, 5000, 20000, fake: .45),
  ItemDef('ring', 'Silver ring', 'jewelry', Rarity.good, 1500, 6000, fake: .2),
  ItemDef('rod', 'Fishing rod and reel', 'sport', Rarity.good, 3000, 12000),
  ItemDef('pedal', 'Guitar effects pedal', 'music', Rarity.good, 2500, 8000, broken: .2),
  ItemDef('legoset', 'Sealed building set', 'toys', Rarity.good, 4000, 16000),
  ItemDef('kimono', 'Silk kimono', 'clothes', Rarity.good, 3000, 14000),
  // rare
  ItemDef('watch', 'Swiss watch', 'watch', Rarity.rare, 80000, 400000, fake: .7),
  ItemDef('chain', 'Gold chain', 'jewelry', Rarity.rare, 25000, 90000, fake: .35),
  ItemDef('luxbag', 'Luxury designer bag', 'clothes', Rarity.rare, 40000, 180000, fake: .6, icon: Icons.shopping_bag),
  ItemDef('painting', 'Small oil painting', 'art', Rarity.rare, 15000, 150000, fake: .5),
  ItemDef('box', 'Antique jewelry box', 'antique', Rarity.rare, 15000, 70000, sentimental: true, noteEn: 'The owner inherited it from her grandmother.'),
  ItemDef('coins', 'Coin collection', 'antique', Rarity.rare, 10000, 120000, fake: .3),
  ItemDef('vinyl', 'Rare vinyl record', 'music', Rarity.rare, 6000, 60000),
  ItemDef('filmcam', 'German film camera', 'tech', Rarity.rare, 60000, 250000, fake: .3, broken: .3, icon: Icons.photo_camera),
  ItemDef('earrings', 'Diamond earrings', 'jewelry', Rarity.rare, 50000, 250000, fake: .55),
  ItemDef('letters', 'Bundle of old letters', 'books', Rarity.rare, 500, 30000, sentimental: true, noteEn: 'Letters a soldier wrote home to his sweetheart.'),
  ItemDef('violin', 'Old violin', 'music', Rarity.rare, 20000, 300000, fake: .5),
  // legendary
  ItemDef('meteorite', 'Certified meteorite', 'antique', Rarity.legendary, 300000, 1200000, fake: .5),
  ItemDef('egg', 'Imperial-style jeweled egg', 'jewelry', Rarity.legendary, 200000, 2000000, fake: .85),
  ItemDef('firsted', 'Signed first edition classic', 'books', Rarity.legendary, 150000, 900000, fake: .4),
  ItemDef('goldbar', '100 g gold bar', 'jewelry', Rarity.legendary, 600000, 750000, fake: .3),
  ItemDef('prototype', 'Unreleased smartphone prototype', 'tech', Rarity.legendary, 200000, 1500000, icon: Icons.smartphone),
  // contraband
  ItemDef('beetles', 'Rare beetle collection, no permits', 'contraband', Rarity.common, 0, 0),
  ItemDef('caviar', 'Three kilos of unlabeled caviar', 'contraband', Rarity.common, 0, 0),
  ItemDef('ivory', 'Ivory figurine', 'contraband', Rarity.common, 0, 0),
];

final Map<String, ItemDef> defById = {for (final d in itemDefs) d.id: d};

class Origin {
  final String city;
  final String code;
  final Map<String, double> w;
  const Origin(this.city, this.code, this.w);
}

const List<Origin> origins = [
  Origin('Tokyo', 'NRT', {'tech': 3, 'toys': 2, 'beauty': 1.5}),
  Origin('Dubai', 'DXB', {'jewelry': 3, 'watch': 3, 'beauty': 2}),
  Origin('Milan', 'MXP', {'clothes': 3, 'beauty': 2, 'art': 1.5}),
  Origin('Paris', 'CDG', {'art': 2.5, 'beauty': 2, 'clothes': 2, 'books': 1.5}),
  Origin('Istanbul', 'IST', {'antique': 2.5, 'souvenir': 2, 'clothes': 1.5}),
  Origin('Honolulu', 'HNL', {'sport': 2.5, 'souvenir': 2, 'clothes': 1.5}),
  Origin('Anchorage', 'ANC', {'sport': 2, 'tools': 2, 'food': 1.5}),
  Origin('Beijing', 'PEK', {'tech': 2.5, 'toys': 2.5, 'souvenir': 1.5}),
  Origin('London', 'LHR', {'books': 2.5, 'antique': 2, 'music': 1.5}),
  Origin('Chicago', 'ORD', {}),
  Origin('New York', 'JFK', {'music': 2, 'tech': 1.5, 'art': 1.5}),
  Origin('Geneva', 'GVA', {'watch': 3, 'jewelry': 1.5}),
];

class LotTag {
  final String label;
  final double rare;
  final Map<String, double> w;
  const LotTag(this.label, this.rare, this.w);
  String get display => tr(label);
}

const List<LotTag> lotTags = [
  LotTag('Fragile', 1.2, {'art': 2, 'tech': 1.5, 'antique': 2}),
  LotTag('Business class', 1.5, {'tech': 1.5, 'watch': 2, 'jewelry': 1.5}),
  LotTag('Hotel stickers', 1.0, {'souvenir': 2.5, 'clothes': 1.5}),
  LotTag('Taped shut', 0.6, {}),
  LotTag('Combination lock', 1.4, {'jewelry': 1.5, 'watch': 1.5}),
  LotTag('Kid\'s name tag', 0.9, {'toys': 3, 'clothes': 1.5}),
  LotTag('Diplomatic tag', 2.0, {'antique': 1.5, 'art': 1.5, 'watch': 1.5}),
  LotTag('Badly worn', 0.75, {}),
];

LotTag? tagByLabel(String l) {
  for (final t in lotTags) {
    if (t.label == l) return t;
  }
  return null;
}

class LotKind {
  final String id;
  final String en;
  final IconData icon;
  final int minN;
  final int maxN;
  final double rare;
  final double wMin;
  final double wMax;
  final int minDay;
  final bool van;
  const LotKind(this.id, this.en, this.icon, this.minN, this.maxN, this.rare, this.wMin, this.wMax, this.minDay, this.van);
  String get name => tr(en);
}

const List<LotKind> lotKinds = [
  LotKind('backpack', 'Backpack', Icons.backpack, 2, 4, .85, 2, 8, 1, false),
  LotKind('bag', 'Duffel bag', Icons.shopping_bag, 3, 6, .95, 4, 14, 1, false),
  LotKind('box', 'Cardboard box', Icons.inventory_2, 3, 8, .8, 3, 18, 1, false),
  LotKind('suitcase', 'Suitcase', Icons.luggage, 4, 8, 1.1, 8, 23, 2, false),
  LotKind('case', 'Aluminum case', Icons.work, 1, 3, 2.4, 3, 7, 4, false),
  LotKind('container', 'Cargo container', Icons.local_shipping, 14, 22, 1.25, 250, 600, 1, true),
];

LotKind kindById(String id) => lotKinds.firstWhere((k) => k.id == id);

class BidderDef {
  final String id;
  final String nameEn;
  final String descEn;
  final double mult;
  final List<String> specials;
  final double eager;
  const BidderDef(this.id, this.nameEn, this.descEn, this.mult, this.specials, this.eager);
  String get name => tr(nameEn);
  String get desc => tr(descEn);
}

const List<BidderDef> bidders = [
  BidderDef('gena', 'Gus the Pawnbroker', 'Buys cheap and buys a lot. Hates overpaying', .62, [], .8),
  BidderDef('elvira', 'Eleanor, antiques dealer', 'Hunts for antiques, art and jewelry', .8, ['antique', 'art', 'jewelry'], .55),
  BidderDef('timur', 'Tony the Flipper', 'A gambler. Sometimes overpays', .92, [], 1.1),
  BidderDef('marina', 'Maria from the repair shop', 'Buys electronics for parts', .75, ['tech'], .7),
];

BidderDef bidderById(String id) => bidders.firstWhere((b) => b.id == id);

class UpgradeDef {
  final String id;
  final String nameEn;
  final String descEn;
  final int price;
  final IconData icon;
  final String? requires;
  const UpgradeDef(this.id, this.nameEn, this.descEn, this.price, this.icon, [this.requires]);
  String get name => tr(nameEn);
  String get desc => tr(descEn);
}

const List<UpgradeDef> upgradeDefs = [
  UpgradeDef('storage1', 'Shelving', '15 more storage slots', 15000, Icons.grid_view),
  UpgradeDef('xray', 'X-ray scanner', 'Scan lots for free', 25000, Icons.document_scanner),
  UpgradeDef('workshop', 'Workshop', 'Repairs cost 40% less and almost never fail', 35000, Icons.build),
  UpgradeDef('appraiser', 'In-house appraiser', 'Authenticity checks cost half as much', 40000, Icons.verified),
  UpgradeDef('site', 'Online store', 'Buyers show up a third more often', 50000, Icons.storefront),
  UpgradeDef('storage2', 'Second warehouse', '25 more storage slots', 60000, Icons.home_work, 'storage1'),
  UpgradeDef('van', 'Cargo van', 'Bid on entire cargo containers', 80000, Icons.local_shipping),
];

const List<String> buyerNames = [
  'Irene from Denver',
  'College kid Mike',
  'Reseller Steve',
  'Mrs. Patterson',
  'Collector Victor',
  'Second Life Thrift',
  'Dave in Austin',
  'Flea-market Lena',
  'Arthur from Tulsa',
  'Vlogger Kira',
];
