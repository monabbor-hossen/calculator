import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calulator/screens/box_measurement_screen.dart';

void main() {
  testWidgets('BoxMeasurementScreen renders 3D box canvas, zoom controls, and presets', (tester) async {
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

    // Tap Zoom In -> Should be 115%
    await tester.tap(find.byTooltip('Zoom In'));
    await tester.pumpAndSettle();
    expect(find.text('115%'), findsOneWidget);

    // Tap Zoom Out -> Back to 100%
    await tester.tap(find.byTooltip('Zoom Out'));
    await tester.pumpAndSettle();
    expect(find.text('100%'), findsOneWidget);

    // Tap Zoom In again, then tap Reset Zoom (100% text)
    await tester.tap(find.byTooltip('Zoom In'));
    await tester.pumpAndSettle();
    expect(find.text('115%'), findsOneWidget);
    await tester.tap(find.text('115%'));
    await tester.pumpAndSettle();
    expect(find.text('100%'), findsOneWidget);

    // Verify quick angle and fit buttons
    expect(find.text('Iso'), findsOneWidget);
    expect(find.text('Top'), findsOneWidget);
    expect(find.text('Front'), findsOneWidget);
    expect(find.text('Fit'), findsOneWidget);

    // Verify dimension labels
    expect(find.text('Length (L)'), findsOneWidget);
    expect(find.text('Width (W)'), findsOneWidget);
    expect(find.text('Height (H)'), findsOneWidget);

    // Verify initial length from passed value
    expect(find.text('50 cm'), findsOneWidget);

    // Verify conversion metrics section
    expect(find.text('TOTAL VOLUME'), findsOneWidget);
    expect(find.text('VOLUME CONVERSIONS'), findsOneWidget);
    expect(find.text('SURFACE & SHIPPING SPECS'), findsOneWidget);

    // Verify quick preset chips
    expect(find.text('Shoebox'), findsOneWidget);
    expect(find.text('Small Parcel'), findsOneWidget);
    expect(find.text('Medium Box'), findsOneWidget);

    // Tap preset 'Shoebox'
    await tester.tap(find.text('Shoebox'));
    await tester.pumpAndSettle();

    // Shoebox dimensions: 33 x 20 x 12 cm -> 33 * 20 * 12 = 7920 cm³ = 7.92 Liters
    expect(find.text('33 cm'), findsOneWidget);
    expect(find.text('20 cm'), findsOneWidget);
    expect(find.text('12 cm'), findsOneWidget);
    expect(find.text('7.92 Liters'), findsOneWidget);
  });
}
