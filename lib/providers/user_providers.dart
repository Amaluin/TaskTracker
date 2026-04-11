import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';

// Репозиторий пользователей
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// Провайдер для получения всех пользователей
final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final repository = ref.read(userRepositoryProvider);
  return repository.getAllUsers();
});

// Провайдер для текущего пользователя
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final repository = ref.read(userRepositoryProvider);
  return repository.getCurrentUser();
});

// Провайдер для получения пользователя по ID
final userByIdProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final repository = ref.read(userRepositoryProvider);
  return repository.getUserById(userId);
});
