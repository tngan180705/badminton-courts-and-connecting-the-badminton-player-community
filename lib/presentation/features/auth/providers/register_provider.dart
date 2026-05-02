import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Provider quản lý trạng thái đăng ký (Loading, Success, Error)
final registerStateProvider =
    StateProvider<AsyncValue<void>>((ref) => const AsyncData(null));

class RegisterNotifier {
  final Ref ref;
  RegisterNotifier(this.ref);

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String gender,
    required String skillLevel,
    File? imageFile,
  }) async {
    ref.read(registerStateProvider.notifier).state = const AsyncLoading();

    try {
      // Sử dụng UserRepository thông qua Riverpod (nếu bạn đã tạo Provider cho nó)
      await UserRepository().registerUser(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        gender: gender,
        skillLevel: skillLevel,
        imageFile: imageFile,
      );
      //  đăng xuất để chặn Firebase tự vào home
      await FirebaseAuth.instance.signOut();
      // đánh dấu thành công
      ref.read(registerStateProvider.notifier).state = const AsyncData(null);
    } catch (e, stack) {
      ref.read(registerStateProvider.notifier).state = AsyncError(e, stack);
    }
  }
}

final registerActionProvider = Provider((ref) => RegisterNotifier(ref));
