/// DTO para paginación de resultados personales.
class MyResultsQueryDto {
  MyResultsQueryDto({this.limit = 20, this.page = 1});

  final int limit;
  final int page;
}
