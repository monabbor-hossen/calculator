import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'calculation_model.dart';
import 'db_factory.dart';
import 'tip_calculation_model.dart';

class HistoryDb {
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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );

    // Ensure tip_history table exists even if db was already created at version 1
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
    } catch (e) {
      debugPrint('Error ensuring tip_history table: $e');
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
  }

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

  Future<int> clearAllTipHistory() async {
    try {
      final db = await database;
      return await db.delete('tip_history');
    } catch (e) {
      debugPrint('Error clearing tip history: $e');
      return 0;
    }
  }
}

