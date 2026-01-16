import 'package:flutter/material.dart';
import '../../../discovery/domain/entities/theme.dart';
import '../../../discovery/domain/Repositories/IThemeRepositorie.dart';
import '../../../discovery/infraestructure/repositories/ThemeRepository.dart';

class CategoryManagementProvider extends ChangeNotifier {
  // Referencia al repositorio (aunque no lo usemos ahora, lo mantenemos para el futuro)
  final ThemeRepository repository;

  // --- ESTADO LOCAL (SIMULACIÓN DE BASE DE DATOS) ---
  // Lista en memoria que actuará como nuestro "backend" temporal
  List<ThemeVO> _categories = [
    ThemeVO( name: 'Matemáticas'),
    ThemeVO( name: 'Historia'),
    ThemeVO(name: 'Ciencias'),
  ];

  bool _isLoading = false;

  CategoryManagementProvider({required this.repository});

  // Getters para que la UI acceda a los datos
  List<ThemeVO> get categories => _categories;
  bool get isLoading => _isLoading;

  // --- MÉTODOS DE LÓGICA DE NEGOCIO ---

  /// Simula la carga de datos desde una API
  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners(); // Notifica a la UI que muestre el cargando

    // Simulamos un retraso de red de 1 segundo
    await Future.delayed(const Duration(seconds: 1));

    // En modo offline, no llamamos al repository.getThemes()
    // simplemente mantenemos los datos que ya tenemos en la lista privada

    _isLoading = false;
    notifyListeners(); // Notifica a la UI que ya tiene los datos
  }

  /// Simula la creación de una categoría localmente
  Future<void> createCategory(String name) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    // Creamos un nuevo objeto simulando lo que haría el backend
    final newCategory = ThemeVO(
      name: name,
    );

    _categories.add(newCategory); // Guardamos en nuestra lista local

    _isLoading = false;
    notifyListeners(); // La UI se actualizará automáticamente con el nuevo elemento
  }

  /// Simula la edición de una categoría
  Future<void> updateCategory(String id, String name) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    // Buscamos el índice del elemento y lo reemplazamos
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _categories[index] = ThemeVO(
        name: name,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Simula la eliminación de una categoría
  Future<void> deleteCategory(String id) async {
    // Aquí no solemos poner loading para que la eliminación parezca instantánea

    // Eliminamos de la lista local
    _categories.removeWhere((c) => c.id == id);

    // Notificamos para que el elemento desaparezca de la lista visual
    notifyListeners();

    print('Categoría $id eliminada localmente');
  }
}