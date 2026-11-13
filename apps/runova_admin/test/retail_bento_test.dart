import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:runova_admin/screens/retail/retail_screen.dart';
import 'package:runova_admin/state/shop_state.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Tapping Add Product opens Bento Grid modal with plan categories', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RetailScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify "Add Product" button is present
    final addBtn = find.text('Add Product');
    expect(addBtn, findsOneWidget);

    // Tap "Add Product"
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    // Verify Bento Grid Dialog appeared with options according to PRD plan
    expect(find.text('Add Inventory Item'), findsOneWidget);
    expect(find.descendant(of: find.byType(Dialog), matching: find.text('Mobile Accessories & Audio')), findsOneWidget);
    expect(find.descendant(of: find.byType(Dialog), matching: find.text('Cover Matrix')), findsOneWidget);
    expect(find.descendant(of: find.byType(Dialog), matching: find.text('Tempered Glass')), findsOneWidget);
    expect(find.descendant(of: find.byType(Dialog), matching: find.text('Repair Parts')), findsOneWidget);
    expect(find.descendant(of: find.byType(Dialog), matching: find.text('Small Items')), findsOneWidget);

    // Tap Cover Matrix card to open dedicated Cover Matrix dialog
    await tester.tap(find.text('Cover Matrix'));
    await tester.pumpAndSettle();

    // Verify dedicated Cover Matrix form is displayed
    expect(find.text('Add Cover Matrix'), findsOneWidget);
    expect(find.text('Base Model Family Name *'), findsOneWidget);
    expect(find.text('Linked Models (Comma Separated) *'), findsOneWidget);
  });
}
