import 'package:flutter_test/flutter_test.dart';
import 'package:wasteway/main.dart';

void main() {
  testWidgets('WasteWay app shell and navigation smoke test', (WidgetTester tester) async {
    // Build WasteWay app and trigger a frame.
    await tester.pumpWidget(const WasteWayApp());
    await tester.pumpAndSettle();

    // Verify app brand and header
    expect(find.text('WasteWay'), findsOneWidget);
    expect(find.text('Civic Alert'), findsOneWidget);

    // Verify 4 main navigation tabs are present
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Scan'), findsWidgets);
    expect(find.text('Passports'), findsWidgets);
    expect(find.text('Recyclers'), findsWidgets);

    // Verify dashboard metrics are rendered
    expect(find.text('Circular Economy Dashboard'), findsOneWidget);

    // Tap on the 'Recyclers' navigation tab
    await tester.tap(find.text('Recyclers').first);
    await tester.pumpAndSettle();

    // Verify facility directory renders
    expect(find.text('Recycling & Waste Directory'), findsOneWidget);
  });
}
