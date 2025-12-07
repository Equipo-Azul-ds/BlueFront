import 'package:Trivvy/features/discovery/infraestructure/dataSource/ThemeRemoteDataSource.dart';
import 'package:Trivvy/features/discovery/infraestructure/repositories/ThemeRepository.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;


// Genera mocks para el Cliente HTTP y el Data Source
@GenerateMocks([http.Client, ThemeRemoteDataSource, ThemeRepository])
void main() {}