class UserNotFoundError implements Exception {
  final String message;

  UserNotFoundError([this.message = 'User not found']);

  @override
  String toString() => 'UserNotFoundError: $message';
}
