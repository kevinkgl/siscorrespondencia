import 'dart:io';
import 'package:postgres/postgres.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Connection? _connection;

  Future<Connection> get connection async {
    if (_connection == null || _connection!.isOpen == false) {
      await _connectWithRetry();
    }
    return _connection!;
  }

  Future<void> _connectWithRetry({int retries = 3}) async {
    int attempts = 0;
    while (attempts < retries) {
      try {
        await _connect();
        return;
      } catch (e) {
        attempts++;
        developer.log('Intento de conexión $attempts fallido: $e');
        if (attempts >= retries) rethrow;
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
  }

  Future<void> _connect() async {
    // Configuración para Supabase Cloud
    const String host = 'db.yemhcbdyxcuflvhvhsmo.supabase.co';
    const String user = 'postgres';
    const String dbName = 'postgres';
    const String pass = 'Keyler2020..'; // Asegúrate de que esta sea la contraseña de tu proyecto de Supabase

    try {
      _connection = await Connection.open(
        Endpoint(
          host: host,
          database: dbName,
          username: user,
          password: pass,
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.require, // Requerido para Supabase
          connectTimeout: Duration(seconds: 20),
          queryTimeout: Duration(seconds: 30),
        ),
      );
      developer.log('Conexión a Supabase establecida exitosamente');
    } catch (e) {
      developer.log('Error al conectar a Supabase: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    await _connection?.close();
  }
}
