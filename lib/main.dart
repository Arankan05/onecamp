import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/screens/main_navigation_screen.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase for the actual application.
  await FirebaseService.initialize();

  runApp(const OneCampApp());
}

class OneCampApp extends StatelessWidget {
  final Widget? homeOverride;

  const OneCampApp({
    super.key,
    this.homeOverride,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneCamp',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: homeOverride ?? const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Check Firebase authentication status and onboarding status.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      if (Firebase.apps.isEmpty) {
        return const Scaffold(
          body: Center(
            child: Text('OneCamp Initializing...'),
          ),
        );
      }
    } catch (_) {
      return const Scaffold(
        body: Center(
          child: Text('OneCamp Initializing...'),
        ),
      );
    }

    Stream<User?>? authStream;
    try {
      authStream = FirebaseAuth.instance.authStateChanges();
    } catch (_) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: authStream,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        try {
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.usersCollection)
                .doc(user.uid)
                .snapshots(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (profileSnapshot.hasError ||
                  !profileSnapshot.hasData ||
                  !profileSnapshot.data!.exists) {
                return const OnboardingScreen();
              }

              final data = profileSnapshot.data!.data();
              final onboardingCompleted =
                  data?['onboardingCompleted'] as bool? ?? false;

              if (onboardingCompleted) {
                return const MainNavigationScreen();
              }

              return const OnboardingScreen();
            },
          );
        } catch (_) {
          return const OnboardingScreen();
        }
      },
    );
  }
}
