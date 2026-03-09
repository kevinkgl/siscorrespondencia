import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() {
    // Configurar interceptores para añadir el token automáticamente
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  final _dio = Dio(BaseOptions(
    // URL de producción en Render para acceso remoto universal
    baseUrl: kIsWeb ? 'https://siscorrespondencia.onrender.com/api' : 'https://siscorrespondencia.onrender.com/api',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // Guardar token después del login
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<List<Map<String, dynamic>>> query(String sql, {List<dynamic>? params}) async {
    if (kIsWeb) {
      try {
        final response = await _dio.post('/query', data: {
          'sql': sql,
          'params': params ?? [],
        });
        return List<Map<String, dynamic>>.from(response.data);
      } on DioException catch (e) {
        final message = e.response?.data?['detail'] ?? e.message;
        print('Error en Query Web: $message');
        throw Exception('Error en servidor remoto: $message');
      } catch (e) {
        throw Exception('Error inesperado: $e');
      }
    } else {
      try {
        final db = DatabaseService();
        final connection = await db.connection;
        
        final result = await connection.execute(
          sql,
          parameters: params ?? [],
        );
        return result.map((row) => row.toColumnMap()).toList();
      } catch (e) {
        print('--- ERROR SQL DETECTADO ---');
        print('Consulta: $sql');
        print('Parámetros: $params');
        print('Error: $e');
        print('---------------------------');
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> login(String usuario, String password) async {
    if (kIsWeb) {
      try {
        final response = await _dio.post('/auth/login', data: {
          'usuario': usuario,
          'password': password,
        });
        
        final data = response.data;
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return data;
      } catch (e) {
        throw Exception('Usuario o clave incorrectos');
      }
    } else {
      // SI NO ES WEB: Consulta directa a la DB
      try {
        final db = DatabaseService();
        final connection = await db.connection;
        final result = await connection.execute(
          r'''
          SELECT u.id, u.username, u.nombre_completo, r.nombre as rol_nombre, s.nombre as sucursal_nombre, u.sucursal_id, u.password_hash
          FROM usuarios u
          JOIN roles r ON u.role_id = r.id
          JOIN sucursales s ON u.sucursal_id = s.id
          WHERE u.username = $1 AND u.activo = true
          ''',
          parameters: [usuario],
        );

        if (result.isEmpty) throw Exception('Usuario no encontrado');

        final row = result.first;
        final String storedHash = row[6] as String;

        // Nota: En nativo usamos bcrypt de Dart
        // Para simplificar esta lógica, asumimos que si no es web, el repositorio manejaría la verificación
        // Pero para mantener la consistencia con el bridge, devolvemos el mapa esperado
        
        return {
          'user': {
            'id': row[0],
            'username': row[1],
            'nombre_completo': row[2],
            'rol_nombre': row[3],
            'sucursal_nombre': row[4],
            'sucursal_id': row[5],
            'password_hash': row[6], // Lo pasamos para que el repo verifique
          }
        };
      } catch (e) {
        throw Exception('Error en conexión local: $e');
      }
    }
  }
}
