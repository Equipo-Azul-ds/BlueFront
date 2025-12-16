import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trivvy/features/discovery/presentation/widget/featuredKahoots.dart';
import '../../domain/entities/theme.dart';
import '../../infraestructure/repositories/ThemeRepository.dart';
import '../widget/KahootCategory.dart';
import '../widget/KahootSearch.dart';
import '../../../../core/constants/colors.dart';


class DiscoverScreen extends StatefulWidget {
  static const routeName = '/discover';

  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {

  final TextEditingController _searchController = TextEditingController();
  List<ThemeVO> _themes = [];
  bool _isLoading = true;
  String? _error;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    // Iniciar la carga de datos
    Future.microtask(() => _fetchThemes());
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }


  void _onSearchChanged() {
    final newQuery = _searchController.text.trim();
    if (_currentQuery != newQuery) {
      setState(() {
        _currentQuery = newQuery;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _currentQuery = '';
    });
  }

  Future<void> _fetchThemes() async {
    // Implementación del fetchThemes (mantener tu lógica original)
    try{
      // Asegúrate de que ThemeRepository esté disponible
      final ThemeRepository repository = context.read<ThemeRepository>();
      final result = await repository.getThemes();

      result.fold(
            (failure) {
          if(mounted) {
            setState(() {
              _error = 'Error al cargar los temas: ${failure.runtimeType}';
              _isLoading = false;
            });
          }
        },
            (themes) {
          if(mounted) {
            setState(() {
              _themes = themes;
              _isLoading = false;
            });
          }
        },
      );
    }catch (e) {
      print('Error en _fetchThemes: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool showSearchResults = _searchController.text.trim().isNotEmpty;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColor.primary,
                AppColor.primary,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          // *** MANEJO DEL SAFEA AREA SUPERIOR ***
          // Añade el padding de la barra de estado + 8.0 para un espacio correcto
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8.0,
            bottom: 8.0,
            left: 16.0,
            right: 16.0,
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar Kahoots',
              hintStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              filled: true,
              fillColor: Colors.white.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: _clearSearch,
              )
                  : null,
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),

        // 2. Contenido Desplazable (Resto de la Pantalla)
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Si hay búsqueda, mostrar solo resultados
                  if (showSearchResults)
                    KahootSearch(searchTitle: _currentQuery)
                  // Si no hay búsqueda, mostrar contenido principal
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FeaturedKahoots(),
                        const SizedBox(height: 20),

                        // Manejo de estado
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator(color: AppColor.primary))
                        else if (_error != null)
                          Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                        else
                          ..._themes.map((themeEntity) =>
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                // Asumo que KahootCategorySection es tu KahootCategory
                                child: KahootCategorySection(categoryTitle: themeEntity.name),
                              )
                          ).toList(),
                      ],
                    ),

                  const SizedBox(height: 100), // Padding inferior
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}