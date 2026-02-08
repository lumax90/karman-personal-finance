import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karman/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: FinanceCrmApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Özet'), findsWidgets);
  });
}
