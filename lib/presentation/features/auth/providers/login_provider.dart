import 'package:badminton_app/data/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../data/repositories/user_repository.dart';

final loginStateProvider =
    StateProvider<AsyncValue<UserModel?>>((ref) => const AsyncData(null));

class LoginNotifier {
  final Ref ref;
  final UserRepository _userRepository = UserRepository();

  LoginNotifier(this.ref);

  Future<void> login(String email, String password) async {
    ref.read(loginStateProvider.notifier).state =
        const AsyncLoading();

    try {
      // 1. Login Firebase Auth
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 2. Get user from Firestore
      final user =
          await _userRepository.getUserByFirebaseUid(uid);

      if (user == null) {
        throw "Không tìm thấy user trong hệ thống";
      }

      // 3. Check role
      if (user.role != 'admin' && user.role != 'player') {
        throw "Tài khoản không hợp lệ";
      }

      // 4. Return user
      ref.read(loginStateProvider.notifier).state =
          AsyncData(user);

    } on FirebaseAuthException catch (e) {
      String message = "Đã xảy ra lỗi";

      if (e.code == 'user-not-found') {
        message = "Email chưa được đăng ký";
      } else if (e.code == 'wrong-password') {
        message = "Sai mật khẩu";
      } else if (e.code == 'invalid-email') {
        message = "Email không hợp lệ";
      }

      ref.read(loginStateProvider.notifier).state =
          AsyncError(message, StackTrace.current);

    } catch (e) {
      ref.read(loginStateProvider.notifier).state =
          AsyncError(e.toString(), StackTrace.current);
    }
  }
}

final loginActionProvider =
    Provider((ref) => LoginNotifier(ref));