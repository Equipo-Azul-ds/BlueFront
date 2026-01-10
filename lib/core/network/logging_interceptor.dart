import 'package:http/http.dart' as http;

// AOP: envolvemos la funcionalidad base
// para añadirle "aspectos" (logs) sin modificar la lógica del repo.
class LoggingClient extends http.BaseClient {
  final http.Client _inner;

  LoggingClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    print('>> AOP LOG [Request]: ${request.method} ${request.url}');
    final response = await _inner.send(request);
    print('<< AOP LOG [Response]: ${response.statusCode}');
    return response;
  }
}
