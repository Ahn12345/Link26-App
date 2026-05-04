import '../../core/domain/result.dart';

abstract class DurRepository {
  Future<Result<void>> ping();
}
