import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/colors.dart';
import '../../domain/entities/report_model.dart';
import '../blocs/reports_list_bloc.dart';
import '../widgets/ranking_badge.dart';
import '../widgets/shimmer_loading.dart';
import 'host_session_report_page.dart';

/// Pantalla para listar las sesiones multijugador que el usuario ha alojado como host.
/// Filtra la lista de my-results para mostrar solo las sesiones multijugador.
class HostedSessionsListPage extends StatefulWidget {
  const HostedSessionsListPage({super.key});

  @override
  State<HostedSessionsListPage> createState() => _HostedSessionsListPageState();
}

class _HostedSessionsListPageState extends State<HostedSessionsListPage> {
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
        child: Column(
          children: [
            const _HeroHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: Consumer<ReportsListBloc>(
                  builder: (context, bloc, _) {
                    if (bloc.isLoading && !bloc.hasData) {
                      return _SkeletonList();
                    }

                    if (bloc.error != null && !bloc.hasData) {
                      return _ErrorState(
                        message: 'No se pudieron cargar las sesiones',
                        detail: bloc.error!,
                        onRetry: _refresh,
                      );
                    }

                    // Filter only hosted multiplayer sessions
                    final hostedSessions = bloc.items
                        .where((item) => item.gameType == GameType.multiplayer_host)
                        .toList();

                    if (!bloc.isLoading && hostedSessions.isEmpty) {
                      return const _EmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: hostedSessions.length,
                      itemBuilder: (context, index) {
                        final session = hostedSessions[index];
                        return _SessionCard(
                          session: session,
                          onTap: () => _openHostReport(session),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openHostReport(ReportSummary session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HostSessionReportPage(
          sessionId: session.gameId,
          title: session.title,
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColor.primary,
            AppColor.accent,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: AppColor.onPrimary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Spacer(),
              const Text(
                'Sesiones Alojadas',
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
            'Revisa los informes completos de las sesiones multijugador que has alojado. '
            'Analiza el rendimiento de todos los participantes.',
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

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, this.onTap});

  final ReportSummary session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags row
                Row(
                  children: [
                    _Tag(label: 'Multijugador', color: AppColor.accent),
                    const SizedBox(width: 8),
                    if (session.rankingPosition != null)
                      RankingBadge(
                        position: session.rankingPosition!,
                        size: RankingBadgeSize.small,
                      ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  session.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Date and score row
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(session.completionDate),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: AppColor.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${session.finalScore}',
                            style: TextStyle(
                              color: AppColor.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hoy';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return 'Hace ${weeks} ${weeks == 1 ? 'semana' : 'semanas'}';
    } else {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      return '$day/$month/$year';
    }
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
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
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.groups_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              const Text(
                'No has alojado sesiones aún',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crea una sesión multijugador y compártela\ncon otros jugadores para verla aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  final String message;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                  ),
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
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => const ReportCardSkeleton(),
    );
  }
}

extension on Color {
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
