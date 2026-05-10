import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import đúng cấu trúc thư mục feature-based
import 'core/theme/app_theme.dart';
import 'presentation/features/auth/pages/login_screen.dart';
import 'presentation/features/court/pages/home_screen.dart'; // Đã sửa path theo feature court
import 'presentation/features/auth/providers/auth_state_provider.dart';
import 'presentation/features/auth/providers/user_provider.dart';

import 'presentation/features/admin/pages/admin_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('vi_VN', null);
  // await FirebaseAuth.instance.signOut(); 

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: authState.when(
        data: (user) {
          if (user == null) {
            return LoginScreen();
          }
          
          return ref.watch(userDataProvider).when(
            data: (userData) {
              if (userData == null) return LoginScreen();
              
              final role = userData['role'] ?? 'player';
              if (role == 'admin') {
                return const AdminMainScreen();
              }
              return const HomeScreen();
            },
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => Scaffold(
              body: Center(child: Text("Lỗi tải dữ liệu người dùng: $e")),
            ),
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, st) => Scaffold(
          body: Center(child: Text("Lỗi khởi động: $e")),
        ),
      ),
    );
  }
}
