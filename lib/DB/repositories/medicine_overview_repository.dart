import '../../core/domain/result.dart';

abstract class MedicineOverviewRepository {
  Future<Result<void>> ping();
}
