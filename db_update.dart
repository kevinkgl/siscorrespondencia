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

    print('Actualizando tabla correspondencia...');
    await connection.execute('ALTER TABLE correspondencia ADD COLUMN IF NOT EXISTS file_path TEXT;');
    print('Tabla actualizada con éxito.');
    
    await connection.close();
    exit(0);
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
