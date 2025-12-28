import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SinglePlayerAttemptTracker {
  final FlutterSecureStorage secureStorage;
  static const String _keyPrefix = 'single_player_attempt_';

  const SinglePlayerAttemptTracker(this.secureStorage);

  Future<String?> readAttemptId(String quizId) async {
    final normalized = quizId.trim();
    if (normalized.isEmpty) return null;
    final stored = await secureStorage.read(key: _keyFor(normalized));
    if (stored == null) return null;
    final candidate = stored.trim();
    return candidate.isEmpty ? null : candidate;
  }

  Future<void> saveAttemptId(String quizId, String attemptId) async {
    final normalizedQuiz = quizId.trim();
    final normalizedAttempt = attemptId.trim();
    if (normalizedQuiz.isEmpty || normalizedAttempt.isEmpty) return;
    await secureStorage.write(
      key: _keyFor(normalizedQuiz),
      value: normalizedAttempt,
    );
  }

  Future<void> clearAttempt(String quizId) async {
    final normalized = quizId.trim();
    if (normalized.isEmpty) return;
    await secureStorage.delete(key: _keyFor(normalized));
  }

  String _keyFor(String quizId) => '$_keyPrefix$quizId';
}
