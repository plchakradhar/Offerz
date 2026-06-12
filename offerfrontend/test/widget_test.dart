import 'package:flutter_test/flutter_test.dart';
import 'package:offerfrontend/main.dart';

void main() {
  testWidgets('Offerz app loads successfully', (
    WidgetTester tester,
  ) async {
    // Build the app
    await tester.pumpWidget(const OfferzApp());

    // Verify app loads
    expect(find.byType(OfferzApp), findsOneWidget);
  });
}