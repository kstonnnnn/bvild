import 'package:flutter/material.dart';

import '../game.dart';
import '../settings.dart';
import 'auction_tab.dart';
import 'market_tab.dart';
import 'more_tab.dart';
import 'onboarding.dart';
import 'settings_screen.dart';
import '../updates.dart';
import 'warehouse_tab.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  bool _eventOpen = false;

  @override
  void initState() {
    super.initState();
    game.addListener(_onGame);
    settings.addListener(_onSettings);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!settings.onboarded) {
        await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()));
        game.markTutorialSeen();
      }
      _onGame();
      if (mounted) silentUpdateCheck(context);
    });
  }

  @override
  void dispose() {
    game.removeListener(_onGame);
    settings.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  void _onGame() {
    if (!mounted) return;
    if (game.toasts.isNotEmpty) {
      final msgs = List<String>.from(game.toasts);
      game.toasts.clear();
      final m = ScaffoldMessenger.of(context);
      for (final t in msgs) {
        m.showSnackBar(SnackBar(content: Text(t), duration: const Duration(seconds: 3)));
      }
    }
    final route = ModalRoute.of(context);
    final onTop = route == null || route.isCurrent;
    if (game.event != null && !_eventOpen && onTop) {
      _eventOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showEvent());
    }
    if (game.milestoneToShow != null && onTop) {
      final k = game.milestoneToShow!;
      game.milestoneToShow = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showMilestone(k));
    }
    setState(() {});
  }

  Future<void> _showEvent() async {
    final e = game.event;
    if (e == null || !mounted) {
      _eventOpen = false;
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(e.title),
        content: Text(e.text),
        actions: [
          for (final c in e.choices)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                game.resolveEvent(c);
              },
              child: Text(c.label),
            ),
        ],
      ),
    );
    _eventOpen = false;
  }

  Future<void> _showMilestone(int k) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.emoji_events, size: 40),
        title: Text(GameState.milestoneTitles[k]),
        content: Text('Your net worth reached ${cash(GameState.milestones[k])}. '
            '${k == 2 ? 'You rule the lost luggage business. Keep playing as long as you like.' : 'Next goal: ${cash(GameState.milestones[k + 1])}.'}'),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continue'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final offers = game.offers.length;
    final full = game.items.length >= game.capacity;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(settings.storeTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text('Day ${game.day}', style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
            icon: const Icon(Icons.settings_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(20)),
                child: Text(cash(game.money),
                    style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSecondaryContainer)),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: tab,
        children: const [AuctionTab(), WarehouseTab(), MarketTab(), MoreTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.gavel), label: 'Auction'),
          NavigationDestination(
            icon: Badge(isLabelVisible: full, label: const Text('!'), child: const Icon(Icons.inventory_2_outlined)),
            selectedIcon: const Icon(Icons.inventory_2),
            label: 'Storage',
          ),
          NavigationDestination(
            icon: Badge(isLabelVisible: offers > 0, label: Text('$offers'), child: const Icon(Icons.storefront_outlined)),
            selectedIcon: const Icon(Icons.storefront),
            label: 'Sales',
          ),
          const NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
