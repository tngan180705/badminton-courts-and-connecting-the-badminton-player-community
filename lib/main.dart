import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'presentation/features/auth/pages/login_screen.dart';
import 'presentation/features/court/pages/home_screen.dart';
import 'presentation/features/admin/court_management/pages/admin_court_list_screen.dart';
import 'presentation/features/auth/providers/auth_state_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      /// 🔥 FIX QUAN TRỌNG → ép rebuild khi logout
      key: ValueKey(authState.value),

      debugShowCheckedModeBanner: false,
      title: 'Badminton Community',

      home: authState.when(
        data: (firebaseUser) {
          if (firebaseUser == null) {
            return LoginScreen(); // Firebase chưa login -> về Login
          }

          final userAsync = ref.watch(currentUserProvider);

          return userAsync.when(
            data: (userModel) {
              // Nếu đã có Firebase User nhưng không tìm thấy UserModel trong Firestore
              if (userModel == null) {
                // Có thể Firebase User vừa tạo, Firestore chưa kịp tạo document
                // Hoặc bạn có thể trả về LoginScreen hoặc một màn hình tạo Profile
                return LoginScreen();
              }

              if (userModel.role == 'admin') {
                return const AdminCourtListScreen();
              }
              return const HomeScreen();
            },
            loading: () => const LoadingScreen(),
            error: (e, _) => ErrorScreen(message: "Lỗi tải dữ liệu: $e"),
          );
        },
        loading: () => const LoadingScreen(),
        error: (e, _) => ErrorScreen(message: "Lỗi Firebase: $e"),
      ),
    );
  }
}

/// 🔥 LOADING
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// 🔥 ERROR
class ErrorScreen extends StatelessWidget {
  final String message;

  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              child: const Text("Thử lại"),
            ),
          ],
        ),
      ),
    );
  }
}
