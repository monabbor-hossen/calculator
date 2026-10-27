import '../../../../data/calculation_model.dart';

abstract class CalculatorRepository {
  Future<int> insertCalculation(String expression, String result);
  Future<List<Calculation>> getAllHistory();
  Future<int> deleteCalculation(int id);
  Future<int> clearAllHistory();
}
