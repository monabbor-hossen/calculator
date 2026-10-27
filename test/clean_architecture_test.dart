import 'package:flutter_test/flutter_test.dart';
import 'package:calulator/core/utils/date_formatter.dart';
import 'package:calulator/core/utils/number_formatter.dart';
import 'package:calulator/features/unit_converter/domain/services/unit_converter_service.dart';
import 'package:calulator/features/box_measurement/domain/services/box_calculator_service.dart';
import 'package:calulator/features/tip_calculator/domain/services/tip_calculator_service.dart';

void main() {
  group('Clean Architecture - UnitConverterService', () {
    const service = UnitConverterService();

    test('converts length correctly', () {
      final metersToCm = service.convert(
        category: 'Length',
        value: 2.5,
        fromUnit: 'Meter (m)',
        toUnit: 'Centimeter (cm)',
      );
      expect(metersToCm, closeTo(250.0, 0.001));

      final feetToInches = service.convert(
        category: 'Length',
        value: 1.0,
        fromUnit: 'Foot (ft)',
        toUnit: 'Inch (in)',
      );
      expect(feetToInches, closeTo(12.0, 0.001));
    });

    test('converts weight correctly', () {
      final kgToGrams = service.convert(
        category: 'Weight',
        value: 1.5,
        fromUnit: 'Kilogram (kg)',
        toUnit: 'Gram (g)',
      );
      expect(kgToGrams, closeTo(1500.0, 0.001));
    });

    test('converts temperature correctly', () {
      final cToF = service.convert(
        category: 'Temperature',
        value: 100.0,
        fromUnit: 'Celsius (°C)',
        toUnit: 'Fahrenheit (°F)',
      );
      expect(cToF, closeTo(212.0, 0.001));

      final cToK = service.convert(
        category: 'Temperature',
        value: 0.0,
        fromUnit: 'Celsius (°C)',
        toUnit: 'Kelvin (K)',
      );
      expect(cToK, closeTo(273.15, 0.001));
    });

    test('handles unknown units or same units gracefully', () {
      final fallback = service.convert(
        category: 'Unknown',
        value: 42.0,
        fromUnit: 'Foo',
        toUnit: 'Bar',
      );
      expect(fallback, equals(42.0));

      final same = service.convert(
        category: 'Length',
        value: 15.0,
        fromUnit: 'Meter (m)',
        toUnit: 'Meter (m)',
      );
      expect(same, equals(15.0));
    });
  });

  group('Clean Architecture - BoxCalculatorService', () {
    const service = BoxCalculatorService();

    test('converts dimensions to meters accurately', () {
      expect(service.toMeters(100, 'cm'), closeTo(1.0, 0.0001));
      expect(service.toMeters(1000, 'mm'), closeTo(1.0, 0.0001));
      expect(service.toMeters(1, 'm'), closeTo(1.0, 0.0001));
      expect(service.toMeters(1, 'ft'), closeTo(0.3048, 0.0001));
      expect(service.toMeters(12, 'in'), closeTo(0.3048, 0.0001));
    });

    test('calculates box metrics correctly', () {
      // 50cm x 40cm x 30cm box
      final metrics = service.calculateMetrics(
        length: 50,
        width: 40,
        height: 30,
        unit: 'cm',
      );

      // Volume = 0.5 * 0.4 * 0.3 = 0.06 m^3 = 60 Liters = 60,000 cm^3
      expect(metrics.volumeM3, closeTo(0.06, 0.0001));
      expect(metrics.volumeLiters, closeTo(60.0, 0.01));
      expect(metrics.volumeCm3, closeTo(60000.0, 0.1));

      // Surface Area = 2*(0.5*0.4 + 0.5*0.3 + 0.4*0.3) = 2*(0.2 + 0.15 + 0.12) = 0.94 m^2
      expect(metrics.surfaceAreaM2, closeTo(0.94, 0.001));

      // Diagonal = sqrt(0.5^2 + 0.4^2 + 0.3^2) = sqrt(0.25 + 0.16 + 0.09) = sqrt(0.5) ~ 0.7071 m
      expect(metrics.diagonalMeters, closeTo(0.7071, 0.001));

      // Air freight = (50 * 40 * 30) / 5000 = 60000 / 5000 = 12.0 kg
      expect(metrics.volumetricWeightKg, closeTo(12.0, 0.01));
    });
  });

  group('Clean Architecture - TipCalculatorService', () {
    const service = TipCalculatorService();

    test('calculates tip and split bill correctly', () {
      final res = service.calculate(
        bill: 100.0,
        tipPercent: 15.0,
        people: 2,
      );

      expect(res.tipAmount, closeTo(15.0, 0.001));
      expect(res.totalBill, closeTo(115.0, 0.001));
      expect(res.perPerson, closeTo(57.5, 0.001));
    });

    test('supports 0% tip correctly', () {
      final res = service.calculate(
        bill: 250.0,
        tipPercent: 0.0,
        people: 5,
      );

      expect(res.tipAmount, equals(0.0));
      expect(res.totalBill, equals(250.0));
      expect(res.perPerson, equals(50.0));
    });
  });

  group('Clean Architecture - NumberFormatter', () {
    test('formats numbers and cleans trailing zeros', () {
      expect(NumberFormatter.format(12.3456, 2), equals('12.35'));
      expect(NumberFormatter.format(12.3000, 2), equals('12.3'));
      expect(NumberFormatter.format(12.0, 2), equals('12'));
    });

    test('formats currency with exact 2 decimal places', () {
      expect(NumberFormatter.formatCurrency(12.3), equals('12.30'));
      expect(NumberFormatter.formatCurrency(0), equals('0.00'));
      expect(NumberFormatter.formatCurrency(99.99), equals('99.99'));
    });

    test('adds commas to integers and decimals', () {
      expect(NumberFormatter.addCommas('1234567'), equals('1,234,567'));
      expect(NumberFormatter.addCommas('1234567.891'), equals('1,234,567.891'));
      expect(NumberFormatter.addCommas('-987654.32'), equals('-987,654.32'));
      expect(NumberFormatter.addCommas('Error'), equals('Error'));
    });

    test('formats expression strings with token commas', () {
      expect(
        NumberFormatter.formatExpression('12345 + 67890'),
        equals('12,345 + 67,890'),
      );
    });
  });

  group('Clean Architecture - DateFormatter', () {
    test('formats relative dates accurately', () {
      final now = DateTime.now();
      expect(DateFormatter.formatRelative(now), equals('Just now'));

      final tenMinsAgo = now.subtract(const Duration(minutes: 10));
      expect(DateFormatter.formatRelative(tenMinsAgo), equals('10m ago'));
    });

    test('formats timestamp strings', () {
      final date = DateTime(2026, 10, 27, 15, 30);
      final str = DateFormatter.formatTimestamp(date);
      expect(str, contains('3:30 PM'));
    });
  });
}
