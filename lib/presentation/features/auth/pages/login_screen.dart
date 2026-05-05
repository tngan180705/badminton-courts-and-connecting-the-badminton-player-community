import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/validators.dart';
// Sử dụng AppSizes cho chuẩn
import '../providers/login_provider.dart';
import '../pages/register_screen.dart';
import '../pages/forgot_password_screen.dart';
import '../../court/pages/home_screen.dart'; // Import trang Home của bạn
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends ConsumerWidget {
  // Chuyển sang ConsumerWidget
  LoginScreen({super.key});

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // LẮNG NGHE TRẠNG THÁI LOGIN
    ref.listen<AsyncValue<UserCredential?>>(loginStateProvider,
        (previous, next) {
      next.when(
        data: (user) {
          if (previous is AsyncLoading && user != null) {
            Navigator.pop(context); // Đóng Loading Dialog
            // Chuyển sang Home và xóa lịch sử navigation
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          }
        },
        error: (err, _) {
          Navigator.pop(context); // Đóng Loading Dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(err.toString()),
                backgroundColor: AppColors.error),
          );
        },
        loading: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Khối minh họa (Giữ nguyên UI bạn A)
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 10)
                      ]),
                  child: const Icon(Icons.sports_tennis,
                      color: Colors.white, size: 50),
                ),
                const SizedBox(height: 30),
                const Text("ĐĂNG NHẬP",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary)),
                const SizedBox(height: 30),

                // Email field
                TextFormField(
                  controller: _emailController,
                  validator: Validators.validateEmail,
                  decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.email, color: AppColors.secondary),
                      hintText: "Email",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 15),

                // Password field
                TextFormField(
                  controller: _passController,
                  obscureText: true,
                  validator: Validators.validatePassword,
                  decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.lock, color: AppColors.secondary),
                      hintText: "Mật khẩu",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none)),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen()),
                    );
                  },
                  child: const Text(
                    "Quên mật khẩu?",
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 20),

                // Nút đăng nhập
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        ref.read(loginActionProvider).login(
                              _emailController.text.trim(),
                              _passController.text.trim(),
                            );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: const Text("ĐĂNG NHẬP",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 30),
                GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    child: RichText(
                        text: const TextSpan(
                            text: "Chưa có tài khoản? ",
                            style: TextStyle(color: AppColors.textPrimary),
                            children: [
                          TextSpan(
                              text: "Đăng ký ngay",
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline))
                        ]))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
