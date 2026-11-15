import 'package:flutter/material.dart';

class AppRoutes {
  static const String initial = '/';
  
  // Define route names here
  // static const String login = '/login';
  // static const String home = '/home';

  static Map<String, WidgetBuilder> get routes {
    return {
      // initial: (context) => const SplashScreen(),
    };
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initial:
        // Return initial route widget
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('OneCamp Initializing...'))));
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
