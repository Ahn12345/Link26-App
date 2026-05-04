import '../../core/domain/result.dart';

abstract class ChatRepository {
  Future<Result<void>> ping();
}
