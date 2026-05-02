import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import đúng cấu trúc thư mục feature-based
import 'core/theme/app_theme.dart';
import 'presentation/features/auth/pages/login_screen.dart';
import 'presentation/features/court/pages/home_screen.dart'; // Đã sửa path theo feature court
import 'presentation/features/auth/providers/auth_state_provider.dart'; // File vừa tạo ở trên

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.signOut();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  // Chuyển sang ConsumerWidget để dùng ref
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Lắng nghe stream thay đổi trạng thái (đã tạo ở bước trước)
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // 2. Sử dụng .when để handle 3 trạng thái của một Stream
      home: authState.when(
        data: (user) {
          // Nếu user == null nghĩa là chưa đăng nhập hoặc đã logout
          if (user == null) {
            return LoginScreen();
          }
          // Nếu có user, đẩy thẳng vào Home
          return const HomeScreen();
        },
        // Trong lúc app đang check Firebase (mất khoảng 1-2s đầu)
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        // Nếu lỗi kết nối Firebase
        error: (e, st) => Scaffold(
          body: Center(child: Text("Lỗi khởi động: $e")),
        ),
      ),
    );
  }
}
