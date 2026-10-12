import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the single SQLite connection and the schema (fully offline).
///
/// Schema overview
///   partners              – the business partners
///   bikes                 – inventory (new + used), one row per bike
///   partner_contributions – capital put in by a partner; bike_id NULL = general capital
///   bike_expenses         – bike_id set = cost of that bike; NULL = daily showroom expense
///   sales                 – one sale per bike (UNIQUE bike_id)
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'bike_showroom.db';
  static const int _dbVersion = 1;

  Database? _db;
  Future<Database>? _opening;

  Future<Database> get database async {
    if (_db != null) return _db!;
    // Guard against concurrent first-time opens.
    return _opening ??= _open().then((db) => _db = db);
  }

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE partners (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT NOT NULL,
        phone       TEXT,
        created_at  TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    batch.execute('''
      CREATE TABLE bikes (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        make             TEXT NOT NULL,
        model            TEXT NOT NULL,
        year             INTEGER NOT NULL,
        condition        TEXT NOT NULL CHECK (condition IN ('new','used')),
        registration_no  TEXT,
        chassis_no       TEXT UNIQUE,
        color            TEXT,
        mileage_km       INTEGER,
        purchase_price   REAL NOT NULL CHECK (purchase_price >= 0),
        purchase_date    TEXT NOT NULL,
        status           TEXT NOT NULL DEFAULT 'available'
                         CHECK (status IN ('available','reserved','sold','under_repair')),
        notes            TEXT,
        created_at       TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    batch.execute('''
      CREATE TABLE partner_contributions (
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        partner_id         INTEGER NOT NULL
                           REFERENCES partners(id) ON DELETE RESTRICT,
        bike_id            INTEGER REFERENCES bikes(id) ON DELETE CASCADE,
        amount             REAL NOT NULL CHECK (amount > 0),
        contribution_date  TEXT NOT NULL,
        note               TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE bike_expenses (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        bike_id       INTEGER REFERENCES bikes(id) ON DELETE CASCADE,
        category      TEXT NOT NULL,
        description   TEXT,
        amount        REAL NOT NULL CHECK (amount > 0),
        expense_date  TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE sales (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        bike_id      INTEGER NOT NULL UNIQUE
                     REFERENCES bikes(id) ON DELETE CASCADE,
        buyer_name   TEXT NOT NULL,
        buyer_phone  TEXT,
        sale_price   REAL NOT NULL CHECK (sale_price >= 0),
        sale_date    TEXT NOT NULL,
        notes        TEXT
      )
    ''');

    batch.execute('CREATE INDEX idx_bikes_status ON bikes(status)');
    batch.execute('CREATE INDEX idx_expenses_bike ON bike_expenses(bike_id)');
    batch.execute('CREATE INDEX idx_expenses_date ON bike_expenses(expense_date)');
    batch.execute('CREATE INDEX idx_contrib_bike ON partner_contributions(bike_id)');
    batch.execute('CREATE INDEX idx_contrib_partner ON partner_contributions(partner_id)');
    batch.execute('CREATE INDEX idx_sales_date ON sales(sale_date)');

    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add forward-only migrations here, e.g.:
    // if (oldVersion < 2) { await db.execute('ALTER TABLE bikes ADD COLUMN ...'); }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
    _opening = null;
  }
}
