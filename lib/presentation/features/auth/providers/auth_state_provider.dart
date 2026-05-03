import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/models/user_model.dart';

/// 🔥 AUTH STATE
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// 🔥 REPOSITORY
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// 🔥 USER DATA
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  // Lấy user hiện tại từ Firebase Auth
  final user = ref.watch(authStateChangesProvider).value;

  if (user == null) return null;

  // Chỉ fetch từ DB khi chắc chắn có UID
  return await ref.read(userRepositoryProvider).getUserById(user.uid);
});

/// 🔥 AUTH CONTROLLER
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController();
});

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> logout() async {
    await _auth.signOut();
  }
}
