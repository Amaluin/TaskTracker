import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserRepository {
  final SupabaseClient _client = Supabase.instance.client;

  UserModel _currentUserToModel(User user) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      phone: user.phone,
      name: user.userMetadata?['name'] as String?,
      displayName: user.userMetadata?['display_name'] as String?,
      createdAt: DateTime.parse(user.createdAt),
    );
  }

  // Получить всех пользователей
  Future<List<UserModel>> getAllUsers() async {
    final currentUser = await getCurrentUser();
    try {
      // Получаем пользователей из auth.users через RPC функцию
      final response = await _client.rpc('get_all_users');

      if (response == null) {
        print('⚠️ RPC вернул null, пробуем fallback через user_profiles');
        return await _getUsersFromProfilesFallback(currentUser);
      }

      final List<dynamic> data = response is List ? response : [response];
      final users = data
          .whereType<Map<String, dynamic>>()
          .map(UserModel.fromJson)
          .where((user) => user.id.isNotEmpty)
          .toList();

      print('✅ Загружено пользователей: ${users.length}');
      for (var user in users) {
        print('   - ${user.displayText} (${user.email})');
      }

      return _mergeWithCurrentUser(users, currentUser);
    } catch (e) {
      print('❌ Ошибка получения пользователей: $e');
      print('   Пробуем fallback через user_profiles');
      return await _getUsersFromProfilesFallback(currentUser);
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

      final userModel = _currentUserToModel(user);

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
      final response = await _client.rpc(
        'get_user_by_id',
        params: {'user_id': userId},
      );
      if (response == null) return null;
      if (response is List && response.isNotEmpty) {
        return UserModel.fromJson(response.first as Map<String, dynamic>);
      }
      if (response is Map<String, dynamic>) {
        return UserModel.fromJson(response);
      }

      return null;
    } catch (e) {
      print('❌ Ошибка получения пользователя: $e');
      return null;
    }
  }

  Future<List<UserModel>> _getUsersFromProfilesFallback(
    UserModel? currentUser,
  ) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select('id, phone, display_name, created_at')
          .order('created_at', ascending: false);

      final profiles = (response as List).cast<Map<String, dynamic>>();
      final users = profiles
          .map((json) {
            return UserModel(
              id: json['id'] as String,
              email: '',
              phone: json['phone'] as String?,
              name: null,
              displayName: json['display_name'] as String?,
              createdAt: DateTime.parse(json['created_at'] as String),
            );
          })
          .where((user) => user.id.isNotEmpty)
          .toList();

      print('✅ Загружено пользователей из user_profiles: ${users.length}');
      return _mergeWithCurrentUser(users, currentUser);
    } catch (fallbackError) {
      print('❌ Fallback user_profiles тоже не сработал: $fallbackError');
      return currentUser != null ? [currentUser] : [];
    }
  }

  List<UserModel> _mergeWithCurrentUser(
    List<UserModel> users,
    UserModel? currentUser,
  ) {
    final allUsers = <UserModel>[
      ...users.where((user) => user.id.isNotEmpty),
      if (currentUser != null && currentUser.id.isNotEmpty) currentUser,
    ];

    final byIdentity = <String, UserModel>{};
    for (final user in allUsers) {
      final identityKey = _identityKey(user);
      final existing = byIdentity[identityKey];
      if (existing == null || _qualityScore(user) >= _qualityScore(existing)) {
        byIdentity[identityKey] = user;
      }
    }

    return byIdentity.values.toList();
  }

  String _identityKey(UserModel user) {
    final phoneDigits = user.phone?.replaceAll(RegExp(r'\D'), '') ?? '';
    final email = user.email.trim().toLowerCase();
    final emailLocalDigits = email.isNotEmpty
        ? email.split('@').first.replaceAll(RegExp(r'\D'), '')
        : '';

    // Важно: одинаковые цифры телефона и email local-part считаем одним человеком.
    final numberIdentity = phoneDigits.isNotEmpty
        ? phoneDigits
        : emailLocalDigits;
    if (numberIdentity.isNotEmpty) return 'number:$numberIdentity';

    if (email.isNotEmpty) return 'email:$email';

    return 'id:${user.id}';
  }

  int _qualityScore(UserModel user) {
    var score = 0;
    if (user.displayName != null && user.displayName!.trim().isNotEmpty)
      score += 3;
    if (user.name != null && user.name!.trim().isNotEmpty) score += 2;
    if (user.email.trim().isNotEmpty) score += 2;
    if (user.phone != null && user.phone!.trim().isNotEmpty) score += 1;
    return score;
  }
}
