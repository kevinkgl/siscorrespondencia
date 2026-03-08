import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/api/api_client.dart';
import '../models/correspondence_model.dart';
import '../models/tracking_model.dart';

class CorrespondenceRepository {
  final ApiClient _apiClient = ApiClient();
  final _supabase = Supabase.instance.client;

  // Función para subir el archivo a la nube (Supabase Storage)
  Future<String?> uploadFileToCloud(dynamic fileSource, String cite) async {
    try {
      final String fileName = 'adjunto_${cite.replaceAll('-', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // En la web, fileSource suele ser un Uint8List o un objeto de FilePicker
      if (fileSource is File) {
        await _supabase.storage.from('documentos').upload(
          fileName,
          fileSource,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
      } else {
        // Soporte para Web (bytes)
        await _supabase.storage.from('documentos').uploadBinary(
          fileName,
          fileSource,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
      }

      final String publicUrl = _supabase.storage.from('documentos').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('Error al subir a Supabase Storage: $e');
      return null;
    }
  }

  Future<List<TrackingModel>> getTracking(int correspondenceId) async {
    const sql = '''
      SELECT s.id, u1.nombre_completo as usuario_origen_nombre, u2.nombre_completo as usuario_destino_nombre,
             s.accion, s.observaciones, s.fecha_movimiento
      FROM seguimiento s
      JOIN usuarios u1 ON s.usuario_origen_id = u1.id
      LEFT JOIN usuarios u2 ON s.usuario_destino_id = u2.id
      WHERE s.correspondence_id = \$1
      ORDER BY s.fecha_movimiento ASC
    ''';
    
    final result = await _apiClient.query(sql, params: [correspondenceId]);

    return result.map((row) => TrackingModel.fromMap(row)).toList();
  }

  Future<List<CorrespondenceModel>> getOutbox(int userId, {int? sucursalId, String? role}) async {
    String sql = '''
      SELECT c.id, c.cite_numero, t.nombre as tipo_nombre, u.nombre_completo as remitente_nombre, 
             d.nombre_completo as destinatario_nombre, c.destinatario_externo, c.asunto, 
             c.estado, c.clasificacion, c.prioridad, c.fecha_emision, c.fecha_limite, c.file_path,
             s1.nombre as sucursal_origen_nombre, s2.nombre as sucursal_destino_nombre
      FROM correspondencia c
      JOIN tipos_documento t ON c.tipo_id = t.id
      JOIN usuarios u ON c.remitente_id = u.id
      LEFT JOIN usuarios d ON c.destinatario_id = d.id
      LEFT JOIN sucursales s1 ON c.sucursal_origen_id = s1.id
      LEFT JOIN sucursales s2 ON c.sucursal_destino_id = s2.id
      WHERE 1=1
    ''';

    List<dynamic> params = [];
    
    if (role == 'ADMIN') {
      // Admin ve todo
    } else if (role == 'JEFE_AGENCIA' && sucursalId != null) {
      sql += ' AND c.sucursal_origen_id = \$1';
      params.add(sucursalId);
    } else {
      sql += ' AND c.remitente_id = \$1';
      params.add(userId);
    }

    sql += ' ORDER BY c.fecha_emision DESC';

    final result = await _apiClient.query(sql, params: params);
    return result.map((row) => CorrespondenceModel.fromMap(row)).toList();
  }

  Future<List<CorrespondenceModel>> getInbox(int userId, {int? sucursalId, String? role}) async {
    String sql = '''
      SELECT c.id, c.cite_numero, t.nombre as tipo_nombre, u.nombre_completo as remitente_nombre, 
             d.nombre_completo as destinatario_nombre, c.destinatario_externo, c.asunto, 
             c.estado, c.clasificacion, c.prioridad, c.fecha_emision, c.fecha_limite, c.file_path,
             s1.nombre as sucursal_origen_nombre, s2.nombre as sucursal_destino_nombre
      FROM correspondencia c
      JOIN tipos_documento t ON c.tipo_id = t.id
      JOIN usuarios u ON c.remitente_id = u.id
      LEFT JOIN usuarios d ON c.destinatario_id = d.id
      LEFT JOIN sucursales s1 ON c.sucursal_origen_id = s1.id
      LEFT JOIN sucursales s2 ON c.sucursal_destino_id = s2.id
      WHERE 1=1
    ''';

    List<dynamic> params = [];

    if (role == 'ADMIN') {
      // Admin ve todo
    } else if (role == 'JEFE_AGENCIA' && sucursalId != null) {
      sql += ' AND c.sucursal_destino_id = \$1';
      params.add(sucursalId);
    } else {
      sql += ' AND c.destinatario_id = \$1';
      params.add(userId);
    }

    sql += ' ORDER BY c.fecha_emision DESC';

    final result = await _apiClient.query(sql, params: params);
    return result.map((row) => CorrespondenceModel.fromMap(row)).toList();
  }

  Future<String> generateNextCite(int tipoId, int sucursalId) async {
    final year = DateTime.now().year;

    final infoResult = await _apiClient.query(
      '''
      SELECT t.prefijo, s.codigo_sucursal 
      FROM tipos_documento t, sucursales s 
      WHERE t.id = \$1 AND s.id = \$2
      ''',
      params: [tipoId, sucursalId],
    );

    final prefijo = infoResult.first['prefijo'] as String;
    final codSucursal = infoResult.first['codigo_sucursal'] as String;

    final countResult = await _apiClient.query(
      '''
      SELECT COUNT(*) + 1 as total FROM correspondencia 
      WHERE tipo_id = \$1 AND sucursal_origen_id = \$2 
      AND EXTRACT(YEAR FROM created_at) = \$3
      ''',
      params: [tipoId, sucursalId, year],
    );

    final correlativo = countResult.first['total'].toString().padLeft(4, '0');
    
    return '$prefijo-$codSucursal-$year-$correlativo';
  }

  // Función para subir la firma digital (PNG bytes) a la nube
  Future<String?> uploadSignatureToCloud(dynamic signatureBytes, String cite) async {
    try {
      final fileName = 'firma_${cite.replaceAll('-', '_')}.png';
      
      // Subir al bucket 'firmas'
      await _supabase.storage.from('firmas').uploadBinary(
        fileName,
        signatureBytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final String publicUrl = _supabase.storage.from('firmas').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('Error al subir firma a Supabase: $e');
      return null;
    }
  }

  Future<int> registerCorrespondence({
    required String cite,
    required int tipoId,
    required int remitenteId,
    required int? destinatarioId,
    required String? destinatarioExterno,
    required int sucursalOrigenId,
    required int? sucursalDestinoId,
    required String asunto,
    required String contenido,
    required String clasificacion,
    required String prioridad,
    required DateTime? fechaLimite,
    String? filePath,
    String? firmaUrl,
  }) async {
    const sql = '''
      INSERT INTO correspondencia (
        cite_numero, tipo_id, remitente_id, destinatario_id, destinatario_externo,
        sucursal_origen_id, sucursal_destino_id, asunto, contenido, 
        clasificacion, prioridad, fecha_limite, qr_data, file_path, firma_url
      ) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13, \$14, \$15)
      RETURNING id
    ''';

    final result = await _apiClient.query(
      sql,
      params: [
        cite, tipoId, remitenteId, destinatarioId, destinatarioExterno,
        sucursalOrigenId, sucursalDestinoId, asunto, contenido,
        clasificacion, prioridad, 
        fechaLimite?.toIso8601String(), // CONVERSIÓN CRÍTICA PARA WEB
        cite, filePath, firmaUrl
      ],
    );

    // FIX: Parseo robusto para evitar error "String is not a subtype of int" en Web
    final newId = int.parse(result.first['id'].toString());

    await _apiClient.query(
      '''
      INSERT INTO seguimiento (correspondence_id, usuario_origen_id, accion, observaciones)
      VALUES ($1, $2, 'REGISTRO', 'Documento registrado con adjunto digital')
      ''',
      params: [newId, remitenteId],
    );

    return newId;
  }

  Future<void> receiveDocument(int correspondenceId, int userId) async {
    await _apiClient.query(
      'UPDATE correspondencia SET estado = \$1 WHERE id = \$2',
      params: ['RECIBIDO', correspondenceId],
    );

    await _apiClient.query(
      '''
      INSERT INTO seguimiento (correspondence_id, usuario_origen_id, accion, observaciones)
      VALUES (\$1, \$2, 'RECEPCION', 'Documento marcado como recibido')
      ''',
      params: [correspondenceId, userId],
    );
  }

  Future<void> deriveDocument({
    required int correspondenceId,
    required int fromUserId,
    required int toUserId,
    required String observaciones,
  }) async {
    await _apiClient.query(
      'UPDATE correspondencia SET destinatario_id = \$1, estado = \$2 WHERE id = \$3',
      params: [toUserId, 'EN_TRANSITO', correspondenceId],
    );

    await _apiClient.query(
      '''
      INSERT INTO seguimiento (correspondence_id, usuario_origen_id, usuario_destino_id, accion, observaciones)
      VALUES (\$1, \$2, \$3, 'DERIVACION', \$4)
      ''',
      params: [correspondenceId, fromUserId, toUserId, observaciones],
    );
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final result = await _apiClient.query('SELECT id, nombre_completo as nombre FROM usuarios WHERE activo = true');
    return result;
  }

  Future<List<CorrespondenceModel>> searchCorrespondence({
    String? query,
    int? sucursalId,
    String? estado,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String sql = '''
      SELECT c.id, c.cite_numero, t.nombre as tipo_nombre, u.nombre_completo as remitente_nombre, 
             d.nombre_completo as destinatario_nombre, c.destinatario_externo, c.asunto, 
             c.estado, c.clasificacion, c.prioridad, c.fecha_emision, c.fecha_limite, c.file_path
      FROM correspondencia c
      JOIN tipos_documento t ON c.tipo_id = t.id
      JOIN usuarios u ON c.remitente_id = u.id
      LEFT JOIN usuarios d ON c.destinatario_id = d.id
      WHERE 1=1
    ''';

    List<dynamic> params = [];
    int paramCount = 1;

    if (query != null && query.isNotEmpty) {
      sql += ''' AND (
        to_tsvector('spanish', coalesce(c.asunto, '') || ' ' || coalesce(c.contenido, '')) @@ plainto_tsquery('spanish', \$\$paramCount)
        OR c.cite_numero ILIKE \$\$paramCount 
        OR u.nombre_completo ILIKE \$\$paramCount
      )''';
      params.add('%$query%'); 
      paramCount++;
    }

    if (sucursalId != null) {
      sql += ' AND (c.sucursal_origen_id = \$\$paramCount OR c.sucursal_destino_id = \$\$paramCount)';
      params.add(sucursalId);
      paramCount++;
    }

    if (estado != null) {
      sql += ' AND c.estado = \$\$paramCount';
      params.add(estado);
      paramCount++;
    }

    if (startDate != null && endDate != null) {
      sql += ' AND c.fecha_emision BETWEEN \$\$paramCount AND \$\$${paramCount + 1}';
      params.add(startDate);
      params.add(endDate);
    }

    sql += ' ORDER BY c.fecha_emision DESC LIMIT 100';

    final result = await _apiClient.query(sql, params: params);

    return result.map((row) => CorrespondenceModel.fromMap(row)).toList();
  }

  Future<Map<String, int>> getQuickStats(int userId) async {
    final result = await _apiClient.query(
      '''
      SELECT 
        COUNT(*) FILTER (WHERE destinatario_id = \$1) as recibidos,
        COUNT(*) FILTER (WHERE destinatario_id = \$1 AND estado != 'RECIBIDO') as pendientes,
        COUNT(*) FILTER (WHERE destinatario_id = \$1 AND fecha_limite < NOW() AND estado != 'RECIBIDO') as vencidos
      FROM correspondencia
      ''',
      params: [userId],
    );

    final row = result.first;
    return {
      'recibidos': int.parse(row['recibidos'].toString()),
      'pendientes': int.parse(row['pendientes'].toString()),
      'vencidos': int.parse(row['vencidos'].toString()),
    };
  }

  Future<List<Map<String, dynamic>>> getGlobalStats() async {
    final result = await _apiClient.query(
      '''
      SELECT s.nombre as label, COUNT(c.id) as value
      FROM sucursales s
      LEFT JOIN correspondencia c ON s.id = c.sucursal_origen_id
      GROUP BY s.nombre
      '''
    );
    return result;
  }

  Future<List<TrackingModel>> getGlobalAuditLog() async {
    const sql = '''
      SELECT s.id, u1.nombre_completo as usuario_origen_nombre, u2.nombre_completo as usuario_destino_nombre,
             s.accion, s.observaciones, s.fecha_movimiento
      FROM seguimiento s
      JOIN usuarios u1 ON s.usuario_origen_id = u1.id
      LEFT JOIN usuarios u2 ON s.usuario_destino_id = u2.id
      ORDER BY s.fecha_movimiento DESC
      LIMIT 200
    ''';
    
    final result = await _apiClient.query(sql);
    return result.map((row) => TrackingModel.fromMap(row)).toList();
  }
}
