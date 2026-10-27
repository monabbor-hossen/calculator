import 'dart:math' as math;

/// Metrics calculated for a 3D box.
class BoxMetrics {
  final double lengthMeters;
  final double widthMeters;
  final double heightMeters;
  final double volumeM3;
  final double volumeLiters;
  final double volumeCm3;
  final double volumeFt3;
  final double volumeGal;
  final double surfaceAreaM2;
  final double surfaceAreaCm2;
  final double diagonalMeters;
  final double volumetricWeightKg;

  const BoxMetrics({
    required this.lengthMeters,
    required this.widthMeters,
    required this.heightMeters,
    required this.volumeM3,
    required this.volumeLiters,
    required this.volumeCm3,
    required this.volumeFt3,
    required this.volumeGal,
    required this.surfaceAreaM2,
    required this.surfaceAreaCm2,
    required this.diagonalMeters,
    required this.volumetricWeightKg,
  });
}

/// Pure domain service handling 3D Box calculations.
class BoxCalculatorService {
  const BoxCalculatorService();

  /// Converts a value in [unit] to meters.
  double toMeters(double val, String unit) {
    switch (unit) {
      case 'm':  return val;
      case 'cm': return val * 0.01;
      case 'mm': return val * 0.001;
      case 'in': return val * 0.0254;
      case 'ft': return val * 0.3048;
      case 'yd': return val * 0.9144;
      default:   return val * 0.01;
    }
  }

  /// Calculates complete volume, surface, diagonal, and shipping metrics.
  BoxMetrics calculateMetrics({
    required double length,
    required double width,
    required double height,
    required String unit,
  }) {
    final lMeters = toMeters(length, unit);
    final wMeters = toMeters(width, unit);
    final hMeters = toMeters(height, unit);

    final volM3 = lMeters * wMeters * hMeters;
    final volLiters = volM3 * 1000.0;
    final volCm3 = volM3 * 1000000.0;
    final volFt3 = volM3 / 0.028316846592;
    final volGal = volM3 * 264.172;

    final surfaceM2 = 2 * ((lMeters * wMeters) + (lMeters * hMeters) + (wMeters * hMeters));
    final surfaceCm2 = surfaceM2 * 10000.0;

    final diagonal = math.sqrt((lMeters * lMeters) + (wMeters * wMeters) + (hMeters * hMeters));

    // Air freight volumetric weight: (L_cm * W_cm * H_cm) / 5000
    final lCm = lMeters * 100;
    final wCm = wMeters * 100;
    final hCm = hMeters * 100;
    final volWeightKg = (lCm * wCm * hCm) / 5000;

    return BoxMetrics(
      lengthMeters: lMeters,
      widthMeters: wMeters,
      heightMeters: hMeters,
      volumeM3: volM3,
      volumeLiters: volLiters,
      volumeCm3: volCm3,
      volumeFt3: volFt3,
      volumeGal: volGal,
      surfaceAreaM2: surfaceM2,
      surfaceAreaCm2: surfaceCm2,
      diagonalMeters: diagonal,
      volumetricWeightKg: volWeightKg,
    );
  }
}
