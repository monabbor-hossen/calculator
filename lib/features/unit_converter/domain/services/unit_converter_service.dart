/// Pure domain service handling unit conversions for Length, Weight, Temperature, Speed, Area, and Volume.
class UnitConverterService {
  const UnitConverterService();

  static const Map<String, List<String>> categoriesWithUnits = {
    'Length': [
      'Meter (m)', 'Kilometer (km)', 'Centimeter (cm)', 'Millimeter (mm)',
      'Foot (ft)', 'Inch (in)', 'Mile (mi)', 'Yard (yd)',
    ],
    'Weight': [
      'Kilogram (kg)', 'Gram (g)', 'Pound (lb)', 'Ounce (oz)', 'Ton (t)',
    ],
    'Temperature': [
      'Celsius (°C)', 'Fahrenheit (°F)', 'Kelvin (K)',
    ],
    'Speed': [
      'km/h', 'mph', 'm/s', 'Knot (kn)',
    ],
    'Area': [
      'Sq Meter (m²)', 'Sq Km (km²)', 'Sq Foot (ft²)', 'Acre (ac)', 'Hectare (ha)',
    ],
  };

  /// Converts a value from one unit to another within a given category.
  double convert({
    required String category,
    required double value,
    required String fromUnit,
    required String toUnit,
  }) {
    if (fromUnit == toUnit) return value;

    switch (category) {
      case 'Length':
        return _convertLength(value, fromUnit, toUnit);
      case 'Weight':
        return _convertWeight(value, fromUnit, toUnit);
      case 'Temperature':
        return _convertTemperature(value, fromUnit, toUnit);
      case 'Speed':
        return _convertSpeed(value, fromUnit, toUnit);
      case 'Area':
        return _convertArea(value, fromUnit, toUnit);
      default:
        return value;
    }
  }

  double _convertLength(double val, String from, String to) {
    const toMeters = {
      'Meter (m)': 1.0,
      'Kilometer (km)': 1000.0,
      'Centimeter (cm)': 0.01,
      'Millimeter (mm)': 0.001,
      'Foot (ft)': 0.3048,
      'Inch (in)': 0.0254,
      'Mile (mi)': 1609.344,
      'Yard (yd)': 0.9144,
    };
    final meters = val * (toMeters[from] ?? 1.0);
    return meters / (toMeters[to] ?? 1.0);
  }

  double _convertWeight(double val, String from, String to) {
    const toKg = {
      'Kilogram (kg)': 1.0,
      'Gram (g)': 0.001,
      'Pound (lb)': 0.453592,
      'Ounce (oz)': 0.0283495,
      'Ton (t)': 1000.0,
    };
    final kg = val * (toKg[from] ?? 1.0);
    return kg / (toKg[to] ?? 1.0);
  }

  double _convertTemperature(double val, String from, String to) {
    // Normalize to Celsius
    double celsius;
    if (from == 'Celsius (°C)') {
      celsius = val;
    } else if (from == 'Fahrenheit (°F)') {
      celsius = (val - 32) * 5 / 9;
    } else {
      celsius = val - 273.15;
    }

    // Convert Celsius to Target
    if (to == 'Celsius (°C)') return celsius;
    if (to == 'Fahrenheit (°F)') return (celsius * 9 / 5) + 32;
    return celsius + 273.15;
  }

  double _convertSpeed(double val, String from, String to) {
    const toKmh = {
      'km/h': 1.0,
      'mph': 1.60934,
      'm/s': 3.6,
      'Knot (kn)': 1.852,
    };
    final kmh = val * (toKmh[from] ?? 1.0);
    return kmh / (toKmh[to] ?? 1.0);
  }

  double _convertArea(double val, String from, String to) {
    const toSqMeters = {
      'Sq Meter (m²)': 1.0,
      'Sq Km (km²)': 1000000.0,
      'Sq Foot (ft²)': 0.092903,
      'Acre (ac)': 4046.86,
      'Hectare (ha)': 10000.0,
    };
    final sqm = val * (toSqMeters[from] ?? 1.0);
    return sqm / (toSqMeters[to] ?? 1.0);
  }
}
