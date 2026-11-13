import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:runova_admin/data/local/app_database.dart';
import 'package:runova_admin/state/shop_state.dart';
import 'package:runova_core/runova_core.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Supplier & Retail Integration Tests', () {
    late ShopState state;
    late Database testDb;

    setUp(() async {
      testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await AppDatabase.instance.createSchema(testDb);
      AppDatabase.setDatabaseForTesting(testDb);

      state = ShopState.instance;
      await state.init(force: true);
    });

    tearDown(() async {
      await testDb.close();
      AppDatabase.setDatabaseForTesting(null);
    });

    test('Add and retrieve suppliers in SQLite', () async {
      expect(state.suppliers, isEmpty);

      final sup = await state.addSupplier(
        name: 'Royal Accessories Kolkata',
        phone: '9830012345',
        category: 'Mobile Accessories',
        address: 'Chandni Chowk, Kolkata',
      );

      expect(state.suppliers.length, 1);
      expect(state.suppliers.first.name, 'Royal Accessories Kolkata');
      expect(state.suppliers.first.phone, '9830012345');

      // Verify persistence directly in SQLite
      final fromDb = await AppDatabase.instance.getSuppliers();
      expect(fromDb.length, 1);
      expect(fromDb.first.name, 'Royal Accessories Kolkata');

      // Add product linked with this supplier
      await state.addProduct(
        name: 'Type-C Fast Cable',
        category: 'Cables',
        supplier: sup.name,
        buyPrice: Money.fromRupees(40),
        defaultSellPrice: Money.fromRupees(120),
        initialStock: 25,
      );

      expect(state.products.length, 1);
      expect(state.products.first.supplier, 'Royal Accessories Kolkata');

      // Delete supplier
      await state.deleteSupplier(sup.id);
      expect(state.suppliers, isEmpty);
      final fromDbAfter = await AppDatabase.instance.getSuppliers();
      expect(fromDbAfter, isEmpty);
    });
  });
}
