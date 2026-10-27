import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../features/box_measurement/domain/repositories/box_repository.dart';
import '../features/calculator/domain/repositories/calculator_repository.dart';
import '../features/tip_calculator/domain/repositories/tip_repository.dart';
import 'box_measurement_model.dart';
import 'calculation_model.dart';
import 'db_factory.dart';
import 'tip_calculation_model.dart';

class HistoryDb implements CalculatorRepository, TipRepository, BoxRepository {
  static final HistoryDb instance = HistoryDb._init();
  static Database? _database;

  HistoryDb._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('calculator_history.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    try {
      setupDatabaseFactory();
    } catch (e) {
      debugPrint('Database factory init notice: $e');
    }

    final db = await openDatabase(
      fileName,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );

    // Ensure all tables and performance indexes exist
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tip_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bill REAL NOT NULL,
          tipPercent REAL NOT NULL,
          tipAmount REAL NOT NULL,
          total REAL NOT NULL,
          people INTEGER NOT NULL,
          perPerson REAL NOT NULL,
          currency TEXT NOT NULL,
          timestamp INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS box_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          length REAL NOT NULL,
          width REAL NOT NULL,
          height REAL NOT NULL,
          unit TEXT NOT NULL,
          volumeLiters REAL NOT NULL,
          volumeM3 REAL NOT NULL,
          surfaceAreaCm2 REAL NOT NULL,
          volumetricWeightKg REAL NOT NULL,
          timestamp INTEGER NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_history_timestamp ON history (timestamp DESC)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tip_history_timestamp ON tip_history (timestamp DESC)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_box_history_timestamp ON box_history (timestamp DESC)');
    } catch (e) {
      debugPrint('Error ensuring database tables and indexes: $e');
    }

    return db;
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expression TEXT NOT NULL,
        result TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tip_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill REAL NOT NULL,
        tipPercent REAL NOT NULL,
        tipAmount REAL NOT NULL,
        total REAL NOT NULL,
        people INTEGER NOT NULL,
        perPerson REAL NOT NULL,
        currency TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS box_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        length REAL NOT NULL,
        width REAL NOT NULL,
        height REAL NOT NULL,
        unit TEXT NOT NULL,
        volumeLiters REAL NOT NULL,
        volumeM3 REAL NOT NULL,
        surfaceAreaCm2 REAL NOT NULL,
        volumetricWeightKg REAL NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_history_timestamp ON history (timestamp DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tip_history_timestamp ON tip_history (timestamp DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_box_history_timestamp ON box_history (timestamp DESC)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tip_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bill REAL NOT NULL,
          tipPercent REAL NOT NULL,
          tipAmount REAL NOT NULL,
          total REAL NOT NULL,
          people INTEGER NOT NULL,
          perPerson REAL NOT NULL,
          currency TEXT NOT NULL,
          timestamp INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS box_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          length REAL NOT NULL,
          width REAL NOT NULL,
          height REAL NOT NULL,
          unit TEXT NOT NULL,
          volumeLiters REAL NOT NULL,
          volumeM3 REAL NOT NULL,
          surfaceAreaCm2 REAL NOT NULL,
          volumetricWeightKg REAL NOT NULL,
          timestamp INTEGER NOT NULL
        )
      ''');
    }
  }

  @override
  Future<int> insertCalculation(String expression, String result) async {
    try {
      final db = await database;
      final calculation = Calculation(
        expression: expression,
        result: result,
        timestamp: DateTime.now(),
      );
      final id = await db.insert('history', calculation.toMap());
      debugPrint('Stored calculation in SQLite: $expression $result (id: $id)');
      return id;
    } catch (e) {
      debugPrint('Error inserting calculation: $e');
      return -1;
    }
  }

  @override
  Future<List<Calculation>> getAllHistory() async {
    try {
      final db = await database;
      final maps = await db.query(
        'history',
        orderBy: 'timestamp DESC',
      );
      return maps.map((e) => Calculation.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error getting history: $e');
      return [];
    }
  }

  @override
  Future<int> deleteCalculation(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'history',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleting calculation: $e');
      return 0;
    }
  }

  @override
  Future<int> clearAllHistory() async {
    try {
      final db = await database;
      return await db.delete('history');
    } catch (e) {
      debugPrint('Error clearing history: $e');
      return 0;
    }
  }

  // ── Tip & Split Bill History ─────────────────────────────────────────────
  @override
  Future<int> insertTipCalculation(TipCalculation calc) async {
    try {
      final db = await database;
      final id = await db.insert('tip_history', calc.toMap());
      debugPrint('Stored tip calculation in SQLite (id: $id): ${calc.currency}${calc.perPerson}/person');
      return id;
    } catch (e) {
      debugPrint('Error inserting tip calculation: $e');
      return -1;
    }
  }

  @override
  Future<List<TipCalculation>> getAllTipHistory() async {
    try {
      final db = await database;
      final maps = await db.query(
        'tip_history',
        orderBy: 'timestamp DESC',
      );
      return maps.map((e) => TipCalculation.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error getting tip history: $e');
      return [];
    }
  }

  @override
  Future<int> deleteTipCalculation(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'tip_history',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleting tip calculation: $e');
      return 0;
    }
  }

  @override
  Future<int> clearAllTipHistory() async {
    try {
      final db = await database;
      return await db.delete('tip_history');
    } catch (e) {
      debugPrint('Error clearing tip history: $e');
      return 0;
    }
  }

  // ── Box Measurement History ──────────────────────────────────────────────
  @override
  Future<int> insertBoxMeasurement(BoxMeasurement measurement) async {
    try {
      final db = await database;
      final id = await db.insert('box_history', measurement.toMap());
      debugPrint('Stored box measurement in SQLite (id: $id): ${measurement.title} (${measurement.length}x${measurement.width}x${measurement.height} ${measurement.unit})');
      return id;
    } catch (e) {
      debugPrint('Error inserting box measurement: $e');
      return -1;
    }
  }

  @override
  Future<List<BoxMeasurement>> getAllBoxHistory() async {
    try {
      final db = await database;
      final maps = await db.query(
        'box_history',
        orderBy: 'timestamp DESC',
      );
      return maps.map((e) => BoxMeasurement.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error getting box history: $e');
      return [];
    }
  }

  @override
  Future<int> deleteBoxMeasurement(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'box_history',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleting box measurement: $e');
      return 0;
    }
  }

  @override
  Future<int> clearAllBoxHistory() async {
    try {
      final db = await database;
      return await db.delete('box_history');
    } catch (e) {
      debugPrint('Error clearing box history: $e');
      return 0;
    }
  }
}

