import '../../core/domain/result.dart';

abstract class NhisRepository {
  Future<Result<void>> ping();
}
