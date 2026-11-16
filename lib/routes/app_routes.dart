import 'package:flutter/material.dart';

import '../features/marketplace/models/marketplace_item.dart';
import '../features/marketplace/screens/create_edit_item_screen.dart';
import '../features/marketplace/screens/item_detail_screen.dart';
import '../features/marketplace/screens/marketplace_browse_screen.dart';
import '../features/marketplace/theme/marketplace_theme.dart';

class AppRoutes {
  static const String initial = '/';

  // Marketplace Feature Routes
  static const String marketplace = '/marketplace';
  static const String marketplaceDetail = '/marketplace/detail';
  static const String marketplaceCreate = '/marketplace/create';
  static const String marketplaceEdit = '/marketplace/edit';

  static Map<String, WidgetBuilder> get routes {
    return {marketplace: (context) => const MarketplaceBrowseScreen()};
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initial:
        return MaterialPageRoute(builder: (_) => const AppInitScreen());
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
              body: Center(
                child: Text('Error: No item specified for editing.'),
              ),
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

/// Startup initialization screen that transitions smoothly to the main marketplace screen.
class AppInitScreen extends StatefulWidget {
  const AppInitScreen({super.key});

  @override
  State<AppInitScreen> createState() => _AppInitScreenState();
}

class _AppInitScreenState extends State<AppInitScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.marketplace);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MarketplaceTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: MarketplaceTheme.primary),
            const SizedBox(height: 16),
            Text(
              'OneCamp Initializing...',
              style: TextStyle(
                color: MarketplaceTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
