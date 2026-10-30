import 'package:flutter/material.dart';

import '../settings.dart';

class _Page {
  final IconData icon;
  final String title;
  final String text;
  const _Page(this.icon, this.title, this.text);
}

const _pages = [
  _Page(Icons.luggage, 'Ничейный багаж',
      'Каждый день склад аэропорта продаёт чемоданы, сумки и коробки, за которыми никто не пришёл. Ты покупаешь их вслепую и перепродаёшь содержимое.'),
  _Page(Icons.travel_explore, 'Читай подсказки',
      'Город вылета, вес и бирки многое говорят. Из Дубая чаще везут украшения, из Токио — технику. «Бизнес-класс» и «Кодовый замок» намекают на ценности. Рентген покажет, что внутри.'),
  _Page(Icons.gavel, 'Торгуйся',
      'Против тебя играют перекупщики с разными характерами. После каждой ставки таймер начинается заново. Можно включить автоставку до нужной суммы.'),
  _Page(Icons.verified, 'Проверяй находки',
      'Часы, сумки и украшения часто оказываются подделками, техника бывает сломана. Экспертиза и ремонт стоят денег, но спасают от ошибок.'),
  _Page(Icons.storefront, 'Продавай с умом',
      'Скупщик платит сразу, но половину цены. На площадке можно продать дороже, но покупатели приходят только ночью. Подделку, проданную как оригинал, могут вернуть.'),
  _Page(Icons.emoji_events, 'Цель — миллион',
      'Плати аренду, расширяй склад, покупай улучшения и доведи капитал до миллиона рублей. Первый лот сегодня учебный — с него и начни.'),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  final _name = TextEditingController(text: settings.storeName);
  int page = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    _name.dispose();
    super.dispose();
  }

  void _finish() {
    settings.set((s) {
      s.storeName = _name.text.trim();
      s.onboarded = true;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final last = page == _pages.length;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _finish, child: const Text('Пропустить')),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _pages.length + 1,
                onPageChanged: (i) => setState(() => page = i),
                itemBuilder: (context, i) {
                  if (i == _pages.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _bigIcon(cs, Icons.home_work),
                          const SizedBox(height: 28),
                          Text('Как назовёшь свой склад?',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _name,
                            maxLength: 24,
                            textAlign: TextAlign.center,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Например, «Багаж у Саши»',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          Text('Можно оставить пустым и поменять потом в настройках.',
                              textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    );
                  }
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _bigIcon(cs, p.icon),
                        const SizedBox(height: 28),
                        Text(p.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 14),
                        Text(p.text,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i <= _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == page ? cs.primary : cs.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                onPressed: last
                    ? _finish
                    : () => _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                child: Text(last ? 'Начать игру' : 'Дальше', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigIcon(ColorScheme cs, IconData icon) => Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
        child: Icon(icon, size: 60, color: cs.onPrimaryContainer),
      );
}
