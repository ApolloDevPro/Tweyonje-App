import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tweyonje/main.dart';

void main() {
  testWidgets('Tweyonje App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(child: TweyonjeApp()));

    // Initial render verification
    expect(find.byType(TweyonjeApp), findsOneWidget);

    // Tear down cleanly so background timers (e.g. periodic sync) are
    // cancelled rather than flagged as pending timers by the test binding.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
