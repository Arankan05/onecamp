import 'package:flutter_test/flutter_test.dart';
import 'package:onecamp/routes/app_routes.dart';

void main() {
  group('Main Navigation Unit Tests', () {
    test('AppRoutes contains mainNavigation route definition', () {
      expect(AppRoutes.initial, equals('/'));
      expect(AppRoutes.mainNavigation, equals('/main'));
      expect(AppRoutes.routes.containsKey(AppRoutes.mainNavigation), isTrue);
      expect(AppRoutes.routes.containsKey(AppRoutes.chatList), isTrue);
      expect(AppRoutes.routes.containsKey(AppRoutes.newChat), isTrue);
      expect(AppRoutes.routes.containsKey(AppRoutes.createGroup), isTrue);
    });
  });
}
