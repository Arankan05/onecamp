import 'package:flutter_test/flutter_test.dart';
import 'package:onecamp/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OneCampApp());

    // Verify that the initial route is showing the initialization message.
    expect(find.text('OneCamp Initializing...'), findsOneWidget);
  });
}
