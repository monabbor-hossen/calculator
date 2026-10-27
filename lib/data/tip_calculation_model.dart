class TipCalculation {
  final int? id;
  final double bill;
  final double tipPercent;
  final double tipAmount;
  final double total;
  final int people;
  final double perPerson;
  final String currency;
  final DateTime timestamp;

  TipCalculation({
    this.id,
    required this.bill,
    required this.tipPercent,
    required this.tipAmount,
    required this.total,
    required this.people,
    required this.perPerson,
    this.currency = '৳',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'bill': bill,
      'tipPercent': tipPercent,
      'tipAmount': tipAmount,
      'total': total,
      'people': people,
      'perPerson': perPerson,
      'currency': currency,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory TipCalculation.fromMap(Map<String, dynamic> map) {
    return TipCalculation(
      id: map['id'] as int?,
      bill: (map['bill'] as num).toDouble(),
      tipPercent: (map['tipPercent'] as num).toDouble(),
      tipAmount: (map['tipAmount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      people: (map['people'] as num).toInt(),
      perPerson: (map['perPerson'] as num).toDouble(),
      currency: (map['currency'] as String?) ?? '৳',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}
