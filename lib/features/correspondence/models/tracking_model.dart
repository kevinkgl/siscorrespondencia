class TrackingModel {
  final int id;
  final String usuarioOrigen;
  final String? usuarioDestino;
  final String accion;
  final String? observaciones;
  final DateTime fechaMovimiento;

  TrackingModel({
    required this.id,
    required this.usuarioOrigen,
    this.usuarioDestino,
    required this.accion,
    this.observaciones,
    required this.fechaMovimiento,
  });

  factory TrackingModel.fromMap(Map<String, dynamic> map) {
    return TrackingModel(
      id: map['id'],
      usuarioOrigen: map['usuario_origen_nombre'],
      usuarioDestino: map['usuario_destino_nombre'],
      accion: map['accion'],
      observaciones: map['observaciones'],
      fechaMovimiento: map['fecha_movimiento'],
    );
  }
}
