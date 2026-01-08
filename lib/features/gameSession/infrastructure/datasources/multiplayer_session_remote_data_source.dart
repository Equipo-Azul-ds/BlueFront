import 'package:dio/dio.dart';

import '../../application/dtos/multiplayer_session_dtos.dart';

typedef JwtTokenProvider = Future<String?> Function();

/// Define cómo la app habla con la API REST de sesiones multijugador.
abstract class MultiplayerSessionRemoteDataSource {
  /// Crea una sesión para un Kahoot y devuelve su PIN junto con metadatos.
  Future<CreateSessionResponse> createSession(CreateSessionRequest request);

  /// Resuelve un token QR entregado por backend a un PIN unible.
  Future<QrTokenLookupResponse> getSessionPinFromQr(String qrToken);
}

/// Implementación basada en Dio de [MultiplayerSessionRemoteDataSource].
class MultiplayerSessionRemoteDataSourceImpl
    implements MultiplayerSessionRemoteDataSource {
  MultiplayerSessionRemoteDataSourceImpl({
    required Dio dio,
    JwtTokenProvider? tokenProvider,
  })  : _dio = dio,
        _tokenProvider = tokenProvider;

  final Dio _dio;
  final JwtTokenProvider? _tokenProvider;

  @override
  Future<CreateSessionResponse> createSession(
    CreateSessionRequest request,
  ) async {
    const maxAttempts = 3;
    DioException? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await _dio.post<Map<String, dynamic>>(
          '/multiplayer-sessions',
          data: request.toJson(),
          options: await _optionsWithAuth(requireToken: true),
        );
        return CreateSessionResponse.fromJson(
          response.data ?? const <String, dynamic>{},
        );
      } on DioException catch (error) {
        lastError = error;
        final status = error.response?.statusCode;
        final shouldRetry = status == 500 && attempt < maxAttempts;
        if (!shouldRetry) {
          throw MultiplayerSessionApiException.fromDio(error);
        }
        await Future<void>.delayed(Duration(milliseconds: 200 * attempt));
      }
    }

    throw MultiplayerSessionApiException.fromDio(lastError!);
  }

  @override
  Future<QrTokenLookupResponse> getSessionPinFromQr(String qrToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/multiplayer-sessions/qr-token/$qrToken',
        options: await _optionsWithAuth(),
      );
      return QrTokenLookupResponse.fromJson(
        response.data ?? const <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw MultiplayerSessionApiException.fromDio(error);
    }
  }

  Future<Options> _optionsWithAuth({bool requireToken = false}) async {
    // Adjunta bearer token cuando existe; si es obligatorio y falta, falla.
    final headers = <String, dynamic>{};
    final token = await _tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else if (requireToken) {
      throw StateError('Se requiere un JWT válido para esta operación.');
    }
    return Options(headers: headers.isEmpty ? null : headers);
  }
}

/// Envoltura de errores HTTP para endpoints de sesiones multijugador.
class MultiplayerSessionApiException implements Exception {
  MultiplayerSessionApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory MultiplayerSessionApiException.fromDio(DioException error) {
    final response = error.response;
    final resolvedMessage = () {
      final data = response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return error.message ??
          'Unexpected error while calling multiplayer API.';
    }();
    return MultiplayerSessionApiException(
      resolvedMessage,
      statusCode: response?.statusCode,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('MultiplayerSessionApiException: $message');
    if (statusCode != null) {
      buffer.write(' (status $statusCode)');
    }
    return buffer.toString();
  }
}
