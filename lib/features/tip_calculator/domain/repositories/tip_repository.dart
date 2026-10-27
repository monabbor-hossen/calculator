import '../../../../data/tip_calculation_model.dart';

abstract class TipRepository {
  Future<int> insertTipCalculation(TipCalculation calc);
  Future<List<TipCalculation>> getAllTipHistory();
  Future<int> deleteTipCalculation(int id);
  Future<int> clearAllTipHistory();
}
