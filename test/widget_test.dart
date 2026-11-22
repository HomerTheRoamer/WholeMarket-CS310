import 'package:flutter_test/flutter_test.dart';
import 'package:wholemarket_pricing/main.dart';

void main() {
  testWidgets('WholeMarket app loads successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const WholeMarketApp());

    expect(find.text('Pricing insights'), findsOneWidget);
  });
}
