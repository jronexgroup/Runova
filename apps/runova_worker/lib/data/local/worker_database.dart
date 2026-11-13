import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:runova_core/runova_core.dart';

/// Local SQLite database for Runova Worker App.
/// Encapsulates worker session, offline repair tickets, and sync queue.
class WorkerDatabase {
  static final WorkerDatabase instance = WorkerDatabase._();
  WorkerDatabase._();

  static Database? _db;

  static void setDatabaseForTesting(Database? db) {
    _db = db;
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'runova_worker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => createSchema(db),
    );
  }

  Future<void> createSchema(Database db) async {
    // 1. Worker Session Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS worker_session (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        worker_id TEXT NOT NULL,
        worker_code TEXT NOT NULL,
        name TEXT NOT NULL,
        shop_name TEXT NOT NULL,
        last_login_at INTEGER NOT NULL
      )
    ''');

    // 2. Repair Tickets Table (Strictly NO parts cost or payment amounts stored)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS repair_tickets (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        device_name TEXT NOT NULL,
        reported_problem TEXT NOT NULL,
        inspected_problem TEXT NOT NULL,
        description TEXT NOT NULL,
        audio_url TEXT,
        status TEXT NOT NULL,
        assigned_worker_id TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 3. Sync Outbox Queue
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_outbox (
        id TEXT PRIMARY KEY,
        collection_name TEXT NOT NULL,
        document_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        attempts INTEGER DEFAULT 0,
        status TEXT NOT NULL
      )
    ''');
  }

  // --- Session Management ---
  Future<void> saveSession(AppSession session) async {
    final db = await database;
    await db.insert(
      'worker_session',
      {
        'id': 'current_worker',
        'shop_id': session.shopId,
        'worker_id': session.userId,
        'worker_code': session.workerCode ?? 'WORKER-1',
        'name': session.displayName,
        'shop_name': session.shopName,
        'last_login_at': session.lastLoginAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AppSession?> getSession() async {
    final db = await database;
    final rows = await db.query(
      'worker_session',
      where: 'id = ?',
      whereArgs: ['current_worker'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return AppSession(
      shopId: r['shop_id'] as String,
      userId: r['worker_id'] as String,
      role: UserRole.worker,
      displayName: r['name'] as String,
      shopName: r['shop_name'] as String,
      workerCode: r['worker_code'] as String?,
      lastLoginAt: DateTime.fromMillisecondsSinceEpoch(r['last_login_at'] as int),
    );
  }

  Future<void> clearSession() async {
    final db = await database;
    await db.delete('worker_session', where: 'id = ?', whereArgs: ['current_worker']);
  }

  // --- Repair Tickets CRUD ---
  Future<List<RepairTicket>> getTickets() async {
    final db = await database;
    final rows = await db.query('repair_tickets', orderBy: 'updated_at DESC');

    return rows.map((r) {
      final statusStr = r['status'] as String;
      final status = RepairStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => RepairStatus.inspected,
      );

      return RepairTicket(
        id: r['id'] as String,
        deviceName: r['device_name'] as String,
        reportedProblem: r['reported_problem'] as String,
        inspectedProblem: r['inspected_problem'] as String,
        description: r['description'] as String,
        audioUrl: r['audio_url'] as String?,
        status: status,
        assignedWorkerId: r['assigned_worker_id'] as String?,
        customerName: r['customer_name'] as String?,
        customerPhone: r['customer_phone'] as String?,
        parts: const [], // RBAC: Worker has zero visibility into parts cost
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
      );
    }).toList();
  }

  Future<void> upsertTicket(RepairTicket ticket, String shopId) async {
    final db = await database;
    final row = {
      'id': ticket.id,
      'shop_id': shopId,
      'device_name': ticket.deviceName,
      'reported_problem': ticket.reportedProblem,
      'inspected_problem': ticket.inspectedProblem,
      'description': ticket.description,
      'audio_url': ticket.audioUrl,
      'status': ticket.status.name,
      'assigned_worker_id': ticket.assignedWorkerId,
      'customer_name': ticket.customerName,
      'customer_phone': ticket.customerPhone,
      'created_at': ticket.createdAt.millisecondsSinceEpoch,
      'updated_at': ticket.updatedAt.millisecondsSinceEpoch,
    };

    await db.insert('repair_tickets', row, conflictAlgorithm: ConflictAlgorithm.replace);
    await _enqueueSync('repair_tickets', ticket.id, 'upsert', row);
  }

  static int _syncCounter = 0;

  // --- Outbox Queue ---
  Future<void> _enqueueSync(String collection, String docId, String operation, Map<String, dynamic> payload) async {
    final db = await database;
    await db.insert(
      'sync_outbox',
      {
        'id': '${collection}_${docId}_${DateTime.now().microsecondsSinceEpoch}_${_syncCounter++}',
        'collection_name': collection,
        'document_id': docId,
        'operation': operation,
        'payload_json': jsonEncode(payload),
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'attempts': 0,
        'status': 'pending',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSyncTasks() async {
    final db = await database;
    return await db.query(
      'sync_outbox',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
      limit: 50,
    );
  }

  Future<void> markSyncTaskDone(String taskId) async {
    final db = await database;
    await db.update(
      'sync_outbox',
      {'status': 'synced'},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }
}
