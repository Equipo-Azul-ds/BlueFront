enum RealtimeStatus { idle, syncing, ready, error, closed }

/// Estado normalizado para eventos/payloads en tiempo real.
class RealtimeEventState<T> {
  const RealtimeEventState({
    required this.status,
    this.sequence,
    this.issuedAt,
    this.message,
    this.data,
  });

  final RealtimeStatus status;
  final int? sequence;
  final DateTime? issuedAt;
  final String? message;
  final T? data;

  bool get hasError => status == RealtimeStatus.error;
  bool get isClosed => status == RealtimeStatus.closed;

  RealtimeEventState<T> copyWith({
    RealtimeStatus? status,
    int? sequence,
    DateTime? issuedAt,
    String? message,
    T? data,
  }) {
    return RealtimeEventState<T>(
      status: status ?? this.status,
      sequence: sequence ?? this.sequence,
      issuedAt: issuedAt ?? this.issuedAt,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  static RealtimeEventState<T> fromPayload<T>({
    required Map<String, dynamic>? payload,
    required RealtimeStatus status,
    T? data,
  }) {
    final issuedAtRaw = payload?['issuedAt'] ?? payload?['timestamp'];
    final issuedAt = issuedAtRaw is String ? DateTime.tryParse(issuedAtRaw) : null;
    final sequence = payload?['sequence'] as int? ?? payload?['seq'] as int?;
    final message = payload?['message']?.toString();
    return RealtimeEventState<T>(
      status: status,
      sequence: sequence,
      issuedAt: issuedAt,
      message: message,
      data: data,
    );
  }
}
