class BoxMeasurement {
  final int? id;
  final String title;
  final double length;
  final double width;
  final double height;
  final String unit;
  final double volumeLiters;
  final double volumeM3;
  final double surfaceAreaCm2;
  final double volumetricWeightKg;
  final DateTime timestamp;

  BoxMeasurement({
    this.id,
    required this.title,
    required this.length,
    required this.width,
    required this.height,
    required this.unit,
    required this.volumeLiters,
    required this.volumeM3,
    required this.surfaceAreaCm2,
    required this.volumetricWeightKg,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'length': length,
      'width': width,
      'height': height,
      'unit': unit,
      'volumeLiters': volumeLiters,
      'volumeM3': volumeM3,
      'surfaceAreaCm2': surfaceAreaCm2,
      'volumetricWeightKg': volumetricWeightKg,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory BoxMeasurement.fromMap(Map<String, dynamic> map) {
    return BoxMeasurement(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? 'Box',
      length: (map['length'] as num).toDouble(),
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      unit: (map['unit'] as String?) ?? 'cm',
      volumeLiters: (map['volumeLiters'] as num).toDouble(),
      volumeM3: (map['volumeM3'] as num).toDouble(),
      surfaceAreaCm2: (map['surfaceAreaCm2'] as num).toDouble(),
      volumetricWeightKg: (map['volumetricWeightKg'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}
