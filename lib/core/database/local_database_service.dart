import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    await _initDatabase();
    return _database!;
  }

  Future<void> _initDatabase() async {
    // Inicializar FFI para Windows/Linux
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'offline_data.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE offline_correspondence (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tipo_id INTEGER,
            remitente_id INTEGER,
            destinatario_id INTEGER,
            destinatario_externo TEXT,
            sucursal_origen_id INTEGER,
            sucursal_destino_id INTEGER,
            asunto TEXT,
            contenido TEXT,
            clasificacion TEXT,
            prioridad TEXT,
            fecha_limite TEXT,
            file_path TEXT,
            firma_digital BLOB, -- Guardamos la firma como bytes
            created_at TEXT
          )
        ''');
      },
    );
  }

  Future<int> saveOfflineCorrespondence(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('offline_correspondence', data);
  }

  Future<List<Map<String, dynamic>>> getPendingCorrespondence() async {
    final db = await database;
    return await db.query('offline_correspondence');
  }

  Future<void> deleteOfflineCorrespondence(int id) async {
    final db = await database;
    await db.delete('offline_correspondence', where: 'id = ?', whereArgs: [id]);
  }
}
