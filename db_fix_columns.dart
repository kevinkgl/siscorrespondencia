import 'package:postgres/postgres.dart';
import 'dart:io';

void main() async {
  final endpoint = Endpoint(
    host: 'localhost',
    database: 'sistema_correspondencia',
    username: 'postgres',
    password: 'kegala',
  );

  try {
    final connection = await Connection.open(
      endpoint,
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );

    print('Corrigiendo nombre de columna en tabla seguimiento...');
    // Renombrar correspondencia_id a correspondence_id para que coincida con el código Dart
    await connection.execute('ALTER TABLE seguimiento RENAME COLUMN correspondencia_id TO correspondence_id;');
    
    // También lo corregimos en la tabla adjuntos por si acaso
    await connection.execute('ALTER TABLE adjuntos RENAME COLUMN correspondencia_id TO correspondence_id;');
    
    print('Columnas corregidas con éxito.');
    
    await connection.close();
    exit(0);
  } catch (e) {
    print('Error al corregir columnas: $e');
    print('Es posible que las columnas ya tengan el nombre correcto.');
    exit(1);
  }
}
