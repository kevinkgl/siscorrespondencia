class UserModel {
  final int id;
  final String username;
  final String nombreCompleto;
  final String role;
  final String sucursal;
  final int sucursalId;

  UserModel({
    required this.id,
    required this.username,
    required this.nombreCompleto,
    required this.role,
    required this.sucursal,
    required this.sucursalId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: int.parse(map['id'].toString()),
      username: map['username'],
      nombreCompleto: map['nombre_completo'],
      role: map['rol_nombre'],
      sucursal: map['sucursal_nombre'],
      sucursalId: int.parse(map['sucursal_id'].toString()),
    );
  }
}
