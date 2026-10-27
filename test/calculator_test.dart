import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calulator/data/history_db.dart';
import 'package:calulator/logic/calculator_logic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Calculator Logic Tests', () {
    test('Addition calculation works', () {
      final logic = CalculatorLogic();
      logic.input('7');
      logic.input('+');
      logic.input('5');
      logic.input('=');
      expect(logic.display, '12');
      expect(logic.preview, '7 + 5 =');
    });

    test('Division by zero displays Error', () {
      final logic = CalculatorLogic();
      logic.input('9');
      logic.input('÷');
      logic.input('0');
      logic.input('=');
      expect(logic.display, 'Error');
    });

    test('loadValue restores display', () {
      final logic = CalculatorLogic();
      logic.loadValue('42');
      expect(logic.display, '42');
      expect(logic.preview, '');
    });

    test('backspace deletes last digit', () {
      final logic = CalculatorLogic();
      logic.input('1');
      logic.input('2');
      logic.input('3');
      expect(logic.display, '123');
      logic.backspace();
      expect(logic.display, '12');
      logic.backspace();
      expect(logic.display, '1');
      logic.backspace();
      expect(logic.display, '0');
    });

    test('paste loads numeric string', () {
      final logic = CalculatorLogic();
      logic.paste('1,250.75');
      expect(logic.display, '1250.75');
    });

    test('clearEntry clears current input while preserving operator', () {
      final logic = CalculatorLogic();
      logic.input('5');
      logic.input('+');
      logic.input('9');
      expect(logic.canClearEntry, isTrue);
      logic.input('C');
      expect(logic.display, '5 + ');
      expect(logic.activeOperator, '+');
    });
  });

  group('History SQLite DB Tests', () {
    test('insert, retrieve, delete and clear calculations', () async {
      final db = HistoryDb.instance;
      await db.clearAllHistory();

      // Insert calculations
      final id1 = await db.insertCalculation('7 + 5 =', '12');
      expect(id1, isPositive);

      final id2 = await db.insertCalculation('10 × 4 =', '40');
      expect(id2, isPositive);

      // Query history
      final history = await db.getAllHistory();
      expect(history.length, 2);
      expect(history.first.expression, '10 × 4 =');
      expect(history.first.result, '40');

      // Delete item
      await db.deleteCalculation(id2);
      final afterDelete = await db.getAllHistory();
      expect(afterDelete.length, 1);
      expect(afterDelete.first.result, '12');

      // Clear all
      await db.clearAllHistory();
      final afterClear = await db.getAllHistory();
      expect(afterClear.isEmpty, isTrue);
    });
  });
}
