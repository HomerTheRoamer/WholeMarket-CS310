
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wholemarket/main.dart';

void main() {
  testWidgets(
    'WholeMarket opens with Dashboard selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(const WholeMarketApp());

      // Verify bottom navigation without relying on SQLite.
      final navigationBar =
      tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );

      expect(navigationBar.selectedIndex, 0);

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Pricing'), findsOneWidget);
      expect(find.text('Promos'), findsOneWidget);
    },
  );

  testWidgets(
    'User can navigate to Inventory screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(const WholeMarketApp());

      await tester.tap(find.text('Inventory'));
      await tester.pumpAndSettle();

      expect(find.text('Search products'), findsOneWidget);
    },
  );
}
