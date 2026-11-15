import 'package:flutter/material.dart';
import '../features/marketplace/models/marketplace_item.dart';
import '../features/marketplace/screens/create_edit_item_screen.dart';
import '../features/marketplace/screens/item_detail_screen.dart';
import '../features/marketplace/screens/marketplace_browse_screen.dart';

class AppRoutes {
  static const String initial = '/';

  // Marketplace Feature Routes
  static const String marketplace = '/marketplace';
  static const String marketplaceDetail = '/marketplace/detail';
  static const String marketplaceCreate = '/marketplace/create';
  static const String marketplaceEdit = '/marketplace/edit';

  static Map<String, WidgetBuilder> get routes {
    return {
      marketplace: (context) => const MarketplaceBrowseScreen(),
    };
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initial:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('OneCamp Initializing...')),
          ),
        );
      case marketplace:
        return MaterialPageRoute(
          builder: (_) => const MarketplaceBrowseScreen(),
        );
      case marketplaceDetail:
        final item = settings.arguments as MarketplaceItem?;
        if (item == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Error: No item specified.')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ItemDetailScreen(item: item),
          settings: settings,
        );
      case marketplaceCreate:
        return MaterialPageRoute(
          builder: (_) => const CreateEditItemScreen(isEditing: false),
          settings: settings,
        );
      case marketplaceEdit:
        final item = settings.arguments as MarketplaceItem?;
        if (item == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Error: No item specified for editing.')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => CreateEditItemScreen(isEditing: true, item: item),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
