/// Result of a tip and bill split calculation.
class TipResult {
  final double tipAmount;
  final double totalBill;
  final double perPerson;

  const TipResult({
    required this.tipAmount,
    required this.totalBill,
    required this.perPerson,
  });
}

/// Pure domain service for Tip & Split Bill calculations.
class TipCalculatorService {
  const TipCalculatorService();

  TipResult calculate({
    required double bill,
    required double tipPercent,
    required int people,
  }) {
    final validPeople = people < 1 ? 1 : people;
    final tipAmount = bill * (tipPercent / 100.0);
    final totalBill = bill + tipAmount;
    final perPerson = totalBill / validPeople;

    return TipResult(
      tipAmount: tipAmount,
      totalBill: totalBill,
      perPerson: perPerson,
    );
  }
}
