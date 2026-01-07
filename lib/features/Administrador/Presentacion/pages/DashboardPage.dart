import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/DashboardProvider.dart';
import '../../../../core/constants/colors.dart';


class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Carga los datos automáticamente al entrar a la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: AppColor.background, // Fondo oscuro de tu app
      appBar: AppBar(
        title: const Text('Dashboard Administrativo'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadDashboardData(),
          )
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => provider.loadDashboardData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Text(
                  "Resumen General",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              // Sección de Tarjetas de Métricas
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    'Total Usuarios',
                    provider.totalUsers.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Nuevos usuarios (7d)',
                    '+${provider.newUsersCount}',
                    Icons.trending_up,
                    Colors.green,
                    subtitle: 'Crecimiento semanal',
                  ),
                  _buildStatCard(
                    'Total Quizzes',
                    provider.totalQuizzes.toString(),
                    Icons.quiz,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Kahoots Nuevos',
                    '+${provider.newKahootsCount}',
                    Icons.auto_awesome, // Un icono que resalte lo nuevo
                    Colors.purple,
                    subtitle: 'Última semana',
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Sección de Categorías Populares
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Categorías más Populares",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              provider.categoryPopularity.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No hay datos de categorías disponibles"),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.categoryPopularity.length > 5
                    ? 5
                    : provider.categoryPopularity.length,
                itemBuilder: (context, index) {
                  final entry = provider.categoryPopularity.entries.elementAt(index);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColor.card,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        entry.key,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      trailing: Text(
                        '${entry.value} Kahoots',
                        style: TextStyle(color: Colors.grey.shade600), // Usando el gris oscuro que pediste
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              if (subtitle != null)
                const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}