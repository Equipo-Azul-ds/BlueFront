import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../common_widgets/bottom_navbar.dart';
import 'package:Trivvy/features/discovery/presentation/widget/featuredKahoots.dart';
import '../../domain/entities/theme.dart';
import '../../infraestructure/repositories/ThemeRepository.dart';
import '../widget/KahootCategory.dart';
import '../widget/KahootSearch.dart';

final kDummyThemes = [
  ThemeEntity(
    name: 'Matemáticas',
  ),
  ThemeEntity(
    name: 'Historia',
  ),
  ThemeEntity(
    name: 'Ciencia',
  ),
  ThemeEntity(
    name: 'Arte',
  ),
];


class DiscoverScreen extends StatefulWidget {
  static const routeName = '/discover';

  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {

  final TextEditingController _searchController = TextEditingController();
  //List<ThemeEntity> _themes = [];
  //bool _isLoading = true;
  List<ThemeEntity> _themes = kDummyThemes;
  bool _isLoading = false;
  String? _error;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    // Future.microtask(() => _fetchThemes());

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

  Future<void> _fetchThemes() async {
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
  }

  @override
  Widget build(BuildContext context) {
    const int discoverIndex = 1;
    final bool showSearchResults = _currentQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Find a kahoot about...',
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
              icon: Icon(Icons.search, color: Colors.white54),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        actions: [
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            if (showSearchResults)
              KahootSearch(searchTitle: _currentQuery),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FeaturedKahoots(),
                  const SizedBox(height: 20),


                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: Colors.white))
                  else if (_error != null)
                    Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                  else
                    ..._themes.map((themeEntity) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: KahootCategorySection(categoryTitle: themeEntity.name),
                        )
                    ).toList(),


                ],
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(
        currentIndex: discoverIndex,
      ),
    );
  }
}