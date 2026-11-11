import 'package:flutter/material.dart';
import 'data/remote/firebase_manager.dart';
import 'screens/main_navigation_screen.dart';
import 'state/shop_state.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase (gracefully runs offline-first if credentials not yet dropped)
  await FirebaseManager.instance.initialize();

  // 2. Initialize Local SQLite and load state
  await ShopState.instance.init();

  runApp(const RunovaAdminApp());
}

class RunovaAdminApp extends StatelessWidget {
  const RunovaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Runova Shop Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationScreen(),
    );
  }
}
