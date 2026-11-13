import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:runova_worker/data/auth/worker_auth_service.dart';
import 'package:runova_worker/data/local/worker_database.dart';
import 'package:runova_worker/state/worker_state.dart';
import 'package:runova_core/runova_core.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Runova Worker End-to-End Tests', () {
    late Database testDb;
    late WorkerAuthService auth;
    late WorkerState workerState;

    setUp(() async {
      testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await WorkerDatabase.instance.createSchema(testDb);
      WorkerDatabase.setDatabaseForTesting(testDb);

      auth = WorkerAuthService.instance;
      workerState = WorkerState.instance;

      // Authenticate test worker
      await auth.loginWithPin(
        shopId: 'SHOP-TEST-101',
        workerCode: 'WORKER-1',
        pin: '2026',
      );

      await workerState.init(force: true);
    });

    tearDown(() async {
      await auth.logout();
      await testDb.close();
      WorkerDatabase.setDatabaseForTesting(null);
    });

    test('Worker authenticates with Fast PIN and establishes session', () {
      expect(auth.isAuthenticated, isTrue);
      expect(auth.activeWorkerCode, equals('WORKER-1'));
      expect(auth.activeShopId, equals('SHOP-TEST-101'));
      expect(auth.currentSession?.role, equals(UserRole.worker));
    });

    test('Technician registers new repair intake and self-assigns', () async {
      final ticket = await workerState.registerRepairTicket(
        deviceName: 'Redmi Note 10 Pro',
        reportedProblem: 'Touch digitizer broken',
        inspectedProblem: 'Screen replacement required',
        description: 'Requires display panel swap',
        customerName: 'Rahul Sen',
        customerPhone: '+91 98301 23456',
        selfAssign: true,
      );

      expect(ticket.status, equals(RepairStatus.inspected));
      expect(ticket.assignedWorkerId, equals('WORKER-1'));

      // Verify segregation: appears in myQueue, not in unassignedPool
      expect(workerState.myQueue.length, equals(1));
      expect(workerState.unassignedPool.length, equals(0));
      expect(workerState.myQueue.first.id, equals(ticket.id));
    });

    test('Technician advances status from Inspected -> Part Bought -> Done', () async {
      final ticket = await workerState.registerRepairTicket(
        deviceName: 'Samsung Galaxy M31',
        reportedProblem: 'Battery draining fast',
        inspectedProblem: 'Swollen battery pack',
        description: 'Replace battery',
        selfAssign: true,
      );

      expect(ticket.status, equals(RepairStatus.inspected));

      // Advance to Part Bought
      await workerState.advanceStatus(ticket.id, RepairStatus.partBought);
      expect(workerState.myQueue.first.status, equals(RepairStatus.partBought));

      // Advance to Done
      await workerState.advanceStatus(ticket.id, RepairStatus.done);
      expect(workerState.myQueue.first.status, equals(RepairStatus.done));
    });

    test('Hard RBAC Guard: Worker is strictly blocked from marking Delivered', () async {
      final ticket = await workerState.registerRepairTicket(
        deviceName: 'iPhone 11',
        reportedProblem: 'Speaker not working',
        inspectedProblem: 'Clogged earpiece mesh',
        description: 'Cleaned and tested',
        selfAssign: true,
      );

      // Advance to Done
      await workerState.advanceStatus(ticket.id, RepairStatus.partBought);
      await workerState.advanceStatus(ticket.id, RepairStatus.done);

      // Attempting to advance to Delivered MUST throw StateError
      expect(
        () async => await workerState.advanceStatus(ticket.id, RepairStatus.delivered),
        throwsA(isA<StateError>()),
      );
    });

    test('Unassigned ticket pool and worker self-claim workflow', () async {
      // Register ticket without self-assigning (placed in shop pool)
      final unassignedTicket = await workerState.registerRepairTicket(
        deviceName: 'OnePlus Nord CE 2',
        reportedProblem: 'No display after drop',
        inspectedProblem: 'Loose flex cable',
        description: 'Reconnect and reseat display cable',
        selfAssign: false,
      );

      expect(unassignedTicket.assignedWorkerId, isNull);
      expect(workerState.unassignedPool.length, equals(1));
      expect(workerState.myQueue.length, equals(0));

      // Worker claims the ticket from the pool
      await workerState.claimTicket(unassignedTicket.id);

      expect(workerState.unassignedPool.length, equals(0));
      expect(workerState.myQueue.length, equals(1));
      expect(workerState.myQueue.first.assignedWorkerId, equals('WORKER-1'));
    });

    test('Technician logout clears cached session', () async {
      expect(auth.isAuthenticated, isTrue);

      await auth.logout();

      expect(auth.isAuthenticated, isFalse);
      final cached = await WorkerDatabase.instance.getSession();
      expect(cached, isNull);
    });
  });
}
