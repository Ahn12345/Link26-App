import '../../core/domain/result.dart';

abstract class SettingsRepository {
  Future<Result<void>> ping();
}
