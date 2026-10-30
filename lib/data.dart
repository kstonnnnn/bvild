import 'package:flutter/material.dart';

enum Rarity { junk, common, good, rare, legendary }

const rarityLabels = ['Хлам', 'Обычное', 'Хорошее', 'Редкое', 'Легендарное'];
const rarityColors = [
  Color(0xFF8A8F98),
  Color(0xFF4E9A63),
  Color(0xFF3B78DB),
  Color(0xFF9653CF),
  Color(0xFFE0A21B),
];

class Cat {
  final String label;
  final IconData icon;
  const Cat(this.label, this.icon);
}

const Map<String, Cat> cats = {
  'clothes': Cat('Одежда', Icons.checkroom),
  'tech': Cat('Электроника', Icons.devices),
  'jewelry': Cat('Украшения', Icons.diamond),
  'watch': Cat('Часы', Icons.watch),
  'books': Cat('Книги и бумаги', Icons.menu_book),
  'toys': Cat('Игрушки', Icons.toys),
  'beauty': Cat('Косметика', Icons.spa),
  'art': Cat('Искусство', Icons.palette),
  'tools': Cat('Инструменты', Icons.handyman),
  'sport': Cat('Спорт и отдых', Icons.sports_soccer),
  'souvenir': Cat('Сувениры', Icons.card_giftcard),
  'antique': Cat('Антиквариат', Icons.hourglass_bottom),
  'music': Cat('Музыка', Icons.music_note),
  'food': Cat('Еда и напитки', Icons.local_cafe),
  'contraband': Cat('Без документов', Icons.report),
};

class ItemDef {
  final String id;
  final String name;
  final String cat;
  final Rarity rarity;
  final int minV;
  final int maxV;
  final double fake;
  final double broken;
  final bool sentimental;
  final IconData? icon;
  final String note;
  const ItemDef(this.id, this.name, this.cat, this.rarity, this.minV, this.maxV,
      {this.fake = 0, this.broken = 0, this.sentimental = false, this.icon, this.note = ''});
  IconData get iconData => icon ?? cats[cat]!.icon;
}

const List<ItemDef> itemDefs = [
  // хлам
  ItemDef('socks', 'Носки без пары', 'clothes', Rarity.junk, 10, 60),
  ItemDef('tshirt', 'Мятая футболка', 'clothes', Rarity.junk, 50, 200),
  ItemDef('charger', 'Зарядка непонятного стандарта', 'tech', Rarity.junk, 30, 150, icon: Icons.power),
  ItemDef('magazine', 'Журнал из самолёта', 'books', Rarity.junk, 10, 40),
  ItemDef('slippers', 'Тапочки из отеля', 'souvenir', Rarity.junk, 20, 70),
  ItemDef('umbrella', 'Сломанный зонт', 'tools', Rarity.junk, 20, 90, icon: Icons.beach_access),
  ItemDef('magnet', 'Магнит на холодильник', 'souvenir', Rarity.junk, 20, 90),
  ItemDef('snacks', 'Пачка чипсов с истёкшим сроком', 'food', Rarity.junk, 5, 30),
  ItemDef('pillow', 'Подушка для шеи', 'sport', Rarity.junk, 50, 250),
  // обычное
  ItemDef('jeans', 'Джинсы', 'clothes', Rarity.common, 400, 1500),
  ItemDef('hoodie', 'Худи', 'clothes', Rarity.common, 500, 1800),
  ItemDef('book', 'Роман в мягкой обложке', 'books', Rarity.common, 100, 450),
  ItemDef('headphones', 'Проводные наушники', 'tech', Rarity.common, 200, 900, icon: Icons.headphones),
  ItemDef('powerbank', 'Пауэрбанк', 'tech', Rarity.common, 500, 1500, broken: .2, icon: Icons.battery_charging_full),
  ItemDef('cosmetics', 'Набор косметики', 'beauty', Rarity.common, 600, 2500),
  ItemDef('toycar', 'Игрушечная машинка', 'toys', Rarity.common, 150, 600),
  ItemDef('plush', 'Плюшевый медведь', 'toys', Rarity.common, 200, 900, sentimental: true, note: 'С ним ребёнок засыпал каждую ночь.'),
  ItemDef('sunglasses', 'Солнцезащитные очки', 'clothes', Rarity.common, 300, 1500, fake: .3),
  ItemDef('thermos', 'Термос', 'sport', Rarity.common, 400, 1200),
  ItemDef('ball', 'Футбольный мяч', 'sport', Rarity.common, 400, 1500),
  ItemDef('wallet', 'Пустой кошелёк', 'clothes', Rarity.common, 300, 1500),
  ItemDef('scarf', 'Шерстяной шарф', 'clothes', Rarity.common, 300, 1200),
  ItemDef('tea', 'Коробка дорогого чая', 'food', Rarity.common, 400, 1600),
  ItemDef('figurine', 'Фарфоровая статуэтка', 'souvenir', Rarity.common, 300, 1400),
  ItemDef('drill', 'Аккумуляторная дрель', 'tools', Rarity.common, 1200, 3500, broken: .25),
  ItemDef('album', 'Семейный фотоальбом', 'books', Rarity.common, 100, 500, sentimental: true, note: 'Здесь фотографии трёх поколений семьи.'),
  // хорошее
  ItemDef('phone', 'Смартфон', 'tech', Rarity.good, 6000, 25000, broken: .35, icon: Icons.smartphone),
  ItemDef('laptop', 'Ноутбук', 'tech', Rarity.good, 12000, 45000, broken: .3, icon: Icons.laptop),
  ItemDef('tablet', 'Планшет', 'tech', Rarity.good, 8000, 22000, broken: .3, icon: Icons.tablet_android),
  ItemDef('camera', 'Фотоаппарат', 'tech', Rarity.good, 10000, 40000, broken: .25, icon: Icons.photo_camera),
  ItemDef('console', 'Портативная приставка', 'tech', Rarity.good, 9000, 20000, broken: .2, icon: Icons.sports_esports),
  ItemDef('earbuds', 'Беспроводные наушники', 'tech', Rarity.good, 3000, 12000, fake: .35, icon: Icons.headphones),
  ItemDef('perfume', 'Флакон дорогих духов', 'beauty', Rarity.good, 4000, 12000, fake: .4),
  ItemDef('jacket', 'Кожаная куртка', 'clothes', Rarity.good, 4000, 15000),
  ItemDef('drone', 'Квадрокоптер', 'tech', Rarity.good, 8000, 30000, broken: .35, icon: Icons.flight),
  ItemDef('wine', 'Коллекционное вино', 'food', Rarity.good, 3000, 15000, fake: .2),
  ItemDef('toolset', 'Профессиональный набор инструментов', 'tools', Rarity.good, 3000, 9000),
  ItemDef('sneakers', 'Кроссовки лимитированной серии', 'clothes', Rarity.good, 5000, 20000, fake: .45),
  ItemDef('ring', 'Серебряное кольцо', 'jewelry', Rarity.good, 1500, 6000, fake: .2),
  ItemDef('rod', 'Спиннинг с катушкой', 'sport', Rarity.good, 3000, 12000),
  ItemDef('pedal', 'Гитарная педаль', 'music', Rarity.good, 2500, 8000, broken: .2),
  ItemDef('legoset', 'Нераспечатанный конструктор', 'toys', Rarity.good, 4000, 16000),
  ItemDef('kimono', 'Шёлковое кимоно', 'clothes', Rarity.good, 3000, 14000),
  // редкое
  ItemDef('watch', 'Швейцарские часы', 'watch', Rarity.rare, 80000, 400000, fake: .7),
  ItemDef('chain', 'Золотая цепочка', 'jewelry', Rarity.rare, 25000, 90000, fake: .35),
  ItemDef('luxbag', 'Сумка люксового бренда', 'clothes', Rarity.rare, 40000, 180000, fake: .6, icon: Icons.shopping_bag),
  ItemDef('painting', 'Небольшая картина маслом', 'art', Rarity.rare, 15000, 150000, fake: .5),
  ItemDef('box', 'Старинная шкатулка', 'antique', Rarity.rare, 15000, 70000, sentimental: true, note: 'Шкатулка досталась владелице от бабушки.'),
  ItemDef('coins', 'Коллекция монет', 'antique', Rarity.rare, 10000, 120000, fake: .3),
  ItemDef('vinyl', 'Редкая виниловая пластинка', 'music', Rarity.rare, 6000, 60000),
  ItemDef('filmcam', 'Немецкая плёночная камера', 'tech', Rarity.rare, 60000, 250000, fake: .3, broken: .3, icon: Icons.photo_camera),
  ItemDef('earrings', 'Серьги с бриллиантами', 'jewelry', Rarity.rare, 50000, 250000, fake: .55),
  ItemDef('letters', 'Пачка старых писем', 'books', Rarity.rare, 500, 30000, sentimental: true, note: 'Письма с фронта, которые дед писал бабушке.'),
  ItemDef('violin', 'Старая скрипка', 'music', Rarity.rare, 20000, 300000, fake: .5),
  // легендарное
  ItemDef('meteorite', 'Метеорит с сертификатом', 'antique', Rarity.legendary, 300000, 1200000, fake: .5),
  ItemDef('egg', 'Ювелирное яйцо в императорском стиле', 'jewelry', Rarity.legendary, 200000, 2000000, fake: .85),
  ItemDef('firsted', 'Первое издание классики с автографом', 'books', Rarity.legendary, 150000, 900000, fake: .4),
  ItemDef('goldbar', 'Слиток золота, 100 граммов', 'jewelry', Rarity.legendary, 600000, 750000, fake: .3),
  ItemDef('prototype', 'Прототип неанонсированного смартфона', 'tech', Rarity.legendary, 200000, 1500000, icon: Icons.smartphone),
  // без документов
  ItemDef('beetles', 'Коллекция редких жуков без документов', 'contraband', Rarity.common, 0, 0),
  ItemDef('caviar', 'Три килограмма икры без маркировки', 'contraband', Rarity.common, 0, 0),
  ItemDef('ivory', 'Фигурка из слоновой кости', 'contraband', Rarity.common, 0, 0),
];

final Map<String, ItemDef> defById = {for (final d in itemDefs) d.id: d};

class Origin {
  final String city;
  final String code;
  final Map<String, double> w;
  const Origin(this.city, this.code, this.w);
}

const List<Origin> origins = [
  Origin('Токио', 'NRT', {'tech': 3, 'toys': 2, 'beauty': 1.5}),
  Origin('Дубай', 'DXB', {'jewelry': 3, 'watch': 3, 'beauty': 2}),
  Origin('Милан', 'MXP', {'clothes': 3, 'beauty': 2, 'art': 1.5}),
  Origin('Париж', 'CDG', {'art': 2.5, 'beauty': 2, 'clothes': 2, 'books': 1.5}),
  Origin('Стамбул', 'IST', {'antique': 2.5, 'souvenir': 2, 'clothes': 1.5}),
  Origin('Сочи', 'AER', {'sport': 2.5, 'souvenir': 2, 'clothes': 1.5}),
  Origin('Мурманск', 'MMK', {'sport': 2, 'tools': 2, 'food': 1.5}),
  Origin('Пекин', 'PEK', {'tech': 2.5, 'toys': 2.5, 'souvenir': 1.5}),
  Origin('Лондон', 'LHR', {'books': 2.5, 'antique': 2, 'music': 1.5}),
  Origin('Москва', 'SVO', {}),
  Origin('Нью-Йорк', 'JFK', {'music': 2, 'tech': 1.5, 'art': 1.5}),
  Origin('Женева', 'GVA', {'watch': 3, 'jewelry': 1.5}),
];

class LotTag {
  final String label;
  final double rare;
  final Map<String, double> w;
  const LotTag(this.label, this.rare, this.w);
}

const List<LotTag> lotTags = [
  LotTag('Хрупкое', 1.2, {'art': 2, 'tech': 1.5, 'antique': 2}),
  LotTag('Бизнес-класс', 1.5, {'tech': 1.5, 'watch': 2, 'jewelry': 1.5}),
  LotTag('Наклейки отелей', 1.0, {'souvenir': 2.5, 'clothes': 1.5}),
  LotTag('Перемотан скотчем', 0.6, {}),
  LotTag('Кодовый замок', 1.4, {'jewelry': 1.5, 'watch': 1.5}),
  LotTag('Детская бирка', 0.9, {'toys': 3, 'clothes': 1.5}),
  LotTag('Дипломатическая бирка', 2.0, {'antique': 1.5, 'art': 1.5, 'watch': 1.5}),
  LotTag('Сильно потрёпан', 0.75, {}),
];

LotTag? tagByLabel(String l) {
  for (final t in lotTags) {
    if (t.label == l) return t;
  }
  return null;
}

class LotKind {
  final String id;
  final String name;
  final IconData icon;
  final int minN;
  final int maxN;
  final double rare;
  final double wMin;
  final double wMax;
  final int minDay;
  final bool van;
  const LotKind(this.id, this.name, this.icon, this.minN, this.maxN, this.rare, this.wMin, this.wMax, this.minDay, this.van);
}

const List<LotKind> lotKinds = [
  LotKind('backpack', 'Рюкзак', Icons.backpack, 2, 4, .85, 2, 8, 1, false),
  LotKind('bag', 'Спортивная сумка', Icons.shopping_bag, 3, 6, .95, 4, 14, 1, false),
  LotKind('box', 'Коробка', Icons.inventory_2, 3, 8, .8, 3, 18, 1, false),
  LotKind('suitcase', 'Чемодан', Icons.luggage, 4, 8, 1.1, 8, 23, 2, false),
  LotKind('case', 'Алюминиевый кейс', Icons.work, 1, 3, 2.4, 3, 7, 4, false),
  LotKind('container', 'Контейнер', Icons.local_shipping, 14, 22, 1.25, 250, 600, 1, true),
];

LotKind kindById(String id) => lotKinds.firstWhere((k) => k.id == id);

class BidderDef {
  final String id;
  final String name;
  final String desc;
  final double mult;
  final List<String> specials;
  final double eager;
  const BidderDef(this.id, this.name, this.desc, this.mult, this.specials, this.eager);
}

const List<BidderDef> bidders = [
  BidderDef('gena', 'Гена-скупщик', 'Берёт дёшево и много, переплачивать не любит', .62, [], .8),
  BidderDef('elvira', 'Эльвира, антиквар', 'Охотится за стариной и искусством', .8, ['antique', 'art', 'jewelry'], .55),
  BidderDef('timur', 'Тимур-перекуп', 'Азартный, может переплатить', .92, [], 1.1),
  BidderDef('marina', 'Марина из сервиса', 'Скупает технику на запчасти', .75, ['tech'], .7),
];

BidderDef bidderById(String id) => bidders.firstWhere((b) => b.id == id);

class UpgradeDef {
  final String id;
  final String name;
  final String desc;
  final int price;
  final IconData icon;
  final String? requires;
  const UpgradeDef(this.id, this.name, this.desc, this.price, this.icon, [this.requires]);
}

const List<UpgradeDef> upgradeDefs = [
  UpgradeDef('storage1', 'Стеллажи', 'Плюс 15 мест на складе', 15000, Icons.grid_view),
  UpgradeDef('xray', 'Рентген-сканер', 'Просвечивать лоты бесплатно', 25000, Icons.document_scanner),
  UpgradeDef('workshop', 'Мастерская', 'Ремонт дешевле на 40% и почти всегда успешен', 35000, Icons.build),
  UpgradeDef('appraiser', 'Свой оценщик', 'Экспертиза подлинности в два раза дешевле', 40000, Icons.verified),
  UpgradeDef('site', 'Интернет-магазин', 'Покупатели приходят на треть чаще', 50000, Icons.storefront),
  UpgradeDef('storage2', 'Второй склад', 'Ещё 25 мест на складе', 60000, Icons.home_work, 'storage1'),
  UpgradeDef('van', 'Грузовой фургон', 'Доступ к торгам за целые контейнеры', 80000, Icons.local_shipping),
];

const List<String> buyerNames = [
  'Ирина из Казани',
  'Студент Миша',
  'Перекуп Стас',
  'Ольга Петровна',
  'Коллекционер Вадим',
  'Магазин «Вторая жизнь»',
  'Дмитрий, Екатеринбург',
  'Лена с барахолки',
  'Аркадий из Твери',
  'Блогер Кира',
];
