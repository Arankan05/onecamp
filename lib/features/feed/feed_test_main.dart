import 'package:flutter/material.dart';

import '../../core/services/firebase_service.dart';
import 'feed_test_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseService.initialize();

  runApp(const FeedTestApp());
}
