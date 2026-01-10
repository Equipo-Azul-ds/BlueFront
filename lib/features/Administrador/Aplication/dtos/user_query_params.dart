// features/Administrador/Aplication/dtos/user_query_params.dart

class UserQueryParams {
  final String? name;   // Cambiado de 'q' a 'name'
  final String? userId; // Agregado userId
  final int limit;
  final int page;
  final String? orderBy;
  final String? order;

  const UserQueryParams({
    this.name,
    this.userId,
    this.limit = 20,
    this.page = 1,
    this.orderBy = 'createdAt', // Valor por defecto según doc
    this.order = 'asc',        // Valor por defecto según doc
  });

  Map<String, dynamic> toMap() {
    return {
      if (name != null && name!.isNotEmpty) 'name': name,
      if (userId != null && userId!.isNotEmpty) 'userId': userId,
      'limit': limit,
      'page': page,
      if (orderBy != null) 'orderBy': orderBy,
      if (order != null) 'order': order,
    };
  }
}