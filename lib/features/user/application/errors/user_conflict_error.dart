class UserConflictError implements Exception {
  final String message;

  UserConflictError([this.message = 'User already exists']);

  @override
  String toString() => 'UserConflictError: $message';
}
