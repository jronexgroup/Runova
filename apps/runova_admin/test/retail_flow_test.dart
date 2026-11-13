import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:runova_core/runova_core.dart';
import 'package:runova_admin/screens/retail/retail_screen.dart';
import 'package:runova_admin/screens/retail/add_inventory_screen.dart';
import 'package:runova_admin/data/local/app_database.dart';
import 'package:runova_admin/state/shop_state.dart';
import 'package:runova_admin/data/sync/sync_service.dart';

void main() {
  late Database testDb;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SyncService.instance.stopPeriodicSync();
    testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await AppDatabase.instance.createSchema(testDb);
    AppDatabase.setDatabaseForTesting(testDb);

    await ShopState.instance.init(force: true);
    SyncService.instance.stopPeriodicSync();
  });

  tearDown(() async {
    SyncService.instance.stopPeriodicSync();
    await testDb.close();
    AppDatabase.setDatabaseForTesting(null);
  });

  testWidgets('AddInventoryScreen allows decreasing pieces and shows margin preview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: AddInventoryScreen(categoryType: InventoryCategoryType.accessory),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial quantity is 10
    expect(find.byWidgetPredicate((w) => w is EditableText && w.controller.text == '10'), findsOneWidget);

    // 2. Tap minus button to decrease pieces
    final minusBtn = find.byIcon(Icons.remove);
    await tester.tap(minusBtn);
    await tester.pump();
    expect(find.byWidgetPredicate((w) => w is EditableText && w.controller.text == '9'), findsOneWidget);

    // 3. Tap +25 chip to increase pieces
    await tester.tap(find.text('+25'));
    await tester.pump();
    expect(find.byWidgetPredicate((w) => w is EditableText && w.controller.text == '34'), findsOneWidget);

    // 4. Tap -5 chip to decrease pieces
    await tester.tap(find.text('-5'));
    await tester.pump();
    expect(find.byWidgetPredicate((w) => w is EditableText && w.controller.text == '29'), findsOneWidget);

    // 5. Enter product details
    final nameField = find.byType(TextFormField).at(0);
    final buyField = find.byType(TextFormField).at(1);
    final sellField = find.byType(TextFormField).at(2);

    await tester.enterText(nameField, 'Boat Type-C Cable');
    await tester.enterText(buyField, '50');
    await tester.enterText(sellField, '150');
    await tester.pumpAndSettle();

    // Margin preview should be visible
    expect(find.textContaining('Estimated Profit'), findsOneWidget);
  });

  testWidgets('RetailScreen decrements stock immediately upon sale and adjusts stock from list', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Add sample product to state
    await ShopState.instance.addProduct(
      name: 'Samsung 25W Adapter',
      category: 'Cables & Chargers',
      supplier: 'Galaxy Wholesale',
      buyPrice: Money.fromRupees(300),
      defaultSellPrice: Money.fromRupees(600),
      initialStock: 5,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RetailScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify stock is displayed as 5
    expect(find.text('Stock: 5 Available'), findsOneWidget);

    // Confirm sale of 1 piece
    await tester.tap(find.text('Confirm Sale'));
    await tester.pump();

    // Stock must immediately decrease to 4 on screen!
    expect(find.text('Stock: 4 Available'), findsOneWidget);

    // Tap tune icon on the product card to adjust stock
    final tuneBtn = find.byIcon(Icons.tune).first;
    await tester.ensureVisible(tuneBtn);
    await tester.tap(tuneBtn);
    await tester.pumpAndSettle();

    expect(find.text('Adjust Stock Quantity (Pieces)'), findsOneWidget);

    // Decrease stock by 1
    await tester.tap(find.byIcon(Icons.remove).last);
    await tester.pump();

    await tester.tap(find.text('Update Stock'));
    await tester.pumpAndSettle();

    // Stock must now be 3
    expect(find.text('Stock: 3 Available'), findsOneWidget);
  });
}
