import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:signature/signature.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../auth/auth_provider.dart';
import '../repositories/correspondence_repository.dart';
import '../../../core/database/local_database_service.dart';

final correspondenceRepoProvider = Provider(
  (ref) => CorrespondenceRepository(),
);

class RegisterDocumentScreen extends ConsumerStatefulWidget {
  const RegisterDocumentScreen({super.key});

  @override
  ConsumerState<RegisterDocumentScreen> createState() =>
      _RegisterDocumentScreenState();
}

class _RegisterDocumentScreenState
    extends ConsumerState<RegisterDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  // Controllers
  final _destExternoController = TextEditingController();
  final _asuntoController = TextEditingController();
  final _contenidoController = TextEditingController();

  // Signature
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  // State
  int _selectedTipo = 1;
  String _clasificacion = 'PUBLICA';
  String _prioridad = 'NORMAL';
  String _generatedCite = 'Calculando...';
  DateTime? _fechaLimite;
  dynamic _attachedFile; // Puede ser File (nativo) o Uint8List (web)
  String? _attachedFileName;
  bool _isSaving = false;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _updateCite();
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _destExternoController.dispose();
    _asuntoController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
      if (!_isOnline) {
        _generatedCite =
            'OFFLINE-TEMP-${DateTime.now().millisecondsSinceEpoch}';
      }
    });
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
      withData: true, // IMPORTANTE PARA WEB
    );

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          _attachedFile = result.files.single.bytes;
        } else {
          _attachedFile = File(result.files.single.path!);
        }
        _attachedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _updateCite() async {
    if (!_isOnline) return;
    try {
      final user = ref.read(authProvider).value;
      if (user != null) {
        final cite = await ref
            .read(correspondenceRepoProvider)
            .generateNextCite(_selectedTipo, user.sucursalId);
        if (mounted) setState(() => _generatedCite = cite);
      }
    } catch (e) {
      if (mounted) setState(() => _generatedCite = 'Error al generar CITE');
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fechaLimite = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar firma si es requerida (opcional según regla de negocio)
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe firmar el documento.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final user = ref.read(authProvider).value!;

    try {
      String? savedPath;
      String? firmaUrl;
      
      // Convertir firma a bytes (INDISPENSABLE PARA VALIDEZ)
      final signatureBytes = await _signatureController.toPngBytes();

      if (_isOnline) {
        // 1. Subir archivo adjunto (si hay)
        if (_attachedFile != null) {
          savedPath = await ref
              .read(correspondenceRepoProvider)
              .uploadFileToCloud(_attachedFile, _generatedCite);
        }
        
        // 2. Subir firma digital (si hay)
        if (signatureBytes != null) {
          firmaUrl = await ref
              .read(correspondenceRepoProvider)
              .uploadSignatureToCloud(signatureBytes, _generatedCite);
        }

        // REGISTRO ONLINE FINAL
        await ref
            .read(correspondenceRepoProvider)
            .registerCorrespondence(
              cite: _generatedCite,
              tipoId: _selectedTipo,
              remitenteId: user.id,
              destinatarioId: null,
              destinatarioExterno: _destExternoController.text,
              sucursalOrigenId: user.sucursalId,
              sucursalDestinoId: null,
              asunto: _asuntoController.text,
              contenido: _contenidoController.text,
              clasificacion: _clasificacion,
              prioridad: _prioridad,
              fechaLimite: _fechaLimite,
              filePath: savedPath,
              firmaUrl: firmaUrl,
            );
      } else {
        // REGISTRO OFFLINE (Local SQLite)
        await LocalDatabaseService().saveOfflineCorrespondence({
          'tipo_id': _selectedTipo,
          'remitente_id': user.id,
          'destinatario_externo': _destExternoController.text,
          'sucursal_origen_id': user.sucursalId,
          'asunto': _asuntoController.text,
          'contenido': _contenidoController.text,
          'clasificacion': _clasificacion,
          'prioridad': _prioridad,
          'fecha_limite': _fechaLimite?.toIso8601String(),
          'file_path': kIsWeb ? 'web_upload' : _attachedFile?.path,
          'firma_digital': signatureBytes,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_isOnline ? '¡Éxito!' : 'Guardado Offline'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isOnline ? Icons.check_circle : Icons.wifi_off_rounded,
              color: _isOnline ? Colors.green : Colors.orange,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              _isOnline
                  ? 'Documento registrado con el CITE:'
                  : 'Documento guardado localmente. Se sincronizará cuando haya conexión.',
            ),
            if (_isOnline)
              Text(
                _generatedCite,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue,
                ),
              ),
            const SizedBox(height: 20),
            if (_isOnline)
              SizedBox(
                width: 150,
                height: 150,
                child: QrImageView(
                  data: _generatedCite,
                  version: QrVersions.auto,
                ),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/');
            },
            child: const Text('Cerrar y Volver'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Correspondencia'),
        actions: [
          if (!_isOnline)
            const Chip(
              label: Text('OFFLINE', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.orange,
              avatar: Icon(Icons.wifi_off, color: Colors.white, size: 16),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: _isOnline ? Colors.blue[50] : Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: _isOnline ? Colors.blue : Colors.orange,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'CITE PRELIMINAR: $_generatedCite',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isOnline ? Colors.blue : Colors.deepOrange,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedTipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Documento',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 1,
                          child: Text('CARTA EXTERNA'),
                        ),
                        DropdownMenuItem(value: 2, child: Text('MEMORANDUM')),
                        DropdownMenuItem(value: 3, child: Text('INFORME')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedTipo = val!;
                          if (_isOnline) _generatedCite = 'Recalculando...';
                        });
                        _updateCite();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _clasificacion,
                      decoration: const InputDecoration(
                        labelText: 'Clasificación',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'PUBLICA',
                          child: Text('PÚBLICA'),
                        ),
                        DropdownMenuItem(
                          value: 'PRIVADA',
                          child: Text('PRIVADA'),
                        ),
                        DropdownMenuItem(
                          value: 'CONFIDENCIAL',
                          child: Text('CONFIDENCIAL'),
                        ),
                      ],
                      onChanged: (val) => setState(() => _clasificacion = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _destExternoController,
                decoration: const InputDecoration(
                  labelText: 'Remitente / Destinatario Externo',
                  border: OutlineInputBorder(),
                  hintText: 'Nombre de la persona o institución',
                ),
                validator: (val) =>
                    val!.isEmpty ? 'Este campo es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _asuntoController,
                decoration: const InputDecoration(
                  labelText: 'Asunto / Referencia',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val!.isEmpty ? 'El asunto es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contenidoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Resumen o Contenido',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(
                        _fechaLimite == null
                            ? 'Sin fecha límite'
                            : DateFormat('dd/MM/yyyy').format(_fechaLimite!),
                      ),
                      subtitle: const Text('Plazo de respuesta'),
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Colors.blue,
                      ),
                      onTap: _selectDate,
                      tileColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _prioridad,
                      decoration: const InputDecoration(
                        labelText: 'Prioridad',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'NORMAL',
                          child: Text('NORMAL'),
                        ),
                        DropdownMenuItem(value: 'ALTA', child: Text('ALTA')),
                        DropdownMenuItem(
                          value: 'URGENTE',
                          child: Text('URGENTE'),
                        ),
                      ],
                      onChanged: (val) => setState(() => _prioridad = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _attachedFile == null
                      ? 'Adjuntar Escaneo (Opcional)'
                      : 'Archivo: ${_attachedFileName ?? "adjunto.pdf"}',
                ),
                subtitle: const Text('PDF, JPG o PNG'),
                leading: Icon(
                  Icons.attach_file,
                  color: _attachedFile == null ? Colors.grey : Colors.green,
                ),
                tileColor: Colors.green[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onTap: _pickFile,
                trailing: _attachedFile != null
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => setState(() {
                          _attachedFile = null;
                          _attachedFileName = null;
                        }),
                      )
                    : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Firma Digital',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Signature(
                  controller: _signatureController,
                  height: 150,
                  backgroundColor: Colors.transparent,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _signatureController.clear(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar Firma'),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.save_alt),
                  label: Text(
                    _isSaving
                        ? 'GUARDANDO...'
                        : (_isOnline
                              ? 'FINALIZAR REGISTRO'
                              : 'GUARDAR OFFLINE'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isOnline ? Colors.blue : Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
