import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calulator/data/box_measurement_model.dart';
import 'package:calulator/data/history_db.dart';
import 'package:calulator/screens/box_measurement_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Box Measurement Widget & History Tests', () {
    testWidgets('renders 3D box canvas, zoom controls, presets, and history buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BoxMeasurementScreen(initialValue: '50'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title
      expect(find.text('3D Box Measurement'), findsOneWidget);

      // Verify 3D canvas interaction hint
      expect(find.text('Spin & Zoom'), findsOneWidget);

      // Verify zoom controls on 3D view
      expect(find.text('100%'), findsOneWidget);
      expect(find.byTooltip('Zoom In'), findsOneWidget);
      expect(find.byTooltip('Zoom Out'), findsOneWidget);

      // Verify History button in header
      expect(find.byTooltip('Box History'), findsOneWidget);

      // Tap Zoom In -> Should be 115%
      await tester.tap(find.byTooltip('Zoom In'));
      await tester.pumpAndSettle();
      expect(find.text('115%'), findsOneWidget);

      // Tap Zoom Out -> Back to 100%
      await tester.tap(find.byTooltip('Zoom Out'));
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);

      // Tap preset 'Shoebox'
      await tester.tap(find.text('Shoebox'));
      await tester.pumpAndSettle();

      // Shoebox dimensions: 33 x 20 x 12 cm -> 7.92 Liters
      expect(find.text('33 cm'), findsOneWidget);
      expect(find.text('20 cm'), findsOneWidget);
      expect(find.text('12 cm'), findsOneWidget);
      expect(find.text('7.92 Liters'), findsOneWidget);

      // Scroll down to 'Save Box to History'
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Save Box to History'), findsOneWidget);
    });

    test('SQLite Box History Database CRUD operations', () async {
      final db = HistoryDb.instance;
      await db.clearAllBoxHistory();

      // Insert BoxMeasurement
      final box1 = BoxMeasurement(
        title: 'Custom Storage Box',
        length: 45,
        width: 30,
        height: 25,
        unit: 'cm',
        volumeLiters: 33.75,
        volumeM3: 0.03375,
        surfaceAreaCm2: 6450,
        volumetricWeightKg: 6.75,
      );
      final id1 = await db.insertBoxMeasurement(box1);
      expect(id1, isPositive);

      final box2 = BoxMeasurement(
        title: 'Big Parcel',
        length: 60,
        width: 40,
        height: 35,
        unit: 'cm',
        volumeLiters: 84.0,
        volumeM3: 0.084,
        surfaceAreaCm2: 11800,
        volumetricWeightKg: 16.8,
      );
      final id2 = await db.insertBoxMeasurement(box2);
      expect(id2, isPositive);

      // Query list
      final history = await db.getAllBoxHistory();
      expect(history.length, 2);
      expect(history.first.title, 'Big Parcel');
      expect(history.first.volumeLiters, 84.0);

      // Delete one item
      await db.deleteBoxMeasurement(id2);
      final afterDelete = await db.getAllBoxHistory();
      expect(afterDelete.length, 1);
      expect(afterDelete.first.title, 'Custom Storage Box');

      // Clear all
      await db.clearAllBoxHistory();
      final afterClear = await db.getAllBoxHistory();
      expect(afterClear.isEmpty, isTrue);
    });
  });
}
