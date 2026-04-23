import 'package:badminton_app/presentation/screens/auth/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Thêm dòng này
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import './register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  // --- LOGIC ĐĂNG NHẬP ---
  void _onLogin() async {
    if (_formKey.currentState!.validate()) {
      // 1. Hiển thị vòng xoay Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      try {
        debugPrint("Đang tiến hành đăng nhập...");
        
        // 2. Gọi lệnh đăng nhập từ Firebase
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );

        // 3. Thành công: Đóng loading
        // Lưu ý: Không cần chuyển màn hình vì StreamBuilder ở main.dart sẽ tự làm việc đó
        if (mounted) Navigator.pop(context);

      } on FirebaseAuthException catch (e) {
        // 4. Xử lý các lỗi cụ thể từ Firebase
        if (mounted) {
          Navigator.pop(context); // Đóng loading
          
          String message = "Đã xảy ra lỗi";
          if (e.code == 'user-not-found') message = "Email này chưa được đăng ký";
          else if (e.code == 'wrong-password') message = "Sai mật khẩu, vui lòng thử lại";
          else if (e.code == 'invalid-email') message = "Định dạng email không hợp lệ";

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppColors.error),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lỗi hệ thống, vui lòng thử lại sau"), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Khối minh họa theo bảng màu be-xanh
                Container(
                  height: 100, 
                  width: 100, 
                  decoration: BoxDecoration(
                    color: AppColors.secondary, 
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10)]
                  ),
                  child: const Icon(Icons.sports_tennis, color: Colors.white, size: 50),
                ),
                const SizedBox(height: 30),
                const Text("ĐĂNG NHẬP", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                const SizedBox(height: 30),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  validator: Validators.validateEmail,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email, color: AppColors.secondary), 
                    hintText: "Email", 
                    filled: true, 
                    fillColor: Colors.white, 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
                  ),
                ),
                const SizedBox(height: 15),
                
                // Password field
                TextFormField(
                  controller: _passController,
                  obscureText: true,
                  validator: Validators.validatePassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock, color: AppColors.secondary), 
                    hintText: "Mật khẩu", 
                    filled: true, 
                    fillColor: Colors.white, 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
                  ),
                ),
                
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                    );
                  },
                  child: const Text(
                    "Quên mật khẩu?",
                    style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Nút đăng nhập
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _onLogin, // Gọi hàm đăng nhập thực sự
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: const Text("ĐĂNG NHẬP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), 
                  child: RichText(
                    text: const TextSpan(
                      text: "Chưa có tài khoản? ",
                      style: TextStyle(color: AppColors.textPrimary),
                      children: [
                        TextSpan(text: "Đăng ký ngay", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline))
                      ]
                    )
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}