import 'package:bcrypt/bcrypt.dart';
import '../../../core/api/api_client.dart';

class UserRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getUsers() async {
    const sql = '''
      SELECT u.id, u.username, u.nombre_completo, u.email, r.nombre as rol_nombre, 
             s.nombre as sucursal_nombre, u.activo, u.role_id, u.sucursal_id
      FROM usuarios u
      JOIN roles r ON u.role_id = r.id
      JOIN sucursales s ON u.sucursal_id = s.id
      WHERE u.deleted_at IS NULL
      ORDER BY u.id DESC
    ''';
    
    final result = await _apiClient.query(sql);
    
    return result.map((row) => {
      'id': int.parse(row['id'].toString()),
      'username': row['username'],
      'nombre_completo': row['nombre_completo'],
      'email': row['email'],
      'rol': row['rol_nombre'],
      'sucursal': row['sucursal_nombre'],
      'activo': row['activo'],
      'role_id': int.parse(row['role_id'].toString()),
      'sucursal_id': int.parse(row['sucursal_id'].toString()),
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getRoles() async {
    final result = await _apiClient.query('SELECT id, nombre FROM roles');
    return result.map((row) => {
      'id': int.parse(row['id'].toString()),
      'nombre': row['nombre'],
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getSucursales() async {
    final result = await _apiClient.query('SELECT id, nombre FROM sucursales WHERE deleted_at IS NULL');
    return result.map((row) => {
      'id': int.parse(row['id'].toString()),
      'nombre': row['nombre'],
    }).toList();
  }

  Future<void> createUser({
    required String username,
    required String password,
    required String nombreCompleto,
    required int roleId,
    required int sucursalId,
  }) async {
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
    await _apiClient.query(
      '''
      INSERT INTO usuarios (username, password_hash, nombre_completo, role_id, sucursal_id)
      VALUES (\$1, \$2, \$3, \$4, \$5)
      ''',
      params: [username, hashedPassword, nombreCompleto, roleId, sucursalId],
    );
  }

  Future<void> updateUser({
    required int id,
    required String nombreCompleto,
    required int roleId,
    required int sucursalId,
    String? password,
  }) async {
    if (password != null && password.isNotEmpty) {
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
      await _apiClient.query(
        '''
        UPDATE usuarios SET nombre_completo = \$1, role_id = \$2, sucursal_id = \$3, password_hash = \$4
        WHERE id = \$5
        ''',
        params: [nombreCompleto, roleId, sucursalId, hashedPassword, id],
      );
    } else {
      await _apiClient.query(
        '''
        UPDATE usuarios SET nombre_completo = \$1, role_id = \$2, sucursal_id = \$3
        WHERE id = \$4
        ''',
        params: [nombreCompleto, roleId, sucursalId, id],
      );
    }
  }

  Future<void> toggleUserStatus(int id, bool active) async {
    await _apiClient.query(
      'UPDATE usuarios SET activo = \$1 WHERE id = \$2',
      params: [active, id],
    );
  }

  Future<void> softDeleteUser(int id) async {
    await _apiClient.query(
      'UPDATE usuarios SET deleted_at = CURRENT_TIMESTAMP WHERE id = \$1',
      params: [id],
    );
  }
}
