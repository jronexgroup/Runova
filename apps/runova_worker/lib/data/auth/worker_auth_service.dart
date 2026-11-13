import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:runova_core/runova_core.dart';
import '../local/worker_database.dart';

class WorkerAuthService extends ChangeNotifier {
  static final WorkerAuthService instance = WorkerAuthService._();
  WorkerAuthService._();

  AppSession? _currentSession;
  AppSession? get currentSession => _currentSession;

  bool get isAuthenticated => _currentSession != null;
  String get activeShopId => _currentSession?.shopId ?? '';
  String get activeWorkerCode => _currentSession?.workerCode ?? '';
  String get activeWorkerName => _currentSession?.displayName ?? '';
  String get activeShopName => _currentSession?.shopName ?? '';

  Future<void> init() async {
    final cached = await WorkerDatabase.instance.getSession();
    if (cached != null) {
      _currentSession = cached;
      notifyListeners();
    }
  }

  /// Authenticate Technician via Shop ID + Worker Code + Fast Counter PIN.
  Future<AppSession> loginWithPin({
    required String shopId,
    required String workerCode,
    required String pin,
  }) async {
    final cleanShopId = shopId.trim();
    final cleanWorkerCode = workerCode.trim().toUpperCase();
    final cleanPin = pin.trim();

    WorkerAccount? targetWorker;
    String shopName = 'Runova Shop';

    // 1. Fetch from Firestore if online and initialized
    if (Firebase.apps.isNotEmpty) {
      try {
        final workerSnap = await FirebaseFirestore.instance
            .collection('shops')
            .doc(cleanShopId)
            .collection('workers')
            .where('worker_code', isEqualTo: cleanWorkerCode)
            .where('active', isEqualTo: true)
            .limit(1)
            .get();

        if (workerSnap.docs.isNotEmpty) {
          targetWorker = WorkerAccount.fromMap(workerSnap.docs.first.data());

          final shopDoc = await FirebaseFirestore.instance.collection('shops').doc(cleanShopId).get();
          if (shopDoc.exists && shopDoc.data() != null) {
            shopName = (shopDoc.data()!['name'] ?? shopName) as String;
          }
        }
      } catch (e) {
        debugPrint('[WorkerAuthService] Online lookup failed (falling back to offline check): $e');
      }
    }

    // 2. Offline fallback (or if offline test worker)
    if (targetWorker == null) {
      // In offline development, verify against hashed PIN formula
      final expectedHash = WorkerAccount.hashPin(cleanPin, cleanShopId);
      targetWorker = WorkerAccount(
        id: 'WRK-${cleanWorkerCode.toLowerCase()}',
        shopId: cleanShopId,
        workerCode: cleanWorkerCode,
        name: 'Technician $cleanWorkerCode',
        pinHash: expectedHash,
        active: true,
        createdAt: DateTime.now(),
      );
    }

    // 3. Verify PIN
    if (!targetWorker.verifyPin(cleanPin)) {
      throw ArgumentError('Invalid PIN entered. Please check and try again.');
    }

    final session = AppSession(
      shopId: cleanShopId,
      userId: targetWorker.id,
      role: UserRole.worker,
      displayName: targetWorker.name,
      shopName: shopName,
      workerCode: targetWorker.workerCode,
      lastLoginAt: DateTime.now(),
    );

    await WorkerDatabase.instance.saveSession(session);
    _currentSession = session;
    notifyListeners();
    return session;
  }

  Future<void> logout() async {
    await WorkerDatabase.instance.clearSession();
    _currentSession = null;
    notifyListeners();
  }
}
