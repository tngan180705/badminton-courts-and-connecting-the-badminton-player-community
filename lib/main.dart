import 'package:badminton_app/presentation/screens/home/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart'; // Đảm bảo đã import file này
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/login_screen.dart';

void main() async {
  // 1. Phải có dòng này để khởi tạo các service hệ thống
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Khởi tạo Firebase với options cụ thể
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Badminton App',
      theme: AppTheme.light,
      // Logic điều hướng chuẩn:
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const HomeScreen(); // Nếu đã login thì vào đây
          }
          return const LoginScreen(); // Nếu chưa thì vào đây
        },
      ),
    );
  }
}