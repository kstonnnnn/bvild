import 'package:flutter_test/flutter_test.dart';
import 'package:lost_luggage/game.dart';

void main() {
  test('new game starts with lots and money', () {
    final g = GameState();
    g.newGame();
    expect(g.day, 1);
    expect(g.lots.isNotEmpty, true);
    expect(g.money, 30000);
  });
}
