import 'package:bcrypt/bcrypt.dart';
import '../../core/api/api_client.dart';
import 'user_model.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<UserModel?> login(String username, String password) async {
    try {
      final response = await _apiClient.login(username, password);
      
      if (response['user'] != null) {
        final userData = response['user'];
        
        // Si hay un password_hash en la respuesta, significa que estamos en modo NATIVO
        // y debemos verificar la contraseña aquí.
        if (userData['password_hash'] != null) {
          final String storedHash = userData['password_hash'];
          bool passwordCorrect = false;
          
          try {
            passwordCorrect = BCrypt.checkpw(password, storedHash);
          } catch (e) {
            // Fallback para admin inicial
            if (storedHash == password) passwordCorrect = true;
          }

          if (!passwordCorrect) return null;
        }

        return UserModel.fromMap(userData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
