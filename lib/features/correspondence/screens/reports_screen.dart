import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/tracking_model.dart';
import 'register_document_screen.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(correspondenceRepoProvider);
    final auditFuture = repo.getGlobalAuditLog();
    final statsFuture = repo.getGlobalStats();

    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Auditoría y Reportes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas Nacionales',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(flex: 1, child: _ChartCard(statsFuture: statsFuture)),
                const SizedBox(width: 24),
                const Expanded(flex: 2, child: _AuditSection()),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Registro Global de Movimientos (Auditoría)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<TrackingModel>>(
              future: auditFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final logs = snapshot.data!;
                return Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text('Fecha')),
                        DataColumn(label: Text('Usuario')),
                        DataColumn(label: Text('Acción')),
                        DataColumn(label: Text('Detalle')),
                      ],
                      rows: logs
                          .map(
                            (log) => DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    DateFormat(
                                      'dd/MM HH:mm',
                                    ).format(log.fechaMovimiento),
                                  ),
                                ),
                                DataCell(Text(log.usuarioOrigen)),
                                DataCell(
                                  Text(
                                    log.accion,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(Text(log.observaciones ?? '-')),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> statsFuture;
  const _ChartCard({required this.statsFuture});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Distribución por Sucursal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: statsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final data = snapshot.data!;
                  return PieChart(
                    PieChartData(
                      sections: data.asMap().entries.map<PieChartSectionData>((
                        e,
                      ) {
                        return PieChartSectionData(
                          value:
                              double.tryParse(e.value['value'].toString()) ??
                              0.0,
                          title: '${e.value['label']}\n(${e.value['value']})',
                          radius: 80,
                          color:
                              Colors.primaries[e.key % Colors.primaries.length],
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
    );
  }
}

class _AuditSection extends StatelessWidget {
  const _AuditSection();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de Cumplimiento',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _SummaryItem(
              label: 'Trazabilidad',
              value: '100%',
              color: Colors.green,
            ),
            _SummaryItem(
              label: 'Uso de CITE Automático',
              value: 'Activo',
              color: Colors.blue,
            ),
            _SummaryItem(
              label: 'Digitalización',
              value: 'Requerida',
              color: Colors.orange,
            ),
            _SummaryItem(
              label: 'Respaldo DB',
              value: 'Cada 24h',
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
