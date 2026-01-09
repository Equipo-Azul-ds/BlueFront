

import 'errors/exception.dart';

class Result<T> {
  final T? _value;
  final ApplicationException? _error;

  Result._(this._value, this._error);

  bool get isSuccessful => this._value != null;
  bool get isError => this._error != null;

  ApplicationException get error => this._error!;

  T unwrap() {
    if (isSuccessful) {
      return this._value!;
    } else {
      throw this._error!;
    }
  }

  static Result<T> success<T>(T value) {
    return Result._(value, null);
  }

  static Result<T> failure<T>(ApplicationException error) {
    return Result._(null, error);
  }
}