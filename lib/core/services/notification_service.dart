import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';
import '../database/database_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isListening = false;

  Future<void> init() async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) return;
    try {
      await localNotifier.setup(appName: 'Sistema Correspondencia');
    } catch (e) {
      debugPrint('Error inicializando local_notifier: $e');
    }
  }

  Future<void> startListening(int currentUserId) async {
    if (_isListening) return;

    try {
      final conn = await DatabaseService().connection;

      await conn.execute('LISTEN nueva_correspondencia');
      _isListening = true;

      conn.channels['nueva_correspondencia'].listen((payload) {
        final data = jsonDecode(payload);

        if (data['destinatario_id'] == currentUserId) {
          _showDesktopNotification(
            title: 'Nueva Correspondencia Recibida',
            body: 'CITE: ${data['cite']}\nAsunto: ${data['asunto']}',
          );
        }
      });

      if (kDebugMode) print('Escuchando notificaciones de base de datos...');
    } catch (e) {
      if (kDebugMode) print('Error al iniciar escucha de notificaciones: $e');
      _isListening = false;
    }
  }

  void _showDesktopNotification({required String title, required String body}) {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      // En móviles Android se usaría una lógica distinta (ej. flutter_local_notifications)
      // Por ahora lo dejamos como no-op para evitar el cuelgue.
      return;
    }
    try {
      LocalNotification notification = LocalNotification(
        title: title,
        body: body,
        silent: false,
      );
      notification.show();
    } catch (e) {
      debugPrint('Error mostrando notificación: $e');
    }
  }
}
