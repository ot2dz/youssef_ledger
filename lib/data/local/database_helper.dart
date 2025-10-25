// lib/data/local/database_helper.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:youssef_fabric_ledger/core/enums.dart';
import 'package:youssef_fabric_ledger/data/local/db_bus.dart';
import 'package:youssef_fabric_ledger/data/models/category.dart';
import 'package:youssef_fabric_ledger/data/models/debt_entry.dart';
import 'package:youssef_fabric_ledger/data/models/drawer_snapshot.dart';
import 'package:youssef_fabric_ledger/data/models/expense.dart';
import 'package:youssef_fabric_ledger/data/models/income.dart';
import 'package:youssef_fabric_ledger/data/models/party.dart';
import 'package:youssef_fabric_ledger/models/cash_balance_log.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('youssef_ledger.db');
    return _database!;
  }

  /// Updates a party (vendor or person) in the database.
  Future<int> updateParty(Party party) async {
    final db = await instance.database;
    assert(party.id != null, 'Party id must not be null for update');
    final result = await db.update(
      'parties',
      party.toMap(),
      where: 'id = ?',
      whereArgs: [party.id],
    );

    // Notify listeners of database change
    DbBus.instance.bump();

    return result;
  }

  /// Deletes a party (vendor or person) from the database by id.
  Future<int> deleteParty(int id) async {
    final db = await instance.database;
    final result = await db.delete('parties', where: 'id = ?', whereArgs: [id]);

    // Notify listeners of database change
    DbBus.instance.bump();

    return result;
  }

  /// ينشئ مورد جديد إذا لم يوجد بنفس الاسم
  Future<Party?> createVendor(String name, {String? phone}) async {
    final exists = await _partyExists(name, PartyRole.vendor.toDbString());
    if (exists) {
      debugPrint('[DB-DEBUG] Vendor "$name" already exists, skipping creation');
      return null;
    }
    final party = await insertVendor(Party.vendor(name, phone: phone));
    debugPrint('[DB-DEBUG] Created vendor: $name, Role: ${PartyRole.vendor}');
    return party;
  }

  /// ينشئ شخص جديد إذا لم يوجد بنفس الاسم
  Future<Party?> createPerson(String name, {String? phone}) async {
    final exists = await _partyExists(name, PartyRole.person.toDbString());
    if (exists) {
      debugPrint('[DB-DEBUG] Person "$name" already exists, skipping creation');
      return null;
    }
    final party = await insertPerson(Party.person(name, phone: phone));
    debugPrint('[DB-DEBUG] Created person: $name, Role: ${PartyRole.person}');
    return party;
  }

  /// دالة مساعدة: هل يوجد طرف بنفس الاسم والنوع؟
  Future<bool> _partyExists(String name, String type) async {
    final db = await instance.database;
    final result = await db.query(
      'parties',
      where: 'LOWER(name) = ? AND type = ?',
      whereArgs: [name.trim().toLowerCase(), type.trim().toLowerCase()],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// دالة تنظيف: تصحيح الأنواع الخاطئة للأطراف القديمة (تشغيلها مرة واحدة فقط)
  Future<void> fixPartyTypes() async {
    final db = await instance.database;
    // Normalize existing types to lowercase
    await db.rawUpdate("UPDATE parties SET type = LOWER(TRIM(type))");
    // Fix any invalid types to default to 'person'
    await db.rawUpdate(
      "UPDATE parties SET type = '${Party.kPerson}' WHERE type NOT IN ('${Party.kVendor}','${Party.kPerson}')",
    );
    debugPrint('[DB-REPAIR] Fixed party types to canonical values');
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 11, // <-- Incremented for is_hidden support
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)
    ''');
    await db.insert('settings', {'key': 'totalCashBalance', 'value': '0.0'});

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        amount REAL NOT NULL,
        categoryId INTEGER NOT NULL,
        source TEXT NOT NULL CHECK(source IN ('cash', 'drawer', 'bank')),
        note TEXT,
        createdAt TEXT NOT NULL,
        is_hidden INTEGER DEFAULT 0 NOT NULL CHECK(is_hidden IN (0, 1))
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        iconCodePoint INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('expense', 'income')),
        UNIQUE(name, type)
      )
    ''');

    // Create income table with source constraint (supports cash, drawer, bank)
    await db.execute('''
      CREATE TABLE income (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        amount REAL NOT NULL,
        source TEXT NOT NULL CHECK(source IN ('cash', 'drawer', 'bank')),
        note TEXT,
        createdAt TEXT NOT NULL,
        is_hidden INTEGER DEFAULT 0 NOT NULL CHECK(is_hidden IN (0, 1))
      )
    ''');

    await db.execute('''
      CREATE TABLE parties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('person','vendor')),
        phone TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE debt_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        partyId INTEGER NOT NULL,
        kind TEXT NOT NULL,
        amount REAL NOT NULL,
        paymentMethod TEXT NOT NULL DEFAULT 'credit' CHECK(paymentMethod IN ('cash', 'credit', 'bank')),
        note TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (partyId) REFERENCES parties (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE drawer_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('start', 'end')),
        cashAmount REAL NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL,
        UNIQUE(date, type)
      )
    ''');

    await db.execute('''
      CREATE TABLE cash_balance_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        changeType TEXT NOT NULL CHECK(changeType IN ('manual_edit', 'cash_expense', 'day_closing', 'expense_deletion', 'debt_payment', 'debt_collection', 'cash_income')),
        oldBalance REAL NOT NULL,
        newBalance REAL NOT NULL,
        amount REAL NOT NULL,
        reason TEXT NOT NULL,
        details TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create bank transactions table
    await db.execute('''
      CREATE TABLE bank_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK(type IN ('credit', 'debit', 'transfer', 'fee', 'interest')),
        amount REAL NOT NULL,
        accountNumber TEXT NOT NULL,
        bankName TEXT NOT NULL,
        reference TEXT,
        description TEXT,
        category TEXT DEFAULT 'uncategorized',
        transactionDate TEXT NOT NULL,
        processedDate TEXT NOT NULL,
        balance REAL,
        isReconciled INTEGER DEFAULT 0,
        relatedInvoiceId INTEGER,
        relatedDebtId INTEGER,
        exchangeRate REAL DEFAULT 1.0,
        originalCurrency TEXT DEFAULT 'USD',
        tags TEXT,
        metadata TEXT,
        attachments TEXT,
        isInternal INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await _insertDefaultCategories(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrations for version 2 if any
    }
    if (oldVersion < 3) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS drawer_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('start', 'end')),
        cashAmount REAL NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL,
        UNIQUE(date, type)
        )
      ''');
    }
    if (oldVersion < 4) {
      // Add 'cash' to the CHECK constraint of the income table
      // SQLite doesn't support ALTER TABLE to modify a CHECK constraint directly.
      // The common workaround is to create a new table, copy data, and rename.
      await db.execute('PRAGMA foreign_keys=off;');
      await db.transaction((txn) async {
        await txn.execute('''
          CREATE TABLE income_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            amount REAL NOT NULL,
            source TEXT NOT NULL CHECK(source IN ('cash', 'drawer', 'bank')),
            note TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
        await txn.execute(
          'INSERT INTO income_new(id, date, amount, source, note, createdAt) SELECT id, date, amount, source, note, createdAt FROM income;',
        );
        await txn.execute('DROP TABLE income;');
        await txn.execute('ALTER TABLE income_new RENAME TO income;');
      });
      await db.execute('PRAGMA foreign_keys=on;');

      // Create indexes for performance
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_source ON expenses(source);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_income_date ON income(date);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_income_source ON income(source);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_drawer_snapshots_date_type ON drawer_snapshots(date, type);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_debt_entries_partyId ON debt_entries(partyId);',
      );
    }
    if (oldVersion < 5) {
      // Role-driven architecture migration
      debugPrint(
        '[DB-MIGRATION] Upgrading to version 5: Role-driven architecture',
      );

      // Step 1: Normalize existing party types to lowercase and valid values
      await db.execute('''
        UPDATE parties 
        SET type = LOWER(TRIM(type))
        WHERE type IS NOT NULL
      ''');

      await db.execute('''
        UPDATE parties 
        SET type = 'person' 
        WHERE type NOT IN ('person', 'vendor')
      ''');

      // Step 2: Create optional SQL views for role-specific queries
      await db.execute('''
        CREATE VIEW IF NOT EXISTS persons_view AS 
        SELECT * FROM parties WHERE type = 'person'
      ''');

      await db.execute('''
        CREATE VIEW IF NOT EXISTS vendors_view AS 
        SELECT * FROM parties WHERE type = 'vendor'
      ''');

      // Step 3: Add performance indexes for type-based queries
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_parties_type ON parties(type)
      ''');

      debugPrint('[DB-MIGRATION] Version 5 migration completed successfully');
    }

    if (oldVersion < 6) {
      // Cash balance change log feature
      debugPrint(
        '[DB-MIGRATION] Upgrading to version 6: Cash balance change log',
      );

      // Create cash_balance_log table for audit trail
      await db.execute('''
        CREATE TABLE cash_balance_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp TEXT NOT NULL,
          changeType TEXT NOT NULL CHECK(changeType IN ('manual_edit', 'cash_expense', 'day_closing', 'expense_deletion', 'debt_payment', 'debt_collection', 'cash_income')),
          oldBalance REAL NOT NULL,
          newBalance REAL NOT NULL,
          amount REAL NOT NULL,
          reason TEXT NOT NULL,
          details TEXT,
          createdAt TEXT NOT NULL
        )
      ''');

      // Add performance index for timestamp-based queries
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_cash_balance_log_timestamp ON cash_balance_log(timestamp)
      ''');

      // Add index for change type filtering
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_cash_balance_log_type ON cash_balance_log(changeType)
      ''');

      debugPrint('[DB-MIGRATION] Version 6 migration completed successfully');
    }

    if (oldVersion < 7) {
      // Add payment method to debt entries
      debugPrint('[DB-MIGRATION] Upgrading to version 7: Debt payment methods');

      // Add paymentMethod column to debt_entries table
      await db.execute('''
        ALTER TABLE debt_entries 
        ADD COLUMN paymentMethod TEXT NOT NULL DEFAULT 'credit' 
        CHECK(paymentMethod IN ('cash', 'credit', 'bank'))
      ''');

      debugPrint('[DB-MIGRATION] Version 7 migration completed successfully');
    }

    if (oldVersion < 8) {
      // Add bank transactions table
      debugPrint('[DB-MIGRATION] Upgrading to version 8: Bank transactions');

      await db.execute('''
        CREATE TABLE bank_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL CHECK(type IN ('credit', 'debit', 'transfer', 'fee', 'interest')),
          amount REAL NOT NULL,
          accountNumber TEXT NOT NULL,
          bankName TEXT NOT NULL,
          reference TEXT,
          description TEXT,
          category TEXT DEFAULT 'uncategorized',
          transactionDate TEXT NOT NULL,
          processedDate TEXT NOT NULL,
          balance REAL,
          isReconciled INTEGER DEFAULT 0,
          relatedInvoiceId INTEGER,
          relatedDebtId INTEGER,
          exchangeRate REAL DEFAULT 1.0,
          originalCurrency TEXT DEFAULT 'USD',
          tags TEXT,
          metadata TEXT,
          attachments TEXT,
          isInternal INTEGER DEFAULT 0,
          createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Create indexes for performance
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_bank_transactions_type ON bank_transactions(type)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_bank_transactions_date ON bank_transactions(transactionDate)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_bank_transactions_account ON bank_transactions(accountNumber)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_bank_transactions_bank ON bank_transactions(bankName)
      ''');

      debugPrint('[DB-MIGRATION] Version 8 migration completed successfully');
    }

    if (oldVersion < 9) {
      // Add unique constraint to categories to prevent duplicates
      debugPrint(
        '[DB-MIGRATION] Upgrading to version 9: Categories unique constraint',
      );

      // Since SQLite doesn't support ADD CONSTRAINT, recreate table
      await db.execute('PRAGMA foreign_keys=off;');
      await db.transaction((txn) async {
        // Create new categories table with unique constraint
        await txn.execute('''
          CREATE TABLE categories_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            iconCodePoint INTEGER NOT NULL,
            type TEXT NOT NULL CHECK(type IN ('expense', 'income')),
            UNIQUE(name, type)
          )
        ''');

        // Copy unique categories only (remove duplicates during migration)
        await txn.execute('''
          INSERT OR IGNORE INTO categories_new(id, name, iconCodePoint, type)
          SELECT MIN(id), name, iconCodePoint, type
          FROM categories
          GROUP BY name, type
        ''');

        // Drop old table and rename new one
        await txn.execute('DROP TABLE categories;');
        await txn.execute('ALTER TABLE categories_new RENAME TO categories;');
      });
      await db.execute('PRAGMA foreign_keys=on;');

      debugPrint('[DB-MIGRATION] Version 9 migration completed successfully');
    }

    if (oldVersion < 10) {
      // Add cash_income support to cash_balance_log
      debugPrint('[DB-MIGRATION] Upgrading to version 10: Cash income support');

      // SQLite doesn't support modifying CHECK constraints, so we need to recreate the table
      await db.execute('PRAGMA foreign_keys=off;');
      await db.transaction((txn) async {
        // Create new cash_balance_log table with updated CHECK constraint
        await txn.execute('''
          CREATE TABLE cash_balance_log_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            changeType TEXT NOT NULL CHECK(changeType IN ('manual_edit', 'cash_expense', 'day_closing', 'expense_deletion', 'debt_payment', 'debt_collection', 'cash_income')),
            oldBalance REAL NOT NULL,
            newBalance REAL NOT NULL,
            amount REAL NOT NULL,
            reason TEXT NOT NULL,
            details TEXT,
            createdAt TEXT NOT NULL
          )
        ''');

        // Copy existing data
        await txn.execute('''
          INSERT INTO cash_balance_log_new
          SELECT * FROM cash_balance_log
        ''');

        // Drop old table and rename new one
        await txn.execute('DROP TABLE cash_balance_log;');
        await txn.execute(
          'ALTER TABLE cash_balance_log_new RENAME TO cash_balance_log;',
        );

        // Recreate indexes
        await txn.execute('''
          CREATE INDEX IF NOT EXISTS idx_cash_balance_log_timestamp ON cash_balance_log(timestamp)
        ''');
        await txn.execute('''
          CREATE INDEX IF NOT EXISTS idx_cash_balance_log_type ON cash_balance_log(changeType)
        ''');
      });
      await db.execute('PRAGMA foreign_keys=on;');

      debugPrint('[DB-MIGRATION] Version 10 migration completed successfully');
    }

    if (oldVersion < 11) {
      // Add is_hidden support to expenses and income tables
      debugPrint(
        '[DB-MIGRATION] Upgrading to version 11: Hidden transactions support',
      );

      // Add is_hidden column to expenses table
      await db.execute('''
        ALTER TABLE expenses ADD COLUMN is_hidden INTEGER DEFAULT 0 NOT NULL CHECK(is_hidden IN (0, 1))
      ''');

      // Add is_hidden column to income table
      await db.execute('''
        ALTER TABLE income ADD COLUMN is_hidden INTEGER DEFAULT 0 NOT NULL CHECK(is_hidden IN (0, 1))
      ''');

      debugPrint('[DB-MIGRATION] Version 11 migration completed successfully');
    }
  }

  /// Force creation of SQL views (useful if migration was skipped)
  Future<void> ensureViewsExist() async {
    final db = await instance.database;

    debugPrint('[DB-VIEWS] Ensuring SQL views exist...');

    try {
      // Create persons view
      await db.execute('''
        CREATE VIEW IF NOT EXISTS persons_view AS 
        SELECT * FROM parties WHERE type = 'person'
      ''');

      // Create vendors view
      await db.execute('''
        CREATE VIEW IF NOT EXISTS vendors_view AS 
        SELECT * FROM parties WHERE type = 'vendor'
      ''');

      // Create performance index
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_parties_type ON parties(type)
      ''');

      debugPrint('[DB-VIEWS] SQL views created successfully');
    } catch (e) {
      debugPrint('[DB-VIEWS] Error creating views: $e');
    }
  }

  // --- CRUD for Parties ---
  Future<Party> createParty(Party party) async {
    final db = await instance.database;

    debugPrint(
      '[createParty] name=${party.name} role=${party.role} phone=${party.phone}',
    );

    final id = await db.insert('parties', party.toMap());
    final createdParty = party.copyWith(id: id);

    // Notify listeners of database change
    DbBus.instance.bump();

    return createdParty;
  }

  Future<List<Party>> getParties(String type) async {
    final db = await instance.database;
    final normalizedType = type.trim().toLowerCase();

    debugPrint('[getParties] Fetching parties of type: $normalizedType');

    final maps = await db.query(
      'parties',
      where: 'type = ?',
      whereArgs: [normalizedType],
    );

    final parties = List.generate(maps.length, (i) => Party.fromMap(maps[i]));

    // Debug logging for each party
    for (final party in parties) {
      debugPrint(
        'Party: ${party.name}, Type: ${party.type}, Widget Type: $normalizedType',
      );
    }

    return parties;
  }

  Future<Party?> getPartyById(int id) async {
    final db = await instance.database;
    final maps = await db.query('parties', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Party.fromMap(maps.first);
    }
    return null;
  }

  // --- Role-Specific Party Methods ---

  /// Get all persons from the database
  Future<List<Party>> getPersons() async {
    final db = await instance.database;

    debugPrint('[REPO] getPersons() called');

    // Try to use the persons_view, fallback to main table if view doesn't exist
    List<Map<String, dynamic>> maps;
    try {
      maps = await db.query('persons_view');
    } catch (e) {
      debugPrint('[REPO] persons_view not found, using fallback query: $e');
      maps = await db.query(
        'parties',
        where: 'type = ?',
        whereArgs: [PartyRole.person.toDbString()],
      );
    }

    final parties = List.generate(maps.length, (i) => Party.fromMap(maps[i]));

    // Assert role consistency in debug mode
    for (final party in parties) {
      assert(
        party.role == PartyRole.person,
        'Expected person role but got ${party.role} for party ${party.name}',
      );
      debugPrint(
        '[ASSERT] item.role == PartyRole.person passed for ${party.name}',
      );
    }

    debugPrint('[REPO] getPersons() rows=${parties.length}');
    return parties;
  }

  /// Get all vendors from the database
  Future<List<Party>> getVendors() async {
    final db = await instance.database;

    debugPrint('[REPO] getVendors() called');

    // Try to use the vendors_view, fallback to main table if view doesn't exist
    List<Map<String, dynamic>> maps;
    try {
      maps = await db.query('vendors_view');
    } catch (e) {
      debugPrint('[REPO] vendors_view not found, using fallback query: $e');
      maps = await db.query(
        'parties',
        where: 'type = ?',
        whereArgs: [PartyRole.vendor.toDbString()],
      );
    }

    final parties = List.generate(maps.length, (i) => Party.fromMap(maps[i]));

    // Assert role consistency in debug mode
    for (final party in parties) {
      assert(
        party.role == PartyRole.vendor,
        'Expected vendor role but got ${party.role} for party ${party.name}',
      );
      debugPrint(
        '[ASSERT] item.role == PartyRole.vendor passed for ${party.name}',
      );
    }

    debugPrint('[REPO] getVendors() rows=${parties.length}');
    return parties;
  }

  /// Insert a new person
  Future<Party> insertPerson(Party person) async {
    // Ensure role is correctly set
    final personToInsert = person.copyWith(role: PartyRole.person);
    debugPrint('[DB] insertPerson(name=${person.name}) → DbBus.bump');
    return await createParty(personToInsert);
  }

  /// Insert a new vendor
  Future<Party> insertVendor(Party vendor) async {
    // Ensure role is correctly set
    final vendorToInsert = vendor.copyWith(role: PartyRole.vendor);
    debugPrint('[DB] insertVendor(name=${vendor.name}) → DbBus.bump');
    return await createParty(vendorToInsert);
  }

  Future<void> logInvalidPartyTypes() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> invalidParties = await db.rawQuery(
      "SELECT * FROM parties WHERE TRIM(LOWER(type)) NOT IN ('${Party.kVendor}', '${Party.kPerson}')",
    );

    if (invalidParties.isNotEmpty) {
      debugPrint(
        '[DB-DIAGNOSTIC] Found ${invalidParties.length} parties with invalid types.',
      );
      for (final partyMap in invalidParties) {
        debugPrint(
          '  - ID: ${partyMap['id']}, Name: ${partyMap['name']}, Invalid Type: "${partyMap['type']}"',
        );
      }
    } else {
      debugPrint('[DB-DIAGNOSTIC] All party types are valid.');
    }
  }

  // --- CRUD for Debt Entries ---
  Future<DebtEntry> createDebtEntry(DebtEntry debtEntry) async {
    final db = await instance.database;
    final id = await db.insert('debt_entries', debtEntry.toMap());
    DbBus.instance.bump(); // ✅ إطلاق حدث التحديث
    return debtEntry.copyWith(id: id);
  }

  /// تحديث معاملة دين موجودة
  Future<void> updateDebtEntry(DebtEntry debtEntry) async {
    if (debtEntry.id == null) {
      throw ArgumentError('Cannot update debt entry without an ID');
    }

    final db = await instance.database;
    await db.update(
      'debt_entries',
      debtEntry.toMap(),
      where: 'id = ?',
      whereArgs: [debtEntry.id],
    );
    DbBus.instance.bump(); // ✅ إطلاق حدث التحديث
    debugPrint('[DB] Updated debt entry: id=${debtEntry.id}');
  }

  /// حذف معاملة دين
  Future<void> deleteDebtEntry(int debtEntryId) async {
    final db = await instance.database;
    await db.delete('debt_entries', where: 'id = ?', whereArgs: [debtEntryId]);
    DbBus.instance.bump(); // ✅ إطلاق حدث التحديث
    debugPrint('[DB] Deleted debt entry: id=$debtEntryId');
  }

  Future<double> getPartyBalance(int partyId) async {
    final db = await instance.database;
    final entries = await db.query(
      'debt_entries',
      where: 'partyId = ?',
      whereArgs: [partyId],
    );
    double balance = 0.0;
    for (var entry in entries) {
      final kind = entry['kind'] as String;
      final amount = (entry['amount'] as num).toDouble();
      final paymentMethod = entry['paymentMethod'] as String?;

      // المعاملات التي تُنشئ ديون جديدة
      final bool isDebtCreation =
          kind == 'purchase_credit' || kind == 'loan_out';
      final bool isDebtPayment = kind == 'payment' || kind == 'settlement';

      // تخطي فقط purchase_credit النقدي (الشراء النقدي ليس دينًا)
      // لكن loan_out يُحتسب دائمًا (الإقراض دائمًا دين، نقدي أو آجل)
      if (kind == 'purchase_credit' && paymentMethod != 'credit') {
        continue; // تجاهل الشراء النقدي فقط
      }

      // حساب التغيير في الرصيد
      if (isDebtCreation) {
        balance += amount;
      } else if (isDebtPayment) {
        balance -= amount;
      }
    }
    return balance;
  }

  Future<List<DebtEntry>> getDebtEntriesForParty(int partyId) async {
    final db = await instance.database;
    final maps = await db.query(
      'debt_entries',
      where: 'partyId = ?',
      whereArgs: [partyId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => DebtEntry.fromMap(maps[i]));
  }

  /// Get transaction count for a specific party
  Future<int> getPartyTransactionCount(int partyId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM debt_entries
      WHERE partyId = ?
    ''',
      [partyId],
    );
    return result.first['count'] as int;
  }

  /// Get last transaction date for a specific party
  Future<DateTime?> getPartyLastTransactionDate(int partyId) async {
    final db = await instance.database;
    final result = await db.query(
      'debt_entries',
      where: 'partyId = ?',
      whereArgs: [partyId],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;

    return DateTime.parse(result.first['date'] as String);
  }

  /// Get party statistics (balance, transaction count, last transaction date)
  Future<Map<String, dynamic>> getPartyStats(int partyId) async {
    final db = await instance.database;

    // Get balance and count in a single query for efficiency
    // Use LEFT JOIN to include parties without transactions
    final result = await db.rawQuery(
      '''
      SELECT 
        COALESCE(COUNT(de.id), 0) as transactionCount,
        COALESCE(SUM(CASE 
          -- purchase_credit: فقط الآجل يُحتسب كدين
          WHEN de.kind = 'purchase_credit' AND de.paymentMethod = 'credit' THEN de.amount
          -- loan_out: يُحتسب دائمًا (نقدي أو آجل - الإقراض دائمًا دين)
          WHEN de.kind = 'loan_out' THEN de.amount
          -- المعاملات التي تُسدد ديون: بأي طريقة دفع
          WHEN (de.kind = 'payment' OR de.kind = 'settlement') THEN -de.amount
          ELSE 0
        END), 0) as balance,
        MAX(de.date) as lastTransactionDate
      FROM parties p
      LEFT JOIN debt_entries de ON p.id = de.partyId
      WHERE p.id = ?
      GROUP BY p.id
    ''',
      [partyId],
    );

    if (result.isEmpty) {
      // Party doesn't exist
      return {
        'balance': 0.0,
        'transactionCount': 0,
        'lastTransactionDate': null,
      };
    }

    final row = result.first;
    return {
      'balance': (row['balance'] as num).toDouble(),
      'transactionCount': row['transactionCount'] as int,
      'lastTransactionDate': row['lastTransactionDate'] != null
          ? DateTime.parse(row['lastTransactionDate'] as String)
          : null,
    };
  }

  /// Get statistics for multiple parties at once (more efficient)
  Future<Map<int, Map<String, dynamic>>> getAllPartiesStats(
    PartyRole role,
  ) async {
    final db = await instance.database;

    final result = await db.rawQuery(
      '''
      SELECT 
        p.id,
        COALESCE(COUNT(de.id), 0) as transactionCount,
        COALESCE(SUM(CASE 
          -- purchase_credit: فقط الآجل يُحتسب كدين
          WHEN de.kind = 'purchase_credit' AND de.paymentMethod = 'credit' THEN de.amount
          -- loan_out: يُحتسب دائمًا (نقدي أو آجل - الإقراض دائمًا دين)
          WHEN de.kind = 'loan_out' THEN de.amount
          -- المعاملات التي تُسدد ديون: بأي طريقة دفع
          WHEN (de.kind = 'payment' OR de.kind = 'settlement') THEN -de.amount
          ELSE 0
        END), 0) as balance,
        MAX(de.date) as lastTransactionDate
      FROM parties p
      LEFT JOIN debt_entries de ON p.id = de.partyId
      WHERE p.type = ?
      GROUP BY p.id
    ''',
      [role.toDbString()],
    );

    final Map<int, Map<String, dynamic>> statsMap = {};
    for (final row in result) {
      final partyId = row['id'] as int;
      statsMap[partyId] = {
        'balance': (row['balance'] as num).toDouble(),
        'transactionCount': row['transactionCount'] as int,
        'lastTransactionDate': row['lastTransactionDate'] != null
            ? DateTime.parse(row['lastTransactionDate'] as String)
            : null,
      };
    }

    return statsMap;
  }

  // --- CRUD for Categories ---
  Future<Category> createCategory(Category category) async {
    final db = await instance.database;
    final id = await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    // If insert was ignored due to unique constraint, get existing category
    if (id == 0) {
      final existing = await db.query(
        'categories',
        where: 'name = ? AND type = ?',
        whereArgs: [category.name, category.type],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return Category.fromMap(existing.first);
      }
    }

    return category.copyWith(id: id);
  }

  Future<List<Category>> getCategories(String type) async {
    final db = await instance.database;
    final maps = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name',
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await instance.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCategory(Category category) async {
    final db = await instance.database;
    return db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD for Expenses ---
  Future<Expense> createExpense(Expense expense) async {
    final db = await instance.database;
    final id = await db.insert('expenses', expense.toMap());
    return expense.copyWith(id: id);
  }

  Future<List<Expense>> getExpensesForDate(DateTime date) async {
    final db = await instance.database;
    final dateStart = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();
    final dateEnd = DateTime(
      date.year,
      date.month,
      date.day + 1,
    ).toIso8601String();
    final maps = await db.query(
      'expenses',
      where: 'date >= ? AND date < ? AND (is_hidden IS NULL OR is_hidden = 0)',
      whereArgs: [dateStart, dateEnd],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<List<Expense>> getExpensesForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await instance.database;
    final maps = await db.query(
      'expenses',
      where: 'date >= ? AND date < ? AND (is_hidden IS NULL OR is_hidden = 0)',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await instance.database;
    return db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<Expense?> getExpenseById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Expense.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD for Income ---
  Future<Income> createIncome(Income income) async {
    final db = await instance.database;
    final id = await db.insert('income', income.toMap());
    return income.copyWith(id: id);
  }

  Future<List<Income>> getIncomeForDate(DateTime date) async {
    final db = await instance.database;
    final dateStart = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();
    final dateEnd = DateTime(
      date.year,
      date.month,
      date.day + 1,
    ).toIso8601String();
    final maps = await db.query(
      'income',
      where: 'date >= ? AND date < ? AND (is_hidden IS NULL OR is_hidden = 0)',
      whereArgs: [dateStart, dateEnd],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Income.fromMap(maps[i]));
  }

  Future<List<Income>> getIncomeForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await instance.database;
    final maps = await db.query(
      'income',
      where: 'date >= ? AND date < ? AND (is_hidden IS NULL OR is_hidden = 0)',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Income.fromMap(maps[i]));
  }

  Future<int> deleteIncome(int id) async {
    final db = await instance.database;
    return db.delete('income', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateIncome(Income income) async {
    final db = await instance.database;
    return db.update(
      'income',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  /// Update income with cash balance impact tracking
  Future<void> updateIncomeWithBalanceTracking({
    required Income oldIncome,
    required Income newIncome,
    required double currentCashBalance,
  }) async {
    final db = await instance.database;

    // Calculate the difference
    final oldAmount = oldIncome.source == TransactionSource.cash
        ? oldIncome.amount
        : 0;
    final newAmount = newIncome.source == TransactionSource.cash
        ? newIncome.amount
        : 0;
    final difference = newAmount - oldAmount;

    if (difference != 0) {
      final oldBalance = currentCashBalance;
      final newBalance = oldBalance + difference;

      // Update income
      await db.update(
        'income',
        newIncome.toMap(),
        where: 'id = ?',
        whereArgs: [newIncome.id],
      );

      // Update actual cash balance in app_settings
      await saveSetting('totalCashBalance', newBalance.toString());

      // Log cash balance change
      final log = CashBalanceLog(
        timestamp: DateTime.now(),
        changeType: CashBalanceChangeType.cashIncome,
        oldBalance: oldBalance,
        newBalance: newBalance,
        amount: difference.abs().toDouble(),
        reason: difference > 0
            ? 'تعديل دخل نقدي (زيادة): ${newIncome.note ?? ""}'
            : 'تعديل دخل نقدي (نقصان): ${newIncome.note ?? ""}',
        details:
            'تم التعديل من ${oldAmount.toStringAsFixed(2)} إلى ${newAmount.toStringAsFixed(2)}',
        createdAt: DateTime.now(),
      );

      await insertCashBalanceLog(log);
    } else {
      // No cash balance impact, just update the income
      await db.update(
        'income',
        newIncome.toMap(),
        where: 'id = ?',
        whereArgs: [newIncome.id],
      );
    }
  }

  /// Delete income with cash balance impact tracking
  Future<void> deleteIncomeWithBalanceTracking({
    required int incomeId,
    required double currentCashBalance,
  }) async {
    final db = await instance.database;

    // Get the income first
    final maps = await db.query(
      'income',
      where: 'id = ?',
      whereArgs: [incomeId],
      limit: 1,
    );

    if (maps.isEmpty) return;

    final income = Income.fromMap(maps.first);

    // If it's cash income, update the balance
    if (income.source == TransactionSource.cash && income.amount > 0) {
      final oldBalance = currentCashBalance;
      final newBalance = oldBalance - income.amount;

      // Delete the income
      await db.delete('income', where: 'id = ?', whereArgs: [incomeId]);

      // Update actual cash balance in app_settings
      await saveSetting('totalCashBalance', newBalance.toString());

      // Log cash balance change
      final log = CashBalanceLog(
        timestamp: DateTime.now(),
        changeType: CashBalanceChangeType.cashIncome,
        oldBalance: oldBalance,
        newBalance: newBalance,
        amount: income.amount,
        reason: 'حذف دخل نقدي: ${income.note ?? ""}',
        details: 'مبلغ: ${income.amount.toStringAsFixed(2)}',
        createdAt: DateTime.now(),
      );

      await insertCashBalanceLog(log);
    } else {
      // No cash balance impact, just delete
      await db.delete('income', where: 'id = ?', whereArgs: [incomeId]);
    }
  }

  Future<List<DrawerSnapshot>> getAllDrawerSnapshots() async {
    final db = await instance.database;
    final maps = await db.query('drawer_snapshots', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => DrawerSnapshot.fromMap(maps[i]));
  }

  Future<int> deleteDrawerSnapshot(int id) async {
    final db = await instance.database;
    return db.delete('drawer_snapshots', where: 'id = ?', whereArgs: [id]);
  }

  // --- Drawer Snapshot ---
  Future<DrawerSnapshot> saveDrawerSnapshot(DrawerSnapshot snapshot) async {
    final db = await instance.database;
    // The toMapForDb method now handles the date string conversion
    final data = snapshot.toMapForDb();
    final id = await db.insert(
      'drawer_snapshots',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return snapshot.copyWith(id: id);
  }

  Future<DrawerSnapshot?> getSnapshotForDate(
    DateTime date,
    SnapshotType type,
  ) async {
    final db = await instance.database;
    final dateString = date.toIso8601String().substring(0, 10);
    final maps = await db.query(
      'drawer_snapshots',
      where: 'date = ? AND type = ?',
      whereArgs: [dateString, type.name], // <-- Use enum's name
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return DrawerSnapshot.fromMap(maps.first);
    }
    return null;
  }

  Future<DrawerSnapshot?> getLatestEndSnapshotBefore(DateTime date) async {
    final db = await instance.database;
    final dateString = date.toIso8601String().substring(0, 10);
    final maps = await db.query(
      'drawer_snapshots',
      where: 'type = ? AND date < ?',
      whereArgs: [SnapshotType.end.name, dateString], // <-- Use enum's name
      orderBy: 'date DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return DrawerSnapshot.fromMap(maps.first);
    }
    return null;
  }

  Future<DrawerSnapshot?> getEarliestEndSnapshotAfter(DateTime date) async {
    final db = await instance.database;
    final dateString = date.toIso8601String().substring(0, 10);
    final maps = await db.query(
      'drawer_snapshots',
      where: 'type = ? AND date >= ?',
      whereArgs: [SnapshotType.end.name, dateString], // <-- Use enum's name
      orderBy: 'date ASC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return DrawerSnapshot.fromMap(maps.first);
    }
    return null;
  }

  /// Get the last start balance before the most recent closure (end snapshot)
  /// If no closure exists, return the most recent start balance
  Future<DrawerSnapshot?> getLastStartBalanceBeforeLastClosure() async {
    final db = await instance.database;

    // First, find the most recent end snapshot (closure)
    final lastClosureMaps = await db.query(
      'drawer_snapshots',
      where: 'type = ?',
      whereArgs: [SnapshotType.end.name],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (lastClosureMaps.isEmpty) {
      // No closure exists, return the most recent start balance
      final lastStartMaps = await db.query(
        'drawer_snapshots',
        where: 'type = ?',
        whereArgs: [SnapshotType.start.name],
        orderBy: 'date DESC',
        limit: 1,
      );
      if (lastStartMaps.isNotEmpty) {
        return DrawerSnapshot.fromMap(lastStartMaps.first);
      }
      return null;
    }

    // Get the date of the last closure
    final lastClosureDate = lastClosureMaps.first['date'] as String;

    // Find the most recent start balance before this closure
    final startBeforeClosureMaps = await db.query(
      'drawer_snapshots',
      where: 'type = ? AND date <= ?',
      whereArgs: [SnapshotType.start.name, lastClosureDate],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (startBeforeClosureMaps.isNotEmpty) {
      return DrawerSnapshot.fromMap(startBeforeClosureMaps.first);
    }
    return null;
  }

  Future<double> getDrawerExpensesForDate(DateTime date) async {
    final db = await instance.database;
    final dateString = date.toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE date LIKE ? AND source = ?',
      ['$dateString%', TransactionSource.drawer.name], // <-- Use enum's name
    );
    return (result.first['total'] as num? ?? 0.0).toDouble();
  }

  Future<double> getDrawerExpensesForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await instance.database;
    final startDateString = startDate.toIso8601String().substring(0, 10);
    final endDateString = endDate.toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE DATE(date) >= ? AND DATE(date) <= ? AND source = ?',
      [startDateString, endDateString, TransactionSource.drawer.name],
    );
    return (result.first['total'] as num? ?? 0.0).toDouble();
  }

  Future<double> getDrawerIncomesForDate(DateTime date) async {
    final db = await instance.database;
    final dateString = date.toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM income WHERE date LIKE ? AND source = ?',
      ['$dateString%', TransactionSource.drawer.name], // <-- Use enum's name
    );
    return (result.first['total'] as num? ?? 0.0).toDouble();
  }

  // --- Settings ---
  Future<void> saveSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  // --- Cash Balance Log CRUD Operations ---

  /// Ensure cash_balance_log table exists (for backwards compatibility)
  Future<void> _ensureCashBalanceLogTableExists() async {
    final db = await instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cash_balance_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        changeType TEXT NOT NULL CHECK(changeType IN ('manual_edit', 'cash_expense', 'day_closing', 'expense_deletion')),
        oldBalance REAL NOT NULL,
        newBalance REAL NOT NULL,
        amount REAL NOT NULL,
        reason TEXT NOT NULL,
        details TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Add indexes if they don't exist
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_cash_balance_log_timestamp ON cash_balance_log(timestamp)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_cash_balance_log_type ON cash_balance_log(changeType)
    ''');
  }

  /// Insert a new cash balance log entry
  Future<int> insertCashBalanceLog(CashBalanceLog log) async {
    await _ensureCashBalanceLogTableExists();
    final db = await instance.database;
    final id = await db.insert('cash_balance_log', log.toMap());

    // Notify listeners of database change
    DbBus.instance.bump();

    return id;
  }

  /// Get all cash balance logs ordered by timestamp (newest first)
  Future<List<CashBalanceLog>> getCashBalanceLogs({int? limit}) async {
    await _ensureCashBalanceLogTableExists();
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cash_balance_log',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => CashBalanceLog.fromMap(maps[i]));
  }

  /// Get cash balance logs within a date range
  Future<List<CashBalanceLog>> getCashBalanceLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    await _ensureCashBalanceLogTableExists();
    final db = await instance.database;
    final startDateString = startDate.toIso8601String().substring(0, 10);
    final endDateString = endDate.toIso8601String().substring(0, 10);

    final List<Map<String, dynamic>> maps = await db.query(
      'cash_balance_log',
      where: 'DATE(timestamp) >= ? AND DATE(timestamp) <= ?',
      whereArgs: [startDateString, endDateString],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => CashBalanceLog.fromMap(maps[i]));
  }

  /// Get cash balance logs by change type
  Future<List<CashBalanceLog>> getCashBalanceLogsByType(
    CashBalanceChangeType changeType, {
    int? limit,
  }) async {
    await _ensureCashBalanceLogTableExists();
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cash_balance_log',
      where: 'changeType = ?',
      whereArgs: [changeType.value],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => CashBalanceLog.fromMap(maps[i]));
  }

  /// Get cash balance logs for a specific date
  Future<List<CashBalanceLog>> getCashBalanceLogsForDate(DateTime date) async {
    await _ensureCashBalanceLogTableExists();
    final db = await instance.database;
    final dateString = date.toIso8601String().substring(0, 10);

    final List<Map<String, dynamic>> maps = await db.query(
      'cash_balance_log',
      where: 'DATE(timestamp) = ?',
      whereArgs: [dateString],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => CashBalanceLog.fromMap(maps[i]));
  }

  /// Get latest cash balance log entry
  Future<CashBalanceLog?> getLatestCashBalanceLog() async {
    await _ensureCashBalanceLogTableExists();
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cash_balance_log',
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return CashBalanceLog.fromMap(maps.first);
    }
    return null;
  }

  /// Delete cash balance log entry by id
  Future<int> deleteCashBalanceLog(int id) async {
    await _ensureCashBalanceLogTableExists();
    final db = await instance.database;
    final result = await db.delete(
      'cash_balance_log',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Notify listeners of database change
    DbBus.instance.bump();

    return result;
  }

  /// Get cash balance statistics for a date range
  Future<Map<String, dynamic>> getCashBalanceLogStats(
    DateTime startDate,
    DateTime endDate,
  ) async {
    await _ensureCashBalanceLogTableExists();
    final db = await instance.database;
    final startDateString = startDate.toIso8601String().substring(0, 10);
    final endDateString = endDate.toIso8601String().substring(0, 10);

    final result = await db.rawQuery(
      '''
      SELECT 
        changeType,
        COUNT(*) as count,
        SUM(amount) as totalAmount,
        AVG(amount) as avgAmount
      FROM cash_balance_log 
      WHERE DATE(timestamp) >= ? AND DATE(timestamp) <= ?
      GROUP BY changeType
    ''',
      [startDateString, endDateString],
    );

    return {'stats': result, 'startDate': startDate, 'endDate': endDate};
  }

  // --- CRUD for Bank Transactions ---
  Future<int> createBankTransaction(Map<String, dynamic> transaction) async {
    final db = await instance.database;

    // Add timestamps if not provided
    final now = DateTime.now().toIso8601String();
    transaction['createdAt'] = transaction['createdAt'] ?? now;
    transaction['updatedAt'] = now;

    debugPrint(
      '[createBankTransaction] type=${transaction['type']} amount=${transaction['amount']} bank=${transaction['bankName']}',
    );

    final id = await db.insert('bank_transactions', transaction);

    // Notify listeners of database change
    DbBus.instance.bump();

    return id;
  }

  Future<List<Map<String, dynamic>>> getBankTransactions({
    String? accountNumber,
    String? bankName,
    String? type,
    String? startDate,
    String? endDate,
    int? limit,
    int? offset,
  }) async {
    final db = await instance.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (accountNumber != null) {
      whereClause += 'accountNumber = ?';
      whereArgs.add(accountNumber);
    }

    if (bankName != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'bankName = ?';
      whereArgs.add(bankName);
    }

    if (type != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'type = ?';
      whereArgs.add(type);
    }

    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'transactionDate >= ?';
      whereArgs.add(startDate);
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'transactionDate <= ?';
      whereArgs.add(endDate);
    }

    return await db.query(
      'bank_transactions',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'transactionDate DESC, id DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>?> getBankTransactionById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'bank_transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateBankTransaction(
    int id,
    Map<String, dynamic> transaction,
  ) async {
    final db = await instance.database;

    // Update timestamp
    transaction['updatedAt'] = DateTime.now().toIso8601String();

    final result = await db.update(
      'bank_transactions',
      transaction,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Notify listeners of database change
    DbBus.instance.bump();

    return result;
  }

  Future<int> deleteBankTransaction(int id) async {
    final db = await instance.database;
    final result = await db.delete(
      'bank_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Notify listeners of database change
    DbBus.instance.bump();

    return result;
  }

  /// Get bank transaction statistics for a date range
  Future<Map<String, dynamic>> getBankTransactionStats({
    String? accountNumber,
    String? bankName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await instance.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (accountNumber != null) {
      whereClause += 'accountNumber = ?';
      whereArgs.add(accountNumber);
    }

    if (bankName != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'bankName = ?';
      whereArgs.add(bankName);
    }

    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'transactionDate >= ?';
      whereArgs.add(startDate.toIso8601String().split('T')[0]);
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'transactionDate <= ?';
      whereArgs.add(endDate.toIso8601String().split('T')[0]);
    }

    final result = await db.rawQuery('''
      SELECT 
        type,
        COUNT(*) as count,
        SUM(amount) as total,
        AVG(amount) as average,
        MIN(amount) as minimum,
        MAX(amount) as maximum
      FROM bank_transactions
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      GROUP BY type
    ''', whereArgs);

    return {
      'stats': result,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  /// Get all unique bank accounts
  Future<List<Map<String, dynamic>>> getBankAccounts() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT DISTINCT accountNumber, bankName, 
             COUNT(*) as transactionCount,
             SUM(CASE WHEN type = 'credit' THEN amount ELSE -amount END) as balance
      FROM bank_transactions 
      GROUP BY accountNumber, bankName
      ORDER BY bankName, accountNumber
    ''');
  }

  /// Mark bank transaction as reconciled
  Future<int> reconcileBankTransaction(int id, bool isReconciled) async {
    final db = await instance.database;
    final result = await db.update(
      'bank_transactions',
      {
        'isReconciled': isReconciled ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    // Notify listeners of database change
    DbBus.instance.bump();

    return result;
  }

  // --- Default Data ---
  Future<void> _insertDefaultCategories(Database db) async {
    final categories = [
      {'name': 'مواصلات', 'icon': Icons.directions_bus, 'type': 'expense'},
      {'name': 'طعام', 'icon': Icons.restaurant, 'type': 'expense'},
      {'name': 'تسوق', 'icon': Icons.shopping_bag, 'type': 'expense'},
      {'name': 'منزل', 'icon': Icons.home, 'type': 'expense'},
      {'name': 'صحة', 'icon': Icons.health_and_safety, 'type': 'expense'},
      {'name': 'فواتير', 'icon': Icons.receipt_long, 'type': 'expense'},
    ];
    for (var cat in categories) {
      await db.insert('categories', {
        'name': cat['name'] as String,
        'iconCodePoint': (cat['icon'] as IconData).codePoint,
        'type': cat['type'] as String,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  /// إزالة الفئات المكررة من قاعدة البيانات
  Future<void> removeDuplicateCategories() async {
    final db = await database;

    print('🔄 بدء إزالة الفئات المكررة...');

    // الحصول على جميع الفئات مع عدد التكرار
    final duplicates = await db.rawQuery('''
      SELECT name, type, MIN(id) as keep_id, COUNT(*) as count
      FROM categories 
      GROUP BY name, type 
      HAVING COUNT(*) > 1
    ''');

    print('📊 تم العثور على ${duplicates.length} فئة مكررة');

    for (var duplicate in duplicates) {
      final name = duplicate['name'] as String;
      final type = duplicate['type'] as String;
      final keepId = duplicate['keep_id'] as int;
      final count = duplicate['count'] as int;

      print('🗑️ إزالة ${count - 1} نسخة مكررة من فئة "$name" ($type)');

      // حذف جميع النسخ المكررة عدا الأولى
      await db.delete(
        'categories',
        where: 'name = ? AND type = ? AND id != ?',
        whereArgs: [name, type, keepId],
      );
    }

    // الحصول على العدد النهائي
    final finalCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM categories',
    );
    final totalCategories = finalCount.first['count'] as int;

    print('✅ تم الانتهاء! إجمالي الفئات الآن: $totalCategories');
  }

  /// تنظيف جميع البيانات المكررة
  Future<void> cleanupDuplicateData() async {
    await removeDuplicateCategories();

    // يمكن إضافة تنظيف البيانات المكررة الأخرى هنا
    // مثل الأشخاص والموردين إذا لزم الأمر
  }
}
