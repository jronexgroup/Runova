import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:runova_core/runova_core.dart';
import '../local/app_database.dart';
import '../remote/firebase_manager.dart';

/// Central Authentication & Role-Based Access Control Service.
/// Supports Shop Owners (Firebase Auth) & Technicians (Fast Counter PIN).
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._();
  AuthService._();

  AppSession? _currentSession;
  AppSession? get currentSession => _currentSession;
  ShopInfo? _currentShop;
  ShopInfo? get currentShop => _currentShop;

  bool get isAuthenticated => _currentSession != null;
  bool get isAdmin => _currentSession?.isAdmin ?? false;
  bool get isWorker => _currentSession?.isWorker ?? false;
  String get activeShopId => _currentSession?.shopId ?? _currentShop?.id ?? '';
  String get activeUserName => _currentSession?.displayName ?? '';
  String get activeShopName {
    if (_currentShop != null &&
        _currentShop!.name.isNotEmpty &&
        _currentShop!.name != 'Runova Shop' &&
        _currentShop!.name != 'Runova') {
      return _currentShop!.name;
    }
    if (_currentSession?.shopName != null &&
        _currentSession!.shopName.isNotEmpty &&
        _currentSession!.shopName != 'Runova Shop' &&
        _currentSession!.shopName != 'Runova') {
      return _currentSession!.shopName;
    }
    return _currentShop?.name ?? '';
  }

  void refreshShop(ShopInfo shop) {
    _currentShop = shop;
    if (_currentSession != null) {
      _currentSession = AppSession(
        shopId: shop.id,
        userId: _currentSession!.userId,
        role: _currentSession!.role,
        displayName: _currentSession!.displayName,
        shopName: shop.name,
        workerCode: _currentSession!.workerCode,
        lastLoginAt: _currentSession!.lastLoginAt,
      );
      AppDatabase.instance.saveSession(_currentSession!);
    }
    notifyListeners();
  }

  @visibleForTesting
  void setSessionForTesting(AppSession? session) {
    _currentSession = session;
    notifyListeners();
  }

  /// Restores cached session and shop profile from SQLite on app startup.
  Future<void> init() async {
    final cached = await AppDatabase.instance.getSession();
    if (cached != null) {
      _currentSession = cached;
      if (cached.shopId.isNotEmpty) {
        _currentShop = await AppDatabase.instance.getShop(cached.shopId);
      }
      _currentShop ??= await AppDatabase.instance.getPrimaryShop();

      if (_currentShop != null && _currentShop!.name.isNotEmpty) {
        if (_currentSession!.shopName.isEmpty ||
            _currentSession!.shopName == 'Runova Shop' ||
            _currentSession!.shopName == 'Runova') {
          _currentSession = AppSession(
            shopId: _currentShop!.id,
            userId: _currentSession!.userId,
            role: _currentSession!.role,
            displayName: _currentSession!.displayName,
            shopName: _currentShop!.name,
            workerCode: _currentSession!.workerCode,
            lastLoginAt: _currentSession!.lastLoginAt,
          );
          await AppDatabase.instance.saveSession(_currentSession!);
        }
      }
      notifyListeners();
    } else {
      _currentShop = await AppDatabase.instance.getPrimaryShop();
      notifyListeners();
    }
  }

  /// Registers a new Shop and its Owner (Admin).
  Future<AppSession> registerShopAndAdmin({
    required String email,
    required String password,
    required String shopName,
    required String ownerName,
    required String phone,
    required String address,
    String nameBengali = '',
  }) async {
    String uid = 'ADMIN-${DateTime.now().millisecondsSinceEpoch % 100000}';
    final shopId = 'SHOP-${DateTime.now().millisecondsSinceEpoch % 1000000}';
    final now = DateTime.now();

    // 1. Firebase Auth Registration (if online & configured in Firebase Console)
    final firestore = FirebaseManager.instance.firestore;
    try {
      if (FirebaseManager.instance.isInitialized) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        if (cred.user != null) {
          uid = cred.user!.uid;
          await cred.user!.updateDisplayName(ownerName.trim());
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Firebase Auth registration bypassed (running local first): $e');
      // If Firebase Auth provider is not enabled in console or network fails, proceed with local-first admin UID
      uid = 'LOCAL-ADMIN-${DateTime.now().millisecondsSinceEpoch % 100000}';
    }

    final shop = ShopInfo(
      id: shopId,
      name: shopName.trim(),
      nameBengali: nameBengali.trim(),
      address: address.trim(),
      phone: phone.trim(),
      ownerUid: uid,
      createdAt: now,
    );

    final userProfile = UserProfile(
      uid: uid,
      shopId: shopId,
      role: UserRole.admin,
      displayName: ownerName.trim(),
      email: email.trim(),
      active: true,
      createdAt: now,
    );

    // 2. Persist locally to SQLite
    _currentShop = shop;
    await AppDatabase.instance.saveShop(shop);

    // 3. Persist to Firestore if available
    if (firestore != null) {
      try {
        await firestore.collection('shops').doc(shopId).set(shop.toMap());
        await firestore.collection('users').doc(uid).set(userProfile.toMap());
      } catch (e) {
        debugPrint('[AuthService] Firestore sync error during registration: $e');
      }
    }

    // 4. Save active session
    final session = AppSession(
      shopId: shopId,
      userId: uid,
      role: UserRole.admin,
      displayName: ownerName.trim(),
      shopName: shopName.trim(),
      lastLoginAt: now,
    );

    await AppDatabase.instance.saveSession(session);
    _currentSession = session;
    notifyListeners();
    return session;
  }

  /// Authenticates Shop Owner via Email & Password.
  Future<AppSession> loginAdmin({
    required String email,
    required String password,
  }) async {
    final firestore = FirebaseManager.instance.firestore;
    String uid = '';
    String ownerName = 'Shop Owner';
    String shopId = '';
    String shopName = 'Runova Shop';

    if (FirebaseManager.instance.isInitialized) {
      try {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        if (cred.user != null) {
          uid = cred.user!.uid;
          ownerName = cred.user!.displayName ?? 'Shop Owner';
        }
      } catch (e) {
        debugPrint('[AuthService] Firebase Auth signIn error: $e');
        final cached = await AppDatabase.instance.getSession();
        if (cached != null && cached.isAdmin) {
          _currentSession = cached;
          notifyListeners();
          return cached;
        }
        rethrow;
      }
    } else {
      // Local development or offline fallback
      final cached = await AppDatabase.instance.getSession();
      if (cached != null && cached.isAdmin) {
        _currentSession = cached;
        notifyListeners();
        return cached;
      }
      throw StateError('Firebase is not yet initialized. Please connect to internet to sign in.');
    }

    // Fetch user profile from Firestore
    if (firestore != null && uid.isNotEmpty) {
      try {
        final userDoc = await firestore.collection('users').doc(uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          shopId = (data['shop_id'] ?? '') as String;
          ownerName = (data['display_name'] ?? ownerName) as String;

          if (shopId.isNotEmpty) {
            final shopDoc = await firestore.collection('shops').doc(shopId).get();
            if (shopDoc.exists && shopDoc.data() != null) {
              final shop = ShopInfo.fromMap(shopDoc.data()!);
              shopName = shop.name;
              await AppDatabase.instance.saveShop(shop);
            }
          }
        }
      } catch (e) {
        debugPrint('[AuthService] Error fetching user profile from Firestore: $e');
      }
    }

    // SQLite fallback: retrieve local registered shop if Firestore did not supply name
    if (shopName.isEmpty || shopName == 'Runova Shop') {
      final localShop = (shopId.isNotEmpty ? await AppDatabase.instance.getShop(shopId) : null) ??
                        await AppDatabase.instance.getPrimaryShop();
      if (localShop != null && localShop.name.isNotEmpty) {
        shopName = localShop.name;
        if (shopId.isEmpty) shopId = localShop.id;
        _currentShop = localShop;
      }
    }

    if (shopId.isEmpty) {
      shopId = 'SHOP-${uid.substring(0, 6)}';
    }

    final session = AppSession(
      shopId: shopId,
      userId: uid,
      role: UserRole.admin,
      displayName: ownerName,
      shopName: shopName,
      lastLoginAt: DateTime.now(),
    );

    await AppDatabase.instance.saveSession(session);
    _currentSession = session;
    notifyListeners();
    return session;
  }

  /// Authenticates Worker via Fast Counter PIN (Option 1).
  Future<AppSession> loginWorker({
    required String shopId,
    required String workerCode,
    required String pin,
  }) async {
    final cleanShopId = shopId.trim();
    final cleanWorkerCode = workerCode.trim().toUpperCase();

    // 1. Search in local SQLite workers table
    final workers = await AppDatabase.instance.getWorkers(shopId: cleanShopId);
    WorkerAccount? targetWorker;

    for (final w in workers) {
      if (w.workerCode.toUpperCase() == cleanWorkerCode && w.active) {
        targetWorker = w;
        break;
      }
    }

    // 2. Fallback to Firestore if not cached locally
    if (targetWorker == null && FirebaseManager.instance.firestore != null) {
      try {
        final snap = await FirebaseManager.instance.firestore!
            .collection('shops')
            .doc(cleanShopId)
            .collection('workers')
            .where('worker_code', isEqualTo: cleanWorkerCode)
            .where('active', isEqualTo: true)
            .limit(1)
            .get();

        if (snap.docs.isNotEmpty) {
          targetWorker = WorkerAccount.fromMap(snap.docs.first.data());
          await AppDatabase.instance.upsertWorker(targetWorker);
        }
      } catch (e) {
        debugPrint('[AuthService] Firestore worker lookup error: $e');
      }
    }

    if (targetWorker == null) {
      throw ArgumentError('Worker ($cleanWorkerCode) not found for this Shop.');
    }

    // 3. Verify PIN
    if (!targetWorker.verifyPin(pin)) {
      throw ArgumentError('Invalid PIN entered. Please check and try again.');
    }

    // 4. Retrieve Shop Name
    final shop = await AppDatabase.instance.getShop(cleanShopId);
    final shopName = shop?.name ?? 'Runova Shop';

    final session = AppSession(
      shopId: cleanShopId,
      userId: targetWorker.id,
      role: UserRole.worker,
      displayName: targetWorker.name,
      shopName: shopName,
      workerCode: targetWorker.workerCode,
      lastLoginAt: DateTime.now(),
    );

    await AppDatabase.instance.saveSession(session);
    _currentSession = session;
    notifyListeners();
    return session;
  }

  /// Admin provisions a new Worker with a 4-digit PIN.
  Future<WorkerAccount> createWorker({
    required String name,
    required String workerCode,
    required String pin,
  }) async {
    if (!isAdmin) {
      throw StateError('Only Shop Admin can create workers.');
    }

    final shopId = activeShopId;
    final pinHash = WorkerAccount.hashPin(pin.trim(), shopId);
    final workerId = 'WRK-${DateTime.now().millisecondsSinceEpoch % 100000}';

    final worker = WorkerAccount(
      id: workerId,
      shopId: shopId,
      workerCode: workerCode.trim().toUpperCase(),
      name: name.trim(),
      pinHash: pinHash,
      active: true,
      createdAt: DateTime.now(),
    );

    // Save locally
    await AppDatabase.instance.upsertWorker(worker);

    // Sync to Firestore if available
    final firestore = FirebaseManager.instance.firestore;
    if (firestore != null) {
      try {
        await firestore
            .collection('shops')
            .doc(shopId)
            .collection('workers')
            .doc(worker.id)
            .set(worker.toMap());
      } catch (e) {
        debugPrint('[AuthService] Failed syncing worker to Firestore: $e');
      }
    }

    notifyListeners();
    return worker;
  }

  /// Admin toggles worker active state.
  Future<void> toggleWorkerStatus(WorkerAccount worker, bool active) async {
    if (!isAdmin) {
      throw StateError('Only Shop Admin can modify worker status.');
    }

    final updated = worker.copyWith(active: active);
    await AppDatabase.instance.upsertWorker(updated);

    final firestore = FirebaseManager.instance.firestore;
    if (firestore != null) {
      try {
        await firestore
            .collection('shops')
            .doc(activeShopId)
            .collection('workers')
            .doc(worker.id)
            .update({'active': active ? 1 : 0});
      } catch (e) {
        debugPrint('[AuthService] Error updating worker status in Firestore: $e');
      }
    }

    notifyListeners();
  }

  /// Logs out of active session.
  Future<void> signOut() async {
    await AppDatabase.instance.clearSession();
    try {
      if (FirebaseManager.instance.isInitialized) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {}

    _currentSession = null;
    notifyListeners();
  }
}
