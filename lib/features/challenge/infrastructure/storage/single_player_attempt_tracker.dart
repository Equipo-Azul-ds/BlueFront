import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SinglePlayerAttemptTracker {
  final FlutterSecureStorage secureStorage;
  static const String _keyPrefix = 'single_player_attempt_';

  const SinglePlayerAttemptTracker(this.secureStorage);

  Future<String?> readAttemptId(String quizId, String userId) async {
    final normalized = quizId.trim();
    final normalizedUserId = userId.trim();
    if (normalized.isEmpty || normalizedUserId.isEmpty) return null;
    final stored = await secureStorage.read(key: _keyFor(normalized, normalizedUserId));
    if (stored == null) return null;
    final candidate = stored.trim();
    return candidate.isEmpty ? null : candidate;
  }

  Future<void> saveAttemptId(String quizId, String attemptId, String userId) async {
    final normalizedQuiz = quizId.trim();
    final normalizedAttempt = attemptId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedQuiz.isEmpty || normalizedAttempt.isEmpty || normalizedUserId.isEmpty) return;
    await secureStorage.write(
      key: _keyFor(normalizedQuiz, normalizedUserId),
      value: normalizedAttempt,
    );
  }

  Future<void> clearAttempt(String quizId, String userId) async {
    final normalized = quizId.trim();
    final normalizedUserId = userId.trim();
    if (normalized.isEmpty || normalizedUserId.isEmpty) return;
    await secureStorage.delete(key: _keyFor(normalized, normalizedUserId));
  }

  String _keyFor(String quizId, String userId) => '${_keyPrefix}${userId}_$quizId';
}
