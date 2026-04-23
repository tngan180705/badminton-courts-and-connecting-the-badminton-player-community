import 'dart:io';
import 'package:badminton_app/data/repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedGender = 'Nam';
  String _selectedSkill = 'Mới bắt đầu';
  File? _imageFile;

  // Chọn ảnh từ Gallery
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 50,
      );
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint("Lỗi chọn ảnh: $e");
    }
  }

  void _onRegister() async {
    if (_formKey.currentState!.validate()) {
      // 1. Loading Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      try {
        // 2. Thực hiện Đăng ký thông qua Repository
        await UserRepository().registerUser(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          gender: _selectedGender,
          skillLevel: _selectedSkill,
          imageFile: _imageFile, 
        );

        // 3. Đăng xuất ngay để giữ người dùng ở màn hình Login
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          Navigator.pop(context); // Đóng Loading

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đăng ký thành công! Vui lòng đăng nhập."),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pop(context); // Quay về LoginScreen
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) Navigator.pop(context);
        String errorMsg = "Lỗi đăng ký";
        if (e.code == 'email-already-in-use') errorMsg = "Email đã được sử dụng";
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
        );
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: ${e.toString()}"), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildAvatarPicker(),
                const SizedBox(height: 25),
                const Text(
                  "TẠO TÀI KHOẢN", 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary)
                ),
                const SizedBox(height: 30),
                
                _buildField(_nameController, "Họ và tên", Icons.person_outline, Validators.validateFullName),
                const SizedBox(height: 15),
                _buildField(_emailController, "Email", Icons.email_outlined, Validators.validateEmail),
                const SizedBox(height: 15),
                _buildField(_phoneController, "Số điện thoại", Icons.phone_android_outlined, Validators.validatePhone, isPhone: true),
                const SizedBox(height: 15),
                _buildField(_passwordController, "Mật khẩu", Icons.lock_outline, Validators.validatePassword, isPass: true),
                
                const SizedBox(height: 20),
                _buildDropdowns(),
                
                const SizedBox(height: 40),
                _buildRegisterButton(),
                const SizedBox(height: 15),
                _buildBackToLogin(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 65,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 62,
              backgroundColor: AppColors.secondary.withOpacity(0.2),
              backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
              child: _imageFile == null 
                  ? const Icon(Icons.camera_alt_outlined, size: 45, color: AppColors.primary) 
                  : null,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.edit, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, String? Function(String?)? val, {bool isPass = false, bool isPhone = false}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPass,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      validator: val,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.secondary, size: 22),
        hintText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        errorStyle: const TextStyle(color: AppColors.error),
      ),
    );
  }

  Widget _buildDropdowns() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: InputDecoration(
              filled: true, fillColor: Colors.white, 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15)
            ),
            items: ['Nam', 'Nữ'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _selectedGender = v!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedSkill,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true, fillColor: Colors.white, 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15)
            ),
            items: ['Mới bắt đầu', 'Chơi ổn', 'Chơi tốt'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _selectedSkill = v!),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _onRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
        ),
        child: const Text("ĐĂNG KÝ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildBackToLogin() {
    return TextButton(
      onPressed: () => Navigator.pop(context), 
      child: RichText(
        text: const TextSpan(
          text: "Đã có tài khoản? ",
          style: TextStyle(color: Colors.black54),
          children: [
            TextSpan(text: "Đăng nhập", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
          ]
        )
      )
    );
  }
}