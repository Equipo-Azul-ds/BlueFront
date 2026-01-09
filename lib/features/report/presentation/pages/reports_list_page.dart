import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/colors.dart';
import '../../domain/entities/report_model.dart';
import '../blocs/reports_list_bloc.dart';
import '../widgets/ranking_badge.dart';
import '../widgets/shimmer_loading.dart';
import 'report_detail_page.dart';

/// Pantalla estilizada para listar los reportes personales (endpoint my-results).
class ReportsListPage extends StatefulWidget {
  const ReportsListPage({super.key});

  @override
  State<ReportsListPage> createState() => _ReportsListPageState();
}

class _ReportsListPageState extends State<ReportsListPage> {
  bool _mountedLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mountedLoad) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<ReportsListBloc>();
      if (!bloc.hasLoaded) {
        bloc.loadInitial();
      }
    });
    _mountedLoad = true;
  }

  Future<void> _refresh() async {
    await context.read<ReportsListBloc>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Stack(
          children: [
            const _HeroHeader(),
            RefreshIndicator(
              onRefresh: _refresh,
              child: Consumer<ReportsListBloc>(
                builder: (context, bloc, _) {
                  if (bloc.isLoading && !bloc.hasData) {
                    return _SkeletonList();
                  }

                  if (bloc.error != null && !bloc.hasData) {
                    return _ErrorState(
                      message: 'No se pudieron cargar los reportes',
                      detail: bloc.error!,
                      onRetry: _refresh,
                    );
                  }

                  if (!bloc.isLoading && bloc.items.isEmpty) {
                    return const _EmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 180, 16, 24),
                    itemCount: bloc.items.length + (bloc.canLoadMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= bloc.items.length) {
                        bloc.loadNextPage();
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final item = bloc.items[index];
                      return _ReportCard(
                        item: item,
                        onTap: () => _openDetail(item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(ReportSummary summary) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportDetailPage(summary: summary),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.primary, AppColor.secundary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColor.onPrimary),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const Text(
                'Mis reportes',
                style: TextStyle(
                  color: AppColor.onPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Revisa tus partidas, podios y análisis por pregunta. '
            'Toca un reporte para abrir su detalle.',
            style: TextStyle(
              color: AppColor.onPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.item, this.onTap});

  final ReportSummary item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isSingle = item.gameType == GameType.singleplayer;
    final chipColor = isSingle ? AppColor.success : AppColor.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TagChip(label: isSingle ? 'Singleplayer' : 'Multiplayer', color: chipColor),
                  const SizedBox(width: 8),
                  _TagChip(label: 'Puntaje ${item.finalScore}', color: AppColor.primary),
                  if (item.rankingPosition != null) ...[
                    const SizedBox(width: 8),
                    RankingBadge(
                      position: item.rankingPosition!,
                      size: RankingBadgeSize.small,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(item.completionDate),
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const Icon(Icons.chevron_right, color: AppColor.secundary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.darken(0.1),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 180, 16, 24),
      children: const [
        SizedBox(height: 32),
        Center(
          child: Text(
            'No hay reportes disponibles',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.detail, required this.onRetry});

  final String message;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 180, 16, 24),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(detail, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 180, 16, 24),
      itemCount: 6,
      itemBuilder: (_, __) => const ReportCardSkeleton(),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        height: 64,
        width: 64,
        child: CircularProgressIndicator(strokeWidth: 5),
      ),
    );
  }
}

extension _ColorShade on Color {
  Color darken(double amount) {
    assert(amount >= 0 && amount <= 1);
    final f = 1 - amount;
    return Color.fromRGBO(
      (red * f).round(),
      (green * f).round(),
      (blue * f).round(),
      1.0,
    );
  }
}
