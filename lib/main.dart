
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/services/firebase_service.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';

import 'features/auth/screens/login_screen.dart';
import 'features/profile/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase.
  await FirebaseService.initialize();

  runApp(const OneCampApp());
}

class OneCampApp extends StatelessWidget {
  const OneCampApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneCamp',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Check Firebase authentication status.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // Show loading while checking authentication.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is logged in.
        if (snapshot.hasData) {
          return const ProfileScreen();
        }

        // User is not logged in.
        return const LoginScreen();
      },
    );
  }
}
