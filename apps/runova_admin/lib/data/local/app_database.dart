import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:runova_core/runova_core.dart';

/// Authoritative Local SQLite Database for Runova Shop.
/// Provides instant offline-first persistence for counter operations.
class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();

  static Database? _db;

  /// Allows setting or mocking the database instance (e.g. for in-memory unit tests).
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
    final path = join(dbPath, 'runova_shop.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => createSchema(db),
    );
  }

  Future<void> createSchema(Database db) async {
    // 1. Products
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        supplier TEXT NOT NULL,
        buy_price_paise INTEGER NOT NULL,
        default_sell_price_paise INTEGER NOT NULL,
        stock_quantity INTEGER NOT NULL,
        barcode TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 2. Cover Groups (Pooled Shared Stock by Base Name)
    await db.execute('''
      CREATE TABLE cover_groups (
        id TEXT PRIMARY KEY,
        base_name TEXT NOT NULL,
        linked_models_json TEXT NOT NULL,
        wholesaler TEXT NOT NULL,
        buy_price_paise INTEGER NOT NULL,
        default_sell_price_paise INTEGER NOT NULL,
        stock_quantity INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 3. Repair Tickets
    await db.execute('''
      CREATE TABLE repair_tickets (
        id TEXT PRIMARY KEY,
        device_name TEXT NOT NULL,
        reported_problem TEXT NOT NULL,
        inspected_problem TEXT NOT NULL,
        description TEXT NOT NULL,
        audio_url TEXT,
        status TEXT NOT NULL,
        assigned_worker_id TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        customer_payment_paise INTEGER,
        delivered_by TEXT,
        delivered_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 4. Repair Parts
    await db.execute('''
      CREATE TABLE repair_parts (
        id TEXT PRIMARY KEY,
        repair_id TEXT NOT NULL,
        description TEXT NOT NULL,
        cost_paise INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (repair_id) REFERENCES repair_tickets (id) ON DELETE CASCADE
      )
    ''');

    // 5. Print & Xerox POS Transactions
    await db.execute('''
      CREATE TABLE print_transactions (
        id TEXT PRIMARY KEY,
        receipt_number TEXT NOT NULL,
        service_description TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        total_amount_paise INTEGER NOT NULL,
        tender_type TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // 6. Retail Sale Transactions
    await db.execute('''
      CREATE TABLE sale_transactions (
        id TEXT PRIMARY KEY,
        invoice_number TEXT,
        total_amount_paise INTEGER NOT NULL,
        tender_type TEXT NOT NULL,
        cash_amount_paise INTEGER NOT NULL,
        upi_amount_paise INTEGER NOT NULL,
        customer_name TEXT,
        customer_phone TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // 7. Retail Line Items
    await db.execute('''
      CREATE TABLE sale_items (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_cost_paise INTEGER NOT NULL,
        unit_sell_price_paise INTEGER NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sale_transactions (id) ON DELETE CASCADE
      )
    ''');

    // 8. General Expenses
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        amount_paise INTEGER NOT NULL,
        date INTEGER NOT NULL,
        description TEXT,
        reference_id TEXT
      )
    ''');

    // 9. Formal Invoices
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL,
        type TEXT NOT NULL,
        reference_id TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        customer_phone TEXT,
        device_name TEXT,
        work_description TEXT,
        total_amount_paise INTEGER NOT NULL,
        issued_at INTEGER NOT NULL
      )
    ''');

    // 10. High-Priority Sync Outbox Queue
    await db.execute('''
      CREATE TABLE sync_outbox (
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

    // 11. Active App Session (Offline Auth State)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_session (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        role TEXT NOT NULL,
        display_name TEXT NOT NULL,
        shop_name TEXT NOT NULL,
        worker_code TEXT,
        last_login_at INTEGER NOT NULL
      )
    ''');

    // 12. Provisioned Workers
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workers (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        worker_code TEXT NOT NULL,
        name TEXT NOT NULL,
        pin_hash TEXT NOT NULL,
        active INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // 13. Shop Profile Entity
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shops (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        name_bengali TEXT,
        address TEXT NOT NULL,
        phone TEXT NOT NULL,
        owner_uid TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // 14. Suppliers / Wholesalers Entity
    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        category TEXT,
        address TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  // --- Products CRUD ---
  Future<List<Product>> getProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'name ASC');
    return rows.map((r) => Product(
      id: r['id'] as String,
      name: r['name'] as String,
      category: r['category'] as String,
      supplier: r['supplier'] as String,
      buyPrice: Money.fromPaise(r['buy_price_paise'] as int),
      defaultSellPrice: Money.fromPaise(r['default_sell_price_paise'] as int),
      stockQuantity: r['stock_quantity'] as int,
      barcode: r['barcode'] as String?,
    )).toList();
  }

  Future<void> upsertProduct(Product product) async {
    final db = await database;
    final row = {
      'id': product.id,
      'name': product.name,
      'category': product.category,
      'supplier': product.supplier,
      'buy_price_paise': product.buyPrice.paise,
      'default_sell_price_paise': product.defaultSellPrice.paise,
      'stock_quantity': product.stockQuantity,
      'barcode': product.barcode,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    await db.insert('products', row, conflictAlgorithm: ConflictAlgorithm.replace);
    await _enqueueSync('products', product.id, 'upsert', row);
  }

  Future<void> decrementProductStock(String productId, int quantity) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE products 
      SET stock_quantity = stock_quantity - ?, updated_at = ?
      WHERE id = ? AND stock_quantity >= ?
    ''', [quantity, DateTime.now().millisecondsSinceEpoch, productId, quantity]);
  }

  // --- Cover Groups CRUD ---
  Future<List<CoverGroup>> getCoverGroups() async {
    final db = await database;
    final rows = await db.query('cover_groups', orderBy: 'base_name ASC');
    return rows.map((r) {
      final modelsList = (jsonDecode(r['linked_models_json'] as String) as List)
          .map((e) => e.toString())
          .toList();

      return CoverGroup(
        id: r['id'] as String,
        baseName: r['base_name'] as String,
        linkedModels: modelsList,
        wholesaler: r['wholesaler'] as String,
        buyPrice: Money.fromPaise(r['buy_price_paise'] as int),
        defaultSellPrice: Money.fromPaise(r['default_sell_price_paise'] as int),
        stockQuantity: r['stock_quantity'] as int,
      );
    }).toList();
  }

  Future<void> upsertCoverGroup(CoverGroup group) async {
    final db = await database;
    final row = {
      'id': group.id,
      'base_name': group.baseName,
      'linked_models_json': jsonEncode(group.linkedModels),
      'wholesaler': group.wholesaler,
      'buy_price_paise': group.buyPrice.paise,
      'default_sell_price_paise': group.defaultSellPrice.paise,
      'stock_quantity': group.stockQuantity,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    await db.insert('cover_groups', row, conflictAlgorithm: ConflictAlgorithm.replace);
    await _enqueueSync('cover_groups', group.id, 'upsert', row);
  }

  Future<void> decrementCoverStock(String coverGroupId) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE cover_groups 
      SET stock_quantity = stock_quantity - 1, updated_at = ?
      WHERE id = ? AND stock_quantity > 0
    ''', [DateTime.now().millisecondsSinceEpoch, coverGroupId]);
  }

  // --- Repair Tickets CRUD ---
  Future<List<RepairTicket>> getRepairTickets() async {
    final db = await database;
    final rows = await db.query('repair_tickets', orderBy: 'created_at DESC');

    final List<RepairTicket> tickets = [];
    for (final r in rows) {
      final id = r['id'] as String;
      final partRows = await db.query('repair_parts', where: 'repair_id = ?', whereArgs: [id]);
      final parts = partRows.map((pr) => RepairPart(
        id: pr['id'] as String,
        repairId: pr['repair_id'] as String,
        description: pr['description'] as String,
        cost: Money.fromPaise(pr['cost_paise'] as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(pr['created_at'] as int),
      )).toList();

      final statusStr = r['status'] as String;
      final status = RepairStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => RepairStatus.inspected,
      );

      final paymentPaise = r['customer_payment_paise'] as int?;

      tickets.add(RepairTicket(
        id: id,
        deviceName: r['device_name'] as String,
        reportedProblem: r['reported_problem'] as String,
        inspectedProblem: r['inspected_problem'] as String,
        description: r['description'] as String,
        audioUrl: r['audio_url'] as String?,
        status: status,
        assignedWorkerId: r['assigned_worker_id'] as String?,
        customerName: r['customer_name'] as String?,
        customerPhone: r['customer_phone'] as String?,
        parts: parts,
        customerPayment: paymentPaise != null ? Money.fromPaise(paymentPaise) : null,
        deliveredBy: r['delivered_by'] as String?,
        deliveredAt: r['delivered_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(r['delivered_at'] as int)
            : null,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
      ));
    }
    return tickets;
  }

  Future<void> upsertRepairTicket(RepairTicket ticket) async {
    final db = await database;
    final row = {
      'id': ticket.id,
      'device_name': ticket.deviceName,
      'reported_problem': ticket.reportedProblem,
      'inspected_problem': ticket.inspectedProblem,
      'description': ticket.description,
      'audio_url': ticket.audioUrl,
      'status': ticket.status.name,
      'assigned_worker_id': ticket.assignedWorkerId,
      'customer_name': ticket.customerName,
      'customer_phone': ticket.customerPhone,
      'customer_payment_paise': ticket.customerPayment?.paise,
      'delivered_by': ticket.deliveredBy,
      'delivered_at': ticket.deliveredAt?.millisecondsSinceEpoch,
      'created_at': ticket.createdAt.millisecondsSinceEpoch,
      'updated_at': ticket.updatedAt.millisecondsSinceEpoch,
    };
    await db.insert('repair_tickets', row, conflictAlgorithm: ConflictAlgorithm.replace);
    await _enqueueSync('repair_tickets', ticket.id, 'upsert', row);
  }

  Future<void> insertRepairPart(RepairPart part) async {
    final db = await database;
    final row = {
      'id': part.id,
      'repair_id': part.repairId,
      'description': part.description,
      'cost_paise': part.cost.paise,
      'created_at': part.createdAt.millisecondsSinceEpoch,
    };
    await db.insert('repair_parts', row, conflictAlgorithm: ConflictAlgorithm.replace);
    await _enqueueSync('repair_parts', part.id, 'insert', row);
  }

  // --- Print Transactions CRUD ---
  Future<List<PrintTransaction>> getPrintTransactions() async {
    final db = await database;
    final rows = await db.query('print_transactions', orderBy: 'created_at DESC');
    return rows.map((r) => PrintTransaction(
      id: r['id'] as String,
      receiptNumber: r['receipt_number'] as String,
      serviceDescription: r['service_description'] as String,
      quantity: r['quantity'] as int,
      totalAmount: Money.fromPaise(r['total_amount_paise'] as int),
      tenderType: TenderType.values.firstWhere(
        (t) => t.name == r['tender_type'],
        orElse: () => TenderType.cash,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
    )).toList();
  }

  Future<void> insertPrintTransaction(PrintTransaction txn) async {
    final db = await database;
    final row = {
      'id': txn.id,
      'receipt_number': txn.receiptNumber,
      'service_description': txn.serviceDescription,
      'quantity': txn.quantity,
      'total_amount_paise': txn.totalAmount.paise,
      'tender_type': txn.tenderType.name,
      'created_at': txn.createdAt.millisecondsSinceEpoch,
    };
    await db.insert('print_transactions', row);
    await _enqueueSync('print_transactions', txn.id, 'upsert', row);
  }

  // --- Expenses CRUD ---
  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final rows = await db.query('expenses', orderBy: 'date DESC');
    return rows.map((r) => Expense(
      id: r['id'] as String,
      title: r['title'] as String,
      category: r['category'] as String,
      amount: Money.fromPaise(r['amount_paise'] as int),
      date: DateTime.fromMillisecondsSinceEpoch(r['date'] as int),
      description: r['description'] as String?,
      referenceId: r['reference_id'] as String?,
    )).toList();
  }

  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    final row = {
      'id': expense.id,
      'title': expense.title,
      'category': expense.category,
      'amount_paise': expense.amount.paise,
      'date': expense.date.millisecondsSinceEpoch,
      'description': expense.description,
      'reference_id': expense.referenceId,
    };
    await db.insert('expenses', row);
    await _enqueueSync('expenses', expense.id, 'upsert', row);
  }

  // --- Invoices CRUD ---
  Future<void> insertInvoice(Invoice invoice) async {
    final db = await database;
    final row = {
      'id': invoice.id,
      'invoice_number': invoice.invoiceNumber,
      'type': invoice.type.name,
      'reference_id': invoice.referenceId,
      'customer_name': invoice.customerName,
      'customer_phone': invoice.customerPhone,
      'device_name': invoice.deviceName,
      'work_description': invoice.workDescription,
      'total_amount_paise': invoice.totalAmount.paise,
      'issued_at': invoice.issuedAt.millisecondsSinceEpoch,
    };
    await db.insert('invoices', row);
    await _enqueueSync('invoices', invoice.id, 'upsert', row);
  }

  // --- Auth Session & Multi-tenant Profile ---
  Future<void> saveSession(AppSession session) async {
    final db = await database;
    await db.insert(
      'app_session',
      {
        'id': 'current_session',
        'shop_id': session.shopId,
        'user_id': session.userId,
        'role': session.role.name,
        'display_name': session.displayName,
        'shop_name': session.shopName,
        'worker_code': session.workerCode,
        'last_login_at': session.lastLoginAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AppSession?> getSession() async {
    final db = await database;
    final rows = await db.query(
      'app_session',
      where: 'id = ?',
      whereArgs: ['current_session'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppSession.fromMap(rows.first);
  }

  Future<void> clearSession() async {
    final db = await database;
    await db.delete('app_session', where: 'id = ?', whereArgs: ['current_session']);
  }

  // --- Shop Profile ---
  Future<void> saveShop(ShopInfo shop) async {
    final db = await database;
    final row = {
      'id': shop.id,
      'name': shop.name,
      'name_bengali': shop.nameBengali,
      'address': shop.address,
      'phone': shop.phone,
      'owner_uid': shop.ownerUid,
      'created_at': shop.createdAt.millisecondsSinceEpoch,
    };
    await db.insert('shops', row, conflictAlgorithm: ConflictAlgorithm.replace);
    await _enqueueSync('shops', shop.id, 'upsert', row);
  }

  Future<ShopInfo?> getShop(String shopId) async {
    final db = await database;
    final rows = await db.query('shops', where: 'id = ?', whereArgs: [shopId], limit: 1);
    if (rows.isEmpty) return null;
    return ShopInfo.fromMap(rows.first);
  }

  /// Returns the most recently created or registered Shop from local SQLite.
  Future<ShopInfo?> getPrimaryShop() async {
    final db = await database;
    final rows = await db.query('shops', orderBy: 'created_at DESC', limit: 1);
    if (rows.isEmpty) return null;
    return ShopInfo.fromMap(rows.first);
  }

  // --- Workers CRUD ---
  Future<List<WorkerAccount>> getWorkers({String? shopId}) async {
    final db = await database;
    final rows = shopId != null
        ? await db.query('workers', where: 'shop_id = ?', whereArgs: [shopId], orderBy: 'name ASC')
        : await db.query('workers', orderBy: 'name ASC');

    return rows.map((r) => WorkerAccount.fromMap(r)).toList();
  }

  Future<void> upsertWorker(WorkerAccount worker) async {
    final db = await database;
    final row = worker.toMap();
    await db.insert('workers', row, conflictAlgorithm: ConflictAlgorithm.replace);
    await _enqueueSync('workers', worker.id, 'upsert', row);
  }

  // --- Suppliers CRUD ---
  Future<List<Supplier>> getSuppliers() async {
    final db = await database;
    final rows = await db.query('suppliers', orderBy: 'name ASC');
    return rows.map((r) => Supplier.fromMap(r)).toList();
  }

  Future<void> saveSupplier(Supplier supplier) async {
    final db = await database;
    final row = supplier.toMap();
    await db.insert('suppliers', row, conflictAlgorithm: ConflictAlgorithm.replace);
    await _enqueueSync('suppliers', supplier.id, 'upsert', row);
  }

  Future<void> deleteSupplier(String id) async {
    final db = await database;
    await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
    await _enqueueSync('suppliers', id, 'delete', {'id': id});
  }

  Future<void> deleteWorker(String workerId) async {
    final db = await database;
    await db.delete('workers', where: 'id = ?', whereArgs: [workerId]);
    await _enqueueSync('workers', workerId, 'delete', {'id': workerId});
  }

  static int _syncCounter = 0;

  // --- High Priority Sync Queue ---
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
