import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  final endpoint = Endpoint(
    host: 'localhost',
    database: 'sistema_correspondencia',
    username: 'postgres',
    password: 'kegala',
  );

  print('Conectando a la base de datos...');
  
  try {
    final connection = await Connection.open(
      endpoint,
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );

    print('Leyendo script SQL...');
    final content = await File('database_schema.sql').readAsString();
    
    // Una forma simple de separar sentencias por ';' 
    // Ojo: Esto es básico, pero funciona para este script inicial.
    final statements = content.split(';');

    print('Ejecutando sentencias SQL una por una...');
    for (var statement in statements) {
      final trimmed = statement.trim();
      if (trimmed.isNotEmpty) {
        await connection.execute(trimmed);
      }
    }

    print('¡Base de datos configurada exitosamente!');
    await connection.close();
    exit(0);
  } catch (e) {
    print('Error configurando la base de datos: $e');
    exit(1);
  }
}
