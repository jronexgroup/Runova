import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'data/auth/worker_auth_service.dart';
import 'firebase_options.dart';
import 'screens/login/worker_login_screen.dart';
import 'screens/workbench/worker_workbench_screen.dart';
import 'state/worker_state.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase (gracefully handled if offline)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[WorkerApp] Firebase init running offline-first: $e');
  }

  // 2. Initialize Session
  await WorkerAuthService.instance.init();

  if (WorkerAuthService.instance.isAuthenticated) {
    await WorkerState.instance.init();
  }

  runApp(const RunovaWorkerApp());
}

class RunovaWorkerApp extends StatelessWidget {
  const RunovaWorkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Runova Technician Workbench',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AnimatedBuilder(
        animation: WorkerAuthService.instance,
        builder: (context, _) {
          if (WorkerAuthService.instance.isAuthenticated) {
            // Load state when authenticated
            WorkerState.instance.init();
            return const WorkerWorkbenchScreen();
          }
          return const WorkerLoginScreen();
        },
      ),
    );
  }
}
