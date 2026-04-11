import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Получить всех пользователей
  Future<List<UserModel>> getAllUsers() async {
    try {
      // Получаем пользователей из auth.users через RPC функцию
      final response = await _client.rpc('get_all_users');
      
      if (response == null) {
        print('⚠️ RPC вернул null, возвращаем текущего пользователя');
        final currentUser = await getCurrentUser();
        return currentUser != null ? [currentUser] : [];
      }
      
      final List<dynamic> data = response is List ? response : [response];
      final users = data.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
      
      print('✅ Загружено пользователей: ${users.length}');
      for (var user in users) {
        print('   - ${user.displayText} (${user.email})');
      }
      
      return users;
    } catch (e) {
      print('❌ Ошибка получения пользователей: $e');
      print('   Возвращаем текущего пользователя как fallback');
      
      // Fallback: возвращаем хотя бы текущего пользователя
      final currentUser = await getCurrentUser();
      return currentUser != null ? [currentUser] : [];
    }
  }

  // Получить текущего пользователя
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        print('⚠️ Текущий пользователь не найден (не авторизован)');
        return null;
      }

      print('✅ Текущий пользователь: ${user.email}');
      print('   ID: ${user.id}');
      print('   Metadata: ${user.userMetadata}');

      final userModel = UserModel(
        id: user.id,
        email: user.email ?? '',
        phone: user.phone,
        name: user.userMetadata?['name'] as String?,
        displayName: user.userMetadata?['display_name'] as String?,
        createdAt: DateTime.parse(user.createdAt),
      );
      
      print('   Display text: ${userModel.displayText}');
      
      return userModel;
    } catch (e) {
      print('❌ Ошибка получения текущего пользователя: $e');
      return null;
    }
  }

  // Получить пользователя по ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _client
          .rpc('get_user_by_id', params: {'user_id': userId})
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      print('❌ Ошибка получения пользователя: $e');
      return null;
    }
  }
}
