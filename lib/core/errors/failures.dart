//Aqui lo que hacemos es manejar errores de negocio
abstract class Failure {
  final String message;
  Failure(this.message);
}

//Manejamos errores en caso de que haya error con la red
class NetworkFailure extends Failure {
  NetworkFailure()
    : super('Ups! Hay un error con la red, no podemos conectarnos al servidor');
}

//Manejamos errores en caso de que haya error con la validacion de algun dato
class ValidationFailure extends Failure {
  ValidationFailure(String message) : super('Error de validacion: $message');
}

//Manejamos errores en caso de que haya errores inesperados
class UnknownFailure extends Failure {
  UnknownFailure({String? detail})
      : super('Ocurrió un error inesperado${detail != null ? ': $detail' : ''}.');
}
