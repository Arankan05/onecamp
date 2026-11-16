
import 'package:flutter/material.dart';

import 'screens/feed_test_login_screen.dart';
import 'screens/student_list_screen.dart';

class FeedTestApp extends StatelessWidget {
  const FeedTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneCamp Feed Test',
      debugShowCheckedModeBanner: false,

      routes: {
        '/students': (context) =>
        const StudentListScreen(),
      },

      home: const FeedTestLoginScreen(),
    );
  }
}
