import 'dart:async';
import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../domain/constants/multiplayer_constants.dart';
import '../../domain/repositories/multiplayer_session_realtime.dart';

/// Capa delgada sobre `socket_io_client` que estandariza headers de auth,
/// ciclo de vida y normalización de payloads para el namespace multijugador.
class MultiplayerSocketClient {
  MultiplayerSocketClient({
    required String baseUrl,
    MultiplayerJwtProvider? defaultTokenProvider,
  })  : _baseUrl = baseUrl,
        _defaultTokenProvider = defaultTokenProvider;

  final String _baseUrl;
  final MultiplayerJwtProvider? _defaultTokenProvider;
  final StreamController<MultiplayerSocketStatus> _statusController =
      StreamController<MultiplayerSocketStatus>.broadcast();
  final StreamController<Object> _errorController =
      StreamController<Object>.broadcast();
  final Map<String, StreamController<dynamic>> _eventControllers = {};

  io.Socket? _socket;

  Stream<MultiplayerSocketStatus> get statusStream => _statusController.stream;
  Stream<Object> get errors => _errorController.stream;
  bool get isConnected => _socket?.connected == true;

  /// Abre el socket con los parámetros dados, aplica timeout de handshake y
  /// emite cambios de estado durante el proceso.
  Future<void> connect(MultiplayerSocketParams params) async {
    await disconnect();
    _statusController.add(MultiplayerSocketStatus.connecting);

    final token = params.jwt ?? await _defaultTokenProvider?.call();
    if (token == null || token.isEmpty) {
      _statusController.add(MultiplayerSocketStatus.error);
      throw StateError(MultiplayerConstants.errorMissingJwt);
    }
    final sanitizedToken = token.trim();
    if (sanitizedToken.isEmpty) {
      _statusController.add(MultiplayerSocketStatus.error);
      throw StateError(MultiplayerConstants.errorMissingJwt);
    }

    final target = _buildNamespaceUrl();
    final authHeaderValue = 'Bearer $sanitizedToken';
    final headers = {
      MultiplayerConstants.headerPin: params.pin,
      MultiplayerConstants.headerRole: params.role.toHeaderValue(),
      MultiplayerConstants.headerJwt: sanitizedToken,
      MultiplayerConstants.headerAuthorization: authHeaderValue,
      MultiplayerConstants.headerAuthorizationLower: authHeaderValue,
    };
    final options = io.OptionBuilder()
        .setTransports(MultiplayerConstants.socketTransports)
        .enableForceNew()
        .disableAutoConnect()
        .setExtraHeaders(headers)
        .build();

    final socket = io.io(target, options);
    _socket = socket;

    final completer = Completer<void>();
    Timer? timeoutTimer;
    var completedHandshake = false;

    void completeSuccess() {
      if (completedHandshake) return;
      completedHandshake = true;
      timeoutTimer?.cancel();
      completer.complete();
    }

    void completeError(Object error) {
      if (completedHandshake) return;
      completedHandshake = true;
      timeoutTimer?.cancel();
      completer.completeError(error);
    }

    socket.onConnect((_) {
      _statusController.add(MultiplayerSocketStatus.connected);
      completeSuccess();
    });
    socket.onDisconnect((_) {
      _statusController.add(MultiplayerSocketStatus.disconnected);
    });
    socket.onReconnect((_) {
      _statusController.add(MultiplayerSocketStatus.connected);
    });
    socket.onReconnectAttempt((_) {
      _statusController.add(MultiplayerSocketStatus.connecting);
    });
    void handleConnectError(dynamic error) {
      _handleError(error);
      try {
        socket.disconnect();
        socket.close();
      } catch (_) {}
      _socket = null;
      completeError(
        error ?? StateError('No fue posible conectar con la sala.'),
      );
    }

    socket.onConnectError(handleConnectError);
    socket.on('connect_timeout', (_) {
      handleConnectError(TimeoutException('Tiempo de conexión agotado.'));
    });
    socket.onError(_handleError);
    socket.onAny((event, data) {
      final controller = _eventControllers[event];
      if (controller != null && !controller.isClosed) {
        controller.add(_normalizePayload(data));
      }
    });

    socket.connect();
    timeoutTimer = Timer(const Duration(seconds: 10), () {
      handleConnectError(TimeoutException('Tiempo de conexión agotado.'));
    });
    await completer.future;
  }

  /// Cierra el socket de forma segura y emite estado desconectado.
  Future<void> disconnect() async {
    if (_socket == null) {
      return;
    }
    try {
      _socket!.disconnect();
      _socket!.close();
    } catch (_) {
      // ignore errors on close
    }
    _socket = null;
    _statusController.add(MultiplayerSocketStatus.disconnected);
  }

  /// Se suscribe a eventos del servidor por nombre y castea el payload al tipo
  /// esperado por el consumidor.
  Stream<T> listenToEvent<T>(String eventName) {
    final controller = _eventControllers.putIfAbsent(
      eventName,
      () => StreamController<dynamic>.broadcast(),
    );
    return controller.stream.map((event) => event as T);
  }

  /// Emite un evento del cliente con payload opcional.
  void emit(String eventName, [dynamic payload]) {
    if (_socket == null) {
      throw StateError('Socket is not connected. Unable to emit "$eventName".');
    }
    _socket!.emit(eventName, payload);
  }

  /// Libera todos los controllers y desconecta el socket subyacente.
  void dispose() {
    disconnect();
    for (final controller in _eventControllers.values) {
      controller.close();
    }
    _eventControllers.clear();
    _statusController.close();
    _errorController.close();
  }

  void _handleError(dynamic error) {
    _statusController.add(MultiplayerSocketStatus.error);
    if (!_errorController.isClosed) {
      _errorController.add(error ?? 'Unknown socket error');
    }
  }

  /// Construye la URL del namespace para conexiones multijugador.
  String _buildNamespaceUrl() {
    final trimmedBase = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    return '$trimmedBase/multiplayer-sessions';
  }

  /// Convierte recursivamente payloads dinámicos a estructuras JSON cuando es
  /// posible, dejando primitivas intactas.
  dynamic _normalizePayload(dynamic payload) {
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    if (payload is List) {
      return payload.map(_normalizePayload).toList();
    }
    if (payload is String) {
      final trimmed = payload.trim();
      final looksLikeJson =
          (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'));
      if (looksLikeJson) {
        try {
          return jsonDecode(trimmed);
        } catch (_) {
          return payload;
        }
      }
    }
    return payload;
  }
}
