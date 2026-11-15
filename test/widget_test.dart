
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onecamp/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'App initialization smoke test',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const OneCampApp(
          homeOverride: Scaffold(
            body: Center(
              child: Text('OneCamp Initializing...'),
            ),
          ),
        ),
      );

      expect(
        find.text('OneCamp Initializing...'),
        findsOneWidget,
      );

      expect(
        find.byType(MaterialApp),
        findsOneWidget,
      );
    },
  );
}
