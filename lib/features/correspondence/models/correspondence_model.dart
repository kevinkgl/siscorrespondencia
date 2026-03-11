import 'package:flutter/material.dart';

class CorrespondenceModel {
  final int id;
  final String cite;
  final String tipo;
  final String remitente;
  final String? destinatario;
  final String? destinatarioExterno;
  final String asunto;
  final String? contenido;
  final String estado;
  final String clasificacion;
  final String prioridad;
  final DateTime fechaEmision;
  final DateTime? fechaLimite;
  final String? filePath;
  final String? sucursalOrigen;
  final String? sucursalDestino;
  final String? firmaUrl;

  CorrespondenceModel({
    required this.id,
    required this.cite,
    required this.tipo,
    required this.remitente,
    this.destinatario,
    this.destinatarioExterno,
    required this.asunto,
    this.contenido,
    required this.estado,
    required this.clasificacion,
    required this.prioridad,
    required this.fechaEmision,
    this.fechaLimite,
    this.filePath,
    this.sucursalOrigen,
    this.sucursalDestino,
    this.firmaUrl,
  });

  factory CorrespondenceModel.fromMap(Map<String, dynamic> map) {
    try {
      // Función auxiliar para parsear fechas de forma segura
      DateTime? parseDate(dynamic value) {
        if (value == null) return null;
        if (value is DateTime) return value;
        if (value is String) return DateTime.tryParse(value);
        return null;
      }

      return CorrespondenceModel(
        id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
        cite: map['cite_numero']?.toString() ?? 'SIN-CITE',
        tipo: map['tipo_nombre']?.toString() ?? 'DOCUMENTO',
        remitente: map['remitente_nombre']?.toString() ?? 'REMITENTE DESCONOCIDO',
        destinatario: map['destinatario_nombre']?.toString(),
        destinatarioExterno: map['destinatario_externo']?.toString(),
        asunto: map['asunto']?.toString() ?? '(Sin Asunto)',
        contenido: map['contenido']?.toString(),
        estado: map['estado']?.toString() ?? 'REGISTRADO',
        clasificacion: map['clasificacion']?.toString() ?? 'PUBLICA',
        prioridad: map['prioridad']?.toString() ?? 'NORMAL',
        fechaEmision: parseDate(map['fecha_emision']) ?? DateTime.now(),
        fechaLimite: parseDate(map['fecha_limite']),
        filePath: map['file_path']?.toString(),
        sucursalOrigen: map['sucursal_origen_nombre']?.toString(),
        sucursalDestino: map['sucursal_destino_nombre']?.toString(),
        firmaUrl: map['firma_url']?.toString(),
      );
    } catch (e) {
      print('Error al mapear CorrespondenceModel: $e');
      // Devolver un modelo de error básico para no romper la lista entera
      return CorrespondenceModel(
        id: 0,
        cite: 'ERROR',
        tipo: 'ERROR',
        remitente: 'ERROR',
        asunto: 'Error al cargar este registro',
        estado: 'ERROR',
        clasificacion: 'ERROR',
        prioridad: 'NORMAL',
        fechaEmision: DateTime.now(),
      );
    }
  }

  String get deadlineStatus {
    if (fechaLimite == null) return 'SIN PLAZO';
    final now = DateTime.now();
    final difference = fechaLimite!.difference(now);

    if (difference.isNegative) return 'VENCIDO';
    if (difference.inHours <= 24) return 'URGENTE (24h)';
    if (difference.inDays <= 3) return 'PRÓXIMO (3d)';
    return 'EN PLAZO';
  }

  Color get deadlineColor {
    if (fechaLimite == null) return Colors.grey;
    final status = deadlineStatus;
    if (status == 'VENCIDO') return Colors.red;
    if (status == 'URGENTE (24h)') return Colors.orange;
    if (status == 'PRÓXIMO (3d)') return Colors.amber;
    return Colors.green;
  }
}
