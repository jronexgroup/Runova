import 'package:test/test.dart';
import 'package:runova_core/runova_core.dart';

void main() {
  group('Auth & Shop Models Tests', () {
    test('WorkerAccount PIN hashing and verification works correctly', () {
      const shopId = 'SHOP-RUNOVA-101';
      final pinHash = WorkerAccount.hashPin('2026', shopId);

      final worker = WorkerAccount(
        id: 'WRK-1',
        shopId: shopId,
        workerCode: 'WORKER-1',
        name: 'Subhash Ghosh',
        pinHash: pinHash,
        createdAt: DateTime.now(),
      );

      expect(worker.verifyPin('2026'), isTrue);
      expect(worker.verifyPin('0000'), isFalse);
      expect(worker.verifyPin('1234'), isFalse);

      // Verify serialization roundtrip
      final map = worker.toMap();
      final restored = WorkerAccount.fromMap(map);
      expect(restored.id, equals(worker.id));
      expect(restored.name, equals('Subhash Ghosh'));
      expect(restored.verifyPin('2026'), isTrue);
    });

    test('ShopInfo and AppSession serialization roundtrip', () {
      final now = DateTime.now();
      final shop = ShopInfo(
        id: 'SHOP-99',
        name: 'Runova Telecom',
        nameBengali: 'রুনোভা টেলিকম',
        address: 'Main Market, Contai',
        phone: '+91 98765 43210',
        ownerUid: 'uid_admin_123',
        createdAt: now,
      );

      final shopMap = shop.toMap();
      final restoredShop = ShopInfo.fromMap(shopMap);
      expect(restoredShop.name, equals('Runova Telecom'));
      expect(restoredShop.nameBengali, equals('রুনোভা টেলিকম'));

      final session = AppSession(
        shopId: shop.id,
        userId: 'uid_admin_123',
        role: UserRole.admin,
        displayName: 'Rubai Admin',
        shopName: shop.name,
        lastLoginAt: now,
      );

      expect(session.isAdmin, isTrue);
      expect(session.isWorker, isFalse);

      final sessionMap = session.toMap();
      final restoredSession = AppSession.fromMap(sessionMap);
      expect(restoredSession.shopId, equals('SHOP-99'));
      expect(restoredSession.role, equals(UserRole.admin));
    });
  });
}
