import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../application/dtos/multiplayer_session_dtos.dart';
import '../../application/dtos/multiplayer_socket_events.dart';
import '../../domain/constants/multiplayer_events.dart';
import '../../domain/repositories/multiplayer_session_realtime.dart';
import 'base_session_manager.dart';

/// Gestiona el flujo específico de conexión de jugadores.
/// 
/// Responsabilidades:
/// - Escuchar el evento `player_connected_to_server` del servidor
/// - Emitir automáticamente `player_join` (con nickname) cuando se reciba la confirmación
/// - Mantener estado del flujo de conexión del jugador
/// 
/// Flujo esperado:
/// 1. Socket se conecta → se emite `client_ready` automáticamente (SessionConnectionManager)
/// 2. Servidor responde con `player_connected_to_server`
/// 3. Este manager emite automáticamente `player_join` con el nickname
class SessionPlayerConnectionManager extends BaseSessionManager {
  SessionPlayerConnectionManager({
    required MultiplayerSessionRealtime realtime,
  }) : super(realtime: realtime);

  PlayerConnectedToServerEvent? _playerConnectedToServerDto;
  String? _pendingNickname;

  // Getters
  PlayerConnectedToServerEvent? get playerConnectedToServerDto => _playerConnectedToServerDto;

  /// Registra listeners para el flujo de conexión del jugador.
  void registerPlayerConnectionListeners(
    void Function(Object error) onEventError,
  ) {
    registerEventListener<PlayerConnectedToServerEvent>(
      eventName: MultiplayerEvents.playerConnectedToServer,
      parser: (payload) => PlayerConnectedToServerEvent.fromJson(payload),
      handler: (event) => _handlePlayerConnectedToServer(event),
      onError: onEventError,
    );
  }

  /// Prepara el nickname para ser enviado cuando se reciba `player_connected_to_server`.
  void setPendingNickname(String nickname) {
    _pendingNickname = nickname;
  }

  /// Maneja el evento `player_connected_to_server` y emite automáticamente `player_join`.
  void _handlePlayerConnectedToServer(PlayerConnectedToServerEvent event) {
    print('[EVENT] ← RECEIVED: player_connected_to_server (status=${event.status})');
    _playerConnectedToServerDto = event;

    // Emite player_join automáticamente si hay un nickname pendiente
    if (_pendingNickname != null && _pendingNickname!.isNotEmpty) {
      _emitPlayerJoinAutomatically(_pendingNickname!);
    }

    notifyListeners();
  }

  /// Emite el evento `player_join` con el nickname almacenado.
  void _emitPlayerJoinAutomatically(String nickname) {
    try {
      print('[EVENT] → AUTO-EMIT: player_join (nickname=$nickname)');
      realtime.emitPlayerJoin(PlayerJoinPayload(nickname: nickname));
      _pendingNickname = null; // Limpia el nickname pendiente después de emitir
    } catch (error) {
      print('[EVENT] ✗ ERROR auto-emitting player_join: $error');
      rethrow;
    }
  }

  /// Limpia el evento de conexión del servidor después de procesarlo.
  void clearPlayerConnectedToServerDto() {
    _playerConnectedToServerDto = null;
    notifyListeners();
  }

  /// Reinicia el estado del manager.
  void resetPlayerConnectionState() {
    _playerConnectedToServerDto = null;
    _pendingNickname = null;
    notifyListeners();
  }

  @override
  void dispose() {
    cancelAllEventListeners();
    super.dispose();
  }
}
