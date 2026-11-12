import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:runova_admin/data/local/app_database.dart';
import 'package:runova_admin/data/auth/auth_service.dart';
import 'package:runova_core/runova_core.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('AuthService & Role Management Tests', () {
    late Database testDb;
    late AuthService auth;

    setUp(() async {
      testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await AppDatabase.instance.createSchema(testDb);
      AppDatabase.setDatabaseForTesting(testDb);

      auth = AuthService.instance;
      await auth.init();
    });

    tearDown(() async {
      await auth.signOut();
      await testDb.close();
      AppDatabase.setDatabaseForTesting(null);
    });

    test('Registering Shop & Admin creates active session and shop profile', () async {
      final session = await auth.registerShopAndAdmin(
        email: 'owner@runovashop.com',
        password: 'password123',
        shopName: 'Runova Telecom',
        ownerName: 'Rubai Admin',
        phone: '+91 98765 43210',
        address: 'Contai Super Market',
        nameBengali: 'রুনোভা টেলিকম',
      );

      expect(auth.isAuthenticated, isTrue);
      expect(auth.isAdmin, isTrue);
      expect(auth.isWorker, isFalse);
      expect(auth.activeShopName, equals('Runova Telecom'));
      expect(auth.activeUserName, equals('Rubai Admin'));
      expect(session.shopId, startsWith('SHOP-'));

      // Verify persistent in SQLite
      final cachedSession = await AppDatabase.instance.getSession();
      expect(cachedSession, isNotNull);
      expect(cachedSession!.displayName, equals('Rubai Admin'));
      expect(cachedSession.role, equals(UserRole.admin));
    });

    test('Admin creates worker and worker authenticates via Fast Counter PIN', () async {
      // 1. Establish Admin session
      await auth.registerShopAndAdmin(
        email: 'owner@runovashop.com',
        password: 'password123',
        shopName: 'Runova Telecom',
        ownerName: 'Rubai Admin',
        phone: '+91 98765 43210',
        address: 'Contai Super Market',
      );

      final shopId = auth.activeShopId;

      // 2. Admin provisions worker with PIN 2026
      final worker = await auth.createWorker(
        name: 'Subhash Ghosh',
        workerCode: 'WORKER-1',
        pin: '2026',
      );

      expect(worker.workerCode, equals('WORKER-1'));
      expect(worker.active, isTrue);

      // Verify worker in SQLite
      final workers = await AppDatabase.instance.getWorkers(shopId: shopId);
      expect(workers.length, equals(1));
      expect(workers.first.name, equals('Subhash Ghosh'));

      // 3. Admin signs out
      await auth.signOut();
      expect(auth.isAuthenticated, isFalse);

      // 4. Worker logs in with incorrect PIN -> Fails
      expect(
        () async => await auth.loginWorker(
          shopId: shopId,
          workerCode: 'WORKER-1',
          pin: '9999',
        ),
        throwsA(isA<ArgumentError>()),
      );

      // 5. Worker logs in with correct PIN -> Succeeds
      final workerSession = await auth.loginWorker(
        shopId: shopId,
        workerCode: 'WORKER-1',
        pin: '2026',
      );

      expect(auth.isAuthenticated, isTrue);
      expect(auth.isWorker, isTrue);
      expect(auth.isAdmin, isFalse);
      expect(workerSession.displayName, equals('Subhash Ghosh'));
      expect(workerSession.workerCode, equals('WORKER-1'));
    });

    test('Sign out clears active session from SQLite', () async {
      await auth.registerShopAndAdmin(
        email: 'owner@runovashop.com',
        password: 'password123',
        shopName: 'Runova Telecom',
        ownerName: 'Rubai Admin',
        phone: '+91 98765 43210',
        address: 'Contai Super Market',
      );

      expect(auth.isAuthenticated, isTrue);

      await auth.signOut();

      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentSession, isNull);
      final cached = await AppDatabase.instance.getSession();
      expect(cached, isNull);
    });
  });
}
