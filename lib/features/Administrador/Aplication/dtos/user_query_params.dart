class UserQueryParams {
  final String? q; // Término de búsqueda
  final int limit;
  final int page;
  final String? orderBy;
  final String? order; // 'asc' o 'desc'

  const UserQueryParams({
    this.q,
    this.limit = 20,
    this.page = 1,
    this.orderBy,
    this.order,
  });

  // Helper para convertir a Map<String, dynamic> para el UserDataSource.dart
  Map<String, dynamic> toMap() {
    return {
      if (q != null && q!.isNotEmpty) 'q': q,
      'limit': limit.toString(),
      'page': page.toString(),
      if (orderBy != null) 'orderBy': orderBy,
      if (order != null) 'order': order,
    };
  }
}