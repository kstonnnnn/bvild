import 'package:flutter/material.dart';

import '../settings.dart';

class _Page {
  final IconData icon;
  final String title;
  final String text;
  const _Page(this.icon, this.title, this.text);
}

const _pages = [
  _Page(Icons.luggage, 'Unclaimed bags',
      'Every day the airport auctions off suitcases, bags and boxes nobody came back for. You buy them sight unseen and flip whatever is inside.'),
  _Page(Icons.travel_explore, 'Read the clues',
      'Departure city, weight and tags tell a story. Dubai bags often carry jewelry, Tokyo bags carry gadgets. Business class and combination locks hint at valuables. An X-ray shows what is inside.'),
  _Page(Icons.gavel, 'Bid smart',
      'Rival flippers each have their own style. Every bid resets the timer. You can set an auto-bid up to any amount.'),
  _Page(Icons.verified, 'Check your finds',
      'Watches, bags and jewelry are often fakes, and electronics may be broken. Appraisals and repairs cost money but save you from costly mistakes.'),
  _Page(Icons.storefront, 'Sell wisely',
      'The pawnbroker pays on the spot, but only half. Listing for sale earns more, but buyers only come at night. Sell a fake as the real deal and it may come back.'),
  _Page(Icons.emoji_events, 'Goal: \$100,000',
      'Pay the rent, grow your warehouse, buy upgrades and reach a net worth of \$100,000. Today\'s first lot is a training lot, so start there.'),
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
              child: TextButton(onPressed: _finish, child: const Text('Skip')),
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
                          Text('Name your warehouse',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _name,
                            maxLength: 24,
                            textAlign: TextAlign.center,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'For example, Sam\'s Baggage Barn',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          Text('You can leave it blank and change it later in Settings.',
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
                child: Text(last ? 'Start playing' : 'Next', style: const TextStyle(fontSize: 16)),
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
