import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../auth/auth_provider.dart';
import '../correspondence/repositories/correspondence_repository.dart';
import '../../core/services/notification_service.dart';

final correspondenceRepoProvider = Provider(
  (ref) => CorrespondenceRepository(),
);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  void _initNotifications() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      authState.whenData((user) {
        if (user != null) {
          NotificationService().startListening(user.id);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          Future.microtask(() => context.go('/login'));
          return const Scaffold();
        }

        final statsFuture = ref
            .watch(correspondenceRepoProvider)
            .getQuickStats(user.id);
        final globalStatsFuture = ref
            .watch(correspondenceRepoProvider)
            .getGlobalStats();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Sistema de Correspondencia'),
            elevation: 2,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(child: Text('Hola, ${user.nombreCompleto}')),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(user.nombreCompleto),
                  accountEmail: Text('${user.role} | ${user.sucursal}'),
                  currentAccountPicture: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.blue),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.move_to_inbox),
                  title: const Text('Bandeja de Entrada'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/inbox');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.send),
                  title: const Text('Correspondencia Enviada'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/outbox');
                  },
                ),
                if (user.role == 'ADMIN' || user.role == 'VENTANILLA') ...[
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8),
                    child: Text(
                      'GESTIÓN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_box),
                    title: const Text('Registrar Documento'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/register');
                    },
                  ),
                ],
                if (user.role == 'ADMIN') ...[
                  ListTile(
                    leading: const Icon(Icons.analytics),
                    title: const Text('Auditoría y Reportes'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/reports');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_alt),
                    title: const Text('Gestión de Usuarios'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/users');
                    },
                  ),
                ],
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel de Control - ${user.sucursal}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                FutureBuilder<Map<String, int>>(
                  future: statsFuture,
                  builder: (context, snapshot) {
                    final stats =
                        snapshot.data ??
                        {'recibidos': 0, 'pendientes': 0, 'vencidos': 0};
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _StatCard(
                          title: 'Recibidos',
                          count: stats['recibidos'].toString(),
                          color: Colors.blue,
                          icon: Icons.move_to_inbox,
                        ),
                        _StatCard(
                          title: 'Pendientes',
                          count: stats['pendientes'].toString(),
                          color: Colors.orange,
                          icon: Icons.hourglass_empty,
                        ),
                        _StatCard(
                          title: 'Vencidos',
                          count: stats['vencidos'].toString(),
                          color: Colors.red,
                          icon: Icons.warning_amber_rounded,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: isWide ? 2 : 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Flujo por Sucursal',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 300,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: FutureBuilder<List<Map<String, dynamic>>>(
                                  future: globalStatsFuture,
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    final data = snapshot.data!;
                                    return BarChart(
                                      BarChartData(
                                        borderData: FlBorderData(show: false),
                                        titlesData: FlTitlesData(
                                          leftTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 30,
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                if (value.toInt() <
                                                    data.length) {
                                                  final label =
                                                      data[value
                                                              .toInt()]['label']
                                                          .toString();
                                                  return Text(
                                                    label.length > 3
                                                        ? label.substring(0, 3)
                                                        : label,
                                                  );
                                                }
                                                return const Text('');
                                              },
                                            ),
                                          ),
                                          rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                          topTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                        ),
                                        barGroups: data.asMap().entries.map((
                                          e,
                                        ) {
                                          final rawValue = e.value['value'];
                                          final double yValue = rawValue is num 
                                              ? rawValue.toDouble() 
                                              : double.tryParse(rawValue.toString()) ?? 0.0;
                                          
                                          return BarChartGroupData(
                                            x: e.key,
                                            barRods: [
                                              BarChartRodData(
                                                toY: yValue,
                                                color: Colors.blue,
                                                width: 20,
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isWide) const SizedBox(width: 24),
                        if (!isWide) const SizedBox(height: 40),
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Accesos Rápidos',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Column(
                                children: [
                                  if (user.role == 'ADMIN' ||
                                      user.role == 'VENTANILLA')
                                    _QuickActionButton(
                                      label: 'Nueva Correspondencia',
                                      icon: Icons.add_circle_outline,
                                      color: Colors.blue,
                                      onTap: () => context.push('/register'),
                                    ),
                                  const SizedBox(height: 12),
                                  _QuickActionButton(
                                    label: 'Ver mi Bandeja',
                                    icon: Icons.mark_email_unread_outlined,
                                    color: Colors.green,
                                    onTap: () => context.push('/inbox'),
                                  ),
                                  const SizedBox(height: 12),
                                  if (user.role == 'ADMIN') ...[
                                    _QuickActionButton(
                                      label: 'Gestión de Usuarios',
                                      icon: Icons.people_outline,
                                      color: Colors.purple,
                                      onTap: () => context.push('/users'),
                                    ),
                                    const SizedBox(height: 12),
                                    _QuickActionButton(
                                      label: 'Reportes Globales',
                                      icon: Icons.bar_chart_outlined,
                                      color: Colors.orange,
                                      onTap: () => context.push('/reports'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        width: 200,
        constraints: const BoxConstraints(minHeight: 150),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          // ignore: deprecated_member_use
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
