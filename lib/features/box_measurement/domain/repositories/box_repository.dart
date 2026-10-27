import '../../../../data/box_measurement_model.dart';

abstract class BoxRepository {
  Future<int> insertBoxMeasurement(BoxMeasurement measurement);
  Future<List<BoxMeasurement>> getAllBoxHistory();
  Future<int> deleteBoxMeasurement(int id);
  Future<int> clearAllBoxHistory();
}
