import '../../core/domain/result.dart';

abstract class AuthRepository {
  Future<Result<void>> ping();
}
