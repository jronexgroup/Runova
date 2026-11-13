import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runova_admin/widgets/app_header.dart';
import 'package:runova_admin/data/auth/auth_service.dart';
import 'package:runova_core/runova_core.dart';

void main() {
  tearDown(() {
    AuthService.instance.setSessionForTesting(null);
  });

  testWidgets('AppHeader displays adjusted shop name and omits Kolkata Hub', (tester) async {
    // 1. Initial empty shop name falls back to 'Runova'
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: AppHeader(),
        ),
      ),
    );

    expect(find.text('Runova'), findsOneWidget);
    expect(find.text('Kolkata Hub • কলকাতা হাব'), findsNothing);
    expect(find.textContaining('Kolkata'), findsNothing);
    expect(find.textContaining('কলকাতা'), findsNothing);

    // 2. Multi-word shop name is truncated to the first 2 words
    final multiWordSession = AppSession(
      shopId: 'shop_1',
      userId: 'admin_1',
      role: UserRole.admin,
      displayName: 'Owner',
      shopName: 'Maa Tara Mobile Care & Electronics',
      lastLoginAt: DateTime.now(),
    );
    AuthService.instance.setSessionForTesting(multiWordSession);
    await tester.pump();

    // "Maa Tara Mobile Care & Electronics" has > 2 words -> "Maa Tara"
    expect(find.text('Maa Tara'), findsOneWidget);
    expect(find.text('M'), findsOneWidget); // Profile avatar initial

    // 3. Two-word shop name is kept intact
    final twoWordSession = AppSession(
      shopId: 'shop_1',
      userId: 'admin_1',
      role: UserRole.admin,
      displayName: 'Owner',
      shopName: 'Quick Fix',
      lastLoginAt: DateTime.now(),
    );
    AuthService.instance.setSessionForTesting(twoWordSession);
    await tester.pump();

    expect(find.text('Quick Fix'), findsOneWidget);
    expect(find.text('Q'), findsOneWidget);
  });
}
