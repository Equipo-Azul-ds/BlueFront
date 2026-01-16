import 'package:flutter/foundation.dart';

import '../../application/dtos/report_dtos.dart';
import '../../application/use_cases/report_usecases.dart';
import '../../domain/entities/report_model.dart';
import '../../infrastructure/repositories/reports_repository_impl.dart';

/// BLoC para el listado de reportes personales.
/// Gestiona carga, refresco y paginación siguiendo el patrón usado en
/// challenge/kahoot (ChangeNotifier + Provider).
class ReportsListBloc extends ChangeNotifier {
  ReportsListBloc({required this.getMyResultsUseCase});

  final GetMyResultsUseCase getMyResultsUseCase;

  final List<ReportSummary> _items = [];
  PaginationMeta? _meta;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  List<ReportSummary> get items => List.unmodifiable(_items);
  PaginationMeta? get meta => _meta;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _items.isNotEmpty;
  bool get hasLoaded => _initialized;
  bool get canLoadMore =>
      _meta != null && _meta!.currentPage < (_meta!.totalPages);

  Future<void> loadInitial() async {
    return _load(page: 1, append: false);
  }

  Future<void> refresh() async {
    return _load(page: 1, append: false);
  }

  Future<void> loadNextPage() async {
    if (!canLoadMore || _isLoading) return;
    final nextPage = (_meta?.currentPage ?? 1) + 1;
    return _load(page: nextPage, append: true);
  }

  Future<void> _load({required int page, required bool append}) async {
    print('📄 [ReportsListBloc] Loading reports - page: $page, append: $append');
    _initialized = true;
    _isLoading = true;
    _error = null;
    if (!append) {
      _items.clear();
    }
    notifyListeners();

    try {
      final response = await getMyResultsUseCase(
        MyResultsQueryDto(page: page),
      );
      print('📄 [ReportsListBloc] Received ${response.results.length} items');
      print('📄 [ReportsListBloc] Pagination: page ${response.meta.currentPage} of ${response.meta.totalPages}');
      _meta = response.meta;
      if (append) {
        _items.addAll(response.results);
      } else {
        _items
          ..clear()
          ..addAll(response.results);
      }
      print('✅ [ReportsListBloc] Successfully loaded reports. Total items: ${_items.length}');
    } catch (e) {
      print('❌ [ReportsListBloc] Error loading reports: $e');
      // If the API returns 404 it means the user has no results yet.
      // Treat it as an empty state instead of surfacing an error.
      if (e is ReportsApiException && e.statusCode == 404) {
        _error = null;
        if (!append) {
          _items.clear();
        }
      } else {
        _error = e.toString();
        if (!append) {
          _items.clear();
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
