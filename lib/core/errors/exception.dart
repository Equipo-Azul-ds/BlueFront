class ApplicationException {
  final String message;
  const ApplicationException(this.message);
}

class UnauthorizedException extends ApplicationException {
  const UnauthorizedException() : super("Unauthorized");
}

class NetworkException extends ApplicationException {
  const NetworkException() : super("Network Error");
}

class ServerException extends ApplicationException {
  const ServerException({required String message}) : super("Server Error");
}

class CacheException extends ApplicationException {
  const CacheException() : super("Cache Error");
}

class UnknownException extends ApplicationException {
  const UnknownException() : super("Unknown Error");
}

class PermissionDeniedException extends ApplicationException{
  final String message;
  const PermissionDeniedException({required this.message}) : super(message);
}