import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_provider.dart';
import '../models/correspondence_model.dart';
import 'register_document_screen.dart';

class CorrespondenceListScreen extends ConsumerStatefulWidget {
  final bool isInbox;
  const CorrespondenceListScreen({super.key, required this.isInbox});

  @override
  ConsumerState<CorrespondenceListScreen> createState() =>
      _CorrespondenceListScreenState();
}

class _CorrespondenceListScreenState
    extends ConsumerState<CorrespondenceListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedEstado;

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    if (user == null) return const Scaffold();

    final repo = ref.watch(correspondenceRepoProvider);

    final Future<List<CorrespondenceModel>> fetchDocuments =
        (_searchQuery.isEmpty && _selectedEstado == null)
        ? (widget.isInbox ? repo.getInbox(user.id) : repo.getOutbox(user.id))
        : repo.searchCorrespondence(
            query: _searchQuery,
            estado: _selectedEstado,
            sucursalId: user.role == 'ADMIN' ? null : user.sucursalId,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isInbox ? 'Bandeja de Entrada' : 'Correspondencia Enviada',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Buscar por CITE, Asunto o Remitente...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedEstado,
                      hint: const Text('Estado'),
                      items:
                          ['REGISTRADO', 'RECIBIDO', 'EN_TRANSITO', 'ARCHIVADO']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (val) => setState(() => _selectedEstado = val),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty || _selectedEstado != null)
                  IconButton(
                    icon: const Icon(Icons.clear_all, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                        _selectedEstado = null;
                      });
                    },
                    tooltip: 'Limpiar Filtros',
                  ),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<CorrespondenceModel>>(
        future: fetchDocuments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No se encontraron documentos con esos criterios'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return _CorrespondenceCard(doc: doc);
            },
          );
        },
      ),
    );
  }
}

class _CorrespondenceCard extends StatelessWidget {
  final CorrespondenceModel doc;
  const _CorrespondenceCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    Color priorityColor = Colors.blue;
    if (doc.prioridad == 'URGENTE') priorityColor = Colors.red;
    if (doc.prioridad == 'ALTA') priorityColor = Colors.orange;

    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Row(
          children: [
            Text(
              doc.cite,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: priorityColor),
              ),
              child: Text(
                doc.prioridad,
                style: TextStyle(
                  fontSize: 10,
                  color: priorityColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            _StatusBadge(status: doc.estado),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    doc.asunto,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (doc.fechaLimite != null)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: doc.deadlineColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: doc.deadlineColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doc.deadlineStatus,
                          style: TextStyle(
                            fontSize: 10,
                            color: doc.deadlineColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(doc.remitente, style: const TextStyle(color: Colors.grey)),
                if (doc.filePath != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.attach_file, size: 14, color: Colors.blue),
                ],
                const Spacer(),
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(doc.fechaEmision),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.push('/detail', extra: doc);
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (status == 'REGISTRADO') color = Colors.blue;
    if (status == 'RECIBIDO') color = Colors.green;
    if (status == 'EN_TRANSITO') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
