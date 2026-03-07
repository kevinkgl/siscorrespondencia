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
  });

  factory CorrespondenceModel.fromMap(Map<String, dynamic> map) {
    return CorrespondenceModel(
      id: map['id'],
      cite: map['cite_numero'],
      tipo: map['tipo_nombre'],
      remitente: map['remitente_nombre'],
      destinatario: map['destinatario_nombre'],
      destinatarioExterno: map['destinatario_externo'],
      asunto: map['asunto'],
      contenido: map['contenido'],
      estado: map['estado'],
      clasificacion: map['clasificacion'],
      prioridad: map['prioridad'],
      fechaEmision: map['fecha_emision'],
      fechaLimite: map['fecha_limite'],
      filePath: map['file_path'],
    );
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
