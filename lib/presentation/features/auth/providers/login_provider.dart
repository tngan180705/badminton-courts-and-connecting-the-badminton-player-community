import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final loginStateProvider =
    StateProvider<AsyncValue<UserCredential?>>(
  (ref) => const AsyncData(null),
);

class LoginNotifier {
  final Ref ref;
  LoginNotifier(this.ref);

  Future<void> login(String email, String password) async {
    ref.read(loginStateProvider.notifier).state = const AsyncLoading();

    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      ref.read(loginStateProvider.notifier).state =
          AsyncData(userCredential);
    } on FirebaseAuthException catch (e) {
      String message = "Đã xảy ra lỗi";

      if (e.code == 'user-not-found') {
        message = "Email chưa đăng ký";
      } else if (e.code == 'wrong-password') {
        message = "Sai mật khẩu";
      } else if (e.code == 'invalid-email') {
        message = "Email không hợp lệ";
      }

      ref.read(loginStateProvider.notifier).state =
          AsyncError(message, StackTrace.current);
    } catch (_) {
      ref.read(loginStateProvider.notifier).state =
          AsyncError("Lỗi hệ thống", StackTrace.current);
    }
  }
}

final loginActionProvider = Provider<LoginNotifier>(
  (ref) => LoginNotifier(ref),
);