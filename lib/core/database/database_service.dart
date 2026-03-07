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
    // Detectar host automáticamente
    // Si es Android y no estamos en emulador, usamos la IP de la PC
    // Si es Escritorio, usamos localhost
    String host = 'localhost';
    if (!kIsWeb && Platform.isAndroid) {
      host = '192.168.0.26'; // Tu IP de PC
    }

    try {
      _connection = await Connection.open(
        Endpoint(
          host: host,
          database: 'sistema_correspondencia',
          username: 'postgres',
          password: 'kegala',
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.disable,
          connectTimeout: Duration(seconds: 10),
        ),
      );
      developer.log('Conexión a PostgreSQL establecida en $host');
    } catch (e) {
      developer.log('Error al conectar a PostgreSQL en $host: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    await _connection?.close();
  }
}
