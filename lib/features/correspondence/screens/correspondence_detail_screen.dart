import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/auth_provider.dart';
import '../models/correspondence_model.dart';
import '../models/tracking_model.dart';
import '../services/pdf_service.dart';
import 'register_document_screen.dart';

class CorrespondenceDetailScreen extends ConsumerStatefulWidget {
  final CorrespondenceModel doc;
  const CorrespondenceDetailScreen({super.key, required this.doc});

  @override
  ConsumerState<CorrespondenceDetailScreen> createState() =>
      _CorrespondenceDetailScreenState();
}

class _CorrespondenceDetailScreenState
    extends ConsumerState<CorrespondenceDetailScreen> {
  late Future<List<TrackingModel>> _trackingFuture;

  @override
  void initState() {
    super.initState();
    _refreshTracking();
  }

  Future<void> _openFile() async {
    if (widget.doc.filePath == null) return;

    try {
      final String path = widget.doc.filePath!;
      final Uri uri = path.startsWith('http') 
          ? Uri.parse(path) 
          : Uri.file(path);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Si canLaunchUrl falla, intentamos lanzarlo de todos modos (algunos navegadores lo requieren)
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el documento: $e')),
        );
      }
    }
  }

  void _generateOfficialReport() async {
    await PdfService.generateOfficialPdf(widget.doc);
  }

  void _refreshTracking() {
    setState(() {
      _trackingFuture = ref
          .read(correspondenceRepoProvider)
          .getTracking(widget.doc.id);
    });
  }

  Future<void> _handleReceive() async {
    final user = ref.read(authProvider).value!;
    try {
      await ref
          .read(correspondenceRepoProvider)
          .receiveDocument(widget.doc.id, user.id);
      _refreshTracking();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento recibido con éxito')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showDeriveDialog() async {
    final users = await ref.read(correspondenceRepoProvider).getAllUsers();
    final user = ref.read(authProvider).value!;

    if (!mounted) return;

    int? selectedToUserId;
    final obsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Derivar Documento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Destinatario'),
                items: users
                    .map(
                      (u) => DropdownMenuItem(
                        value: u['id'] as int,
                        child: Text(u['nombre'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (val) =>
                    setDialogState(() => selectedToUserId = val),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: obsController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones/Instrucciones',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedToUserId == null
                  ? null
                  : () async {
                      await ref
                          .read(correspondenceRepoProvider)
                          .deriveDocument(
                            correspondenceId: widget.doc.id,
                            fromUserId: user.id,
                            toUserId: selectedToUserId!,
                            observaciones: obsController.text,
                          );
                      Navigator.pop(context);
                      _refreshTracking();
                    },
              child: const Text('Derivar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value!;
    final bool canReceive = widget.doc.estado != 'RECIBIDO';
    final bool isDestinatario = widget.doc.destinatario == user.nombreCompleto;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de CITE: ${widget.doc.cite}'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton.icon(
              onPressed: _generateOfficialReport,
              icon: const Icon(Icons.print),
              label: const Text('IMPRIMIR OFICIAL'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
              ),
            ),
          ),
          if (canReceive && isDestinatario)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton.icon(
                onPressed: _handleReceive,
                icon: const Icon(Icons.check),
                label: const Text('RECIBIR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showDeriveDialog,
              icon: const Icon(Icons.alt_route),
              label: const Text('DERIVAR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lado Izquierdo: Información General
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoSection(
                    title: 'Información del Documento',
                    children: [
                      _DetailItem(
                        label: 'Estado Actual',
                        value: widget.doc.estado,
                        isBold: true,
                        color: Colors.blue,
                      ),
                      _DetailItem(
                        label: 'Asunto',
                        value: widget.doc.asunto,
                        isBold: true,
                      ),
                      _DetailItem(label: 'Tipo', value: widget.doc.tipo),
                      _DetailItem(
                        label: 'Clasificación',
                        value: widget.doc.clasificacion,
                      ),
                      _DetailItem(
                        label: 'Prioridad',
                        value: widget.doc.prioridad,
                      ),
                      _DetailItem(
                        label: 'Fecha Emisión',
                        value: DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(widget.doc.fechaEmision),
                      ),
                      if (widget.doc.fechaLimite != null)
                        _DetailItem(
                          label: 'Fecha Límite',
                          value: DateFormat(
                            'dd/MM/yyyy',
                          ).format(widget.doc.fechaLimite!),
                          color: Colors.red,
                        ),
                      if (widget.doc.filePath != null) ...[
                        const Divider(),
                        ElevatedButton.icon(
                          onPressed: _openFile,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('VER DOCUMENTO ADJUNTO'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  _InfoSection(
                    title: 'Participantes',
                    children: [
                      _DetailItem(
                        label: 'Remitente',
                        value: widget.doc.remitente,
                      ),
                      _DetailItem(
                        label: 'Destinatario',
                        value:
                            widget.doc.destinatario ??
                            widget.doc.destinatarioExterno ??
                            'No especificado',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Lado Derecho: QR y Seguimiento
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Código de Seguimiento',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          QrImageView(data: widget.doc.cite, size: 200),
                          Text(
                            widget.doc.cite,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          // SECCIÓN DE FIRMA DIGITAL (AÑADIDA)
                          if (widget.doc.firmaUrl != null) ...[
                            const Divider(height: 32),
                            const Text(
                              'Autorización Digital',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Column(
                                children: [
                                  Image.network(
                                    widget.doc.firmaUrl!,
                                    height: 80,
                                    errorBuilder: (context, error, stackTrace) => 
                                      const Icon(Icons.error_outline, color: Colors.red),
                                  ),
                                  const Text(
                                    'FIRMADO ELECTRÓNICAMENTE',
                                    style: TextStyle(fontSize: 8, color: Colors.grey, letterSpacing: 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Línea de Tiempo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<TrackingModel>>(
                    future: _trackingFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final steps = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: steps.length,
                        itemBuilder: (context, index) {
                          final step = steps[index];
                          return _TrackingStep(
                            step: step,
                            isLast: index == steps.length - 1,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;
  const _DetailItem({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.black87,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingStep extends StatelessWidget {
  final TrackingModel step;
  final bool isLast;
  const _TrackingStep({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            if (!isLast)
              Container(width: 2, height: 40, color: Colors.green[200]),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.accion,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Por: ${step.usuarioOrigen}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                DateFormat('dd/MM HH:mm').format(step.fechaMovimiento),
                style: const TextStyle(fontSize: 11, color: Colors.blue),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
