import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'security_service.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  Future<Database>? _databaseFuture;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _databaseFuture ??= _initDB('qubico.db');
    _database = await _databaseFuture!;
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    debugPrint('DEBUG QUBICO: Initializing database at path: $path');

    return await openDatabase(
      path,
      version: 9,
      onCreate: (db, version) async {
        debugPrint('DEBUG QUBICO: onCreate triggered for version $version');
        await _createDB(db, version);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        debugPrint('DEBUG QUBICO: onUpgrade triggered from $oldVersion to $newVersion');
        if (oldVersion < 9) {
          debugPrint('DEBUG QUBICO: Purging older tables to upgrade schema to v7...');
          await db.execute('DROP TABLE IF EXISTS orders');
          await db.execute('DROP TABLE IF EXISTS clients');
          await db.execute('DROP TABLE IF EXISTS users');
          await db.execute('DROP TABLE IF EXISTS vehicles');
          await db.execute('DROP TABLE IF EXISTS audit_logs');
          await db.execute('DROP TABLE IF EXISTS sync_queue');
          debugPrint('DEBUG QUBICO: All older tables dropped. Recreating with v7...');
          await _createDB(db, 7);
          debugPrint('DEBUG QUBICO: Recreated database successfully for v7.');
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        patente TEXT NOT NULL,
        max_weight REAL NOT NULL,
        driver_name TEXT NOT NULL,
        driver_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE clients (
        rut TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        billing_address TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id TEXT NOT NULL,
        weight REAL NOT NULL,
        height REAL NOT NULL,
        length REAL NOT NULL,
        width REAL NOT NULL,
        load_type TEXT NOT NULL,
        time_window TEXT NOT NULL,
        address TEXT NOT NULL,
        status TEXT NOT NULL,
        scheduled_date TEXT NOT NULL,
        driver_id TEXT,
        evidence_path TEXT,
        signature_path TEXT,
        incident_reason TEXT,
        delivery_time TEXT,
        FOREIGN KEY (client_id) REFERENCES clients (rut),
        FOREIGN KEY (driver_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        action TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        old_value TEXT,
        new_value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL,
        payload TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        status TEXT DEFAULT 'pending'
      )
    ''');

    // Seed default data inside a fast batch transaction
    final batch = db.batch();
    
    // Default Users (Juan Perez is Conductor, Admin is Admin)
    batch.insert('users', {
      'id': '12345678-9',
      'full_name': 'Juan Perez',
      'email': 'conductor@qubico.cl',
      'password': SecurityService.generateHash('conductor123'),
      'role': 'conductor',
      'is_active': 1
    });
    batch.insert('users', {
      'id': '98765432-1',
      'full_name': 'Admin',
      'email': 'admin@qubico.cl',
      'password': SecurityService.generateHash('admin123'),
      'role': 'admin',
      'is_active': 1
    });

    // Default Clients
    batch.insert('clients', {
      'rut': '12.345.678-9',
      'name': 'Empresa Alpha',
      'phone': '912345678',
      'email': 'contacto@alpha.cl',
      'billing_address': 'Providencia 123'
    });
    batch.insert('clients', {
      'rut': '98.765.432-1',
      'name': 'Logística Beta',
      'phone': '998765432',
      'email': 'ventas@beta.cl',
      'billing_address': 'Las Condes 456'
    });

    // Default Vehicles aligned with active Conductor names
    batch.insert('vehicles', {
      'name': 'Furgón Pequeño',
      'patente': 'AB-CD-12',
      'max_weight': 300.0,
      'driver_name': 'Juan Perez',
      'driver_id': '12345678-9',
    });
    batch.insert('vehicles', {
      'name': 'Camioneta Mediana',
      'patente': 'WX-YZ-99',
      'max_weight': 800.0,
      'driver_name': 'Conductor 2',
      'driver_id': null,
    });

    debugPrint('DEBUG QUBICO: Committing seed data batch...');
    await batch.commit(noResult: true);
    debugPrint('DEBUG QUBICO: Seed data batch committed successfully.');
  }

  // Generic methods for CRUD
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await instance.database;
    return await db.query(table);
  }

  Future<int> update(String table, Map<String, dynamic> data, String idColumn, dynamic idValue) async {
    final db = await instance.database;
    return await db.update(
      table,
      data,
      where: '$idColumn = ?',
      whereArgs: [idValue],
    );
  }

  Future<int> delete(String table, String idColumn, dynamic idValue) async {
    final db = await instance.database;
    return await db.delete(
      table,
      where: '$idColumn = ?',
      whereArgs: [idValue],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
