/// Payload para crear una nueva sesión de juego.
class CreateSessionRequest {
  CreateSessionRequest({required this.kahootId});

  final String kahootId;

  Map<String, dynamic> toJson() {
    return {'kahootId': kahootId};
  }
}

/// Respuesta al crear sesión: PIN, token QR y datos opcionales de tema.
class CreateSessionResponse {
  CreateSessionResponse({
    required this.sessionPin,
    required this.qrToken,
    this.quizTitle,
    this.coverImageUrl,
    this.theme,
  });

  final String sessionPin;
  final String qrToken;
  final String? quizTitle;
  final String? coverImageUrl;
  final SessionThemeDto? theme;

  factory CreateSessionResponse.fromJson(Map<String, dynamic> json) {
    final pinValue = json['sessionPin'];
    final tokenValue = json['qrToken'];
    if (pinValue == null) {
      throw const FormatException('Missing "sessionPin" in response payload.');
    }
    if (tokenValue == null) {
      throw const FormatException('Missing "qrToken" in response payload.');
    }

    return CreateSessionResponse(
      sessionPin: pinValue.toString(),
      qrToken: tokenValue.toString(),
      quizTitle: json['quizTitle']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString(),
      theme: json['theme'] == null
          ? null
          : SessionThemeDto.fromJson(
              Map<String, dynamic>.from(json['theme'] as Map),
            ),
    );
  }
}

/// Tema visual asociado a la sesión (opcional).
class SessionThemeDto {
  SessionThemeDto({required this.id, required this.name, this.url});

  final String id;
  final String name;
  final String? url;

  factory SessionThemeDto.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'];
    final nameValue = json['name'];
    if (idValue == null || nameValue == null) {
      throw const FormatException('Theme payload is missing required fields.');
    }
    return SessionThemeDto(
      id: idValue.toString(),
      name: nameValue.toString(),
      url: json['url']?.toString(),
    );
  }
}

/// Resolución de QR -> PIN para unirse vía token.
class QrTokenLookupResponse {
  QrTokenLookupResponse({required this.sessionPin, this.sessionId});

  final String sessionPin;
  final String? sessionId;

  factory QrTokenLookupResponse.fromJson(Map<String, dynamic> json) {
    final pinValue = json['sessionPin'];
    if (pinValue == null) {
      throw const FormatException(
        'Missing "sessionPin" in QR lookup response.',
      );
    }
    return QrTokenLookupResponse(
      sessionPin: pinValue.toString(),
      sessionId: json['sessionId']?.toString(),
    );
  }
}

/// Payload de jugador al unirse con nickname.
class PlayerJoinPayload {
  PlayerJoinPayload({required this.nickname});

  final String nickname;

  Map<String, dynamic> toJson() => {'nickname': nickname};
}

/// Payload de respuesta enviada por jugador.
class PlayerSubmitAnswerPayload {
  PlayerSubmitAnswerPayload({
    required this.questionId,
    required this.answerIds,
    required this.timeElapsedMs,
  });

  final String questionId;
  final List<String> answerIds;
  final int timeElapsedMs;

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'answerId': answerIds,
        'timeElapsedMs': timeElapsedMs,
      };
}
