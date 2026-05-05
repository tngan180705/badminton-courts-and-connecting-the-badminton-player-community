import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
// Dùng cho đồng bộ
import '../../../../../core/utils/validators.dart';
import '../providers/register_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedGender = 'Nam';
  String _selectedSkill = 'Mới bắt đầu';
  File? _imageFile;

  // Logic chọn ảnh giữ nguyên vì nó là local UI state
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

  void _onRegister() {
    if (_formKey.currentState!.validate()) {
      // GỌI PROVIDER THAY VÌ REPOSITORY TRỰC TIẾP
      ref.read(registerActionProvider).register(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            gender: _selectedGender,
            skillLevel: _selectedSkill,
            imageFile: _imageFile,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // LẮNG NGHE TRẠNG THÁI TỪ PROVIDER ĐỂ XỬ LÝ UI
    ref.listen<AsyncValue<void>>(registerStateProvider, (previous, next) {
      next.when(
        data: (_) {
          if (previous is AsyncLoading) {
            Navigator.pop(context); // Đóng Loading Dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Đăng ký thành công! Vui lòng đăng nhập."),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context); // Quay về LoginScreen
          }
        },
        error: (err, _) {
          Navigator.pop(context); // Đóng Loading Dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Lỗi: $err"), backgroundColor: AppColors.error),
          );
        },
        loading: () {
          // Hiển thị Loading Dialog chuyên nghiệp
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

    // GIỮ NGUYÊN GIAO DIỆN CỦA BẠN A
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
                const Text("TẠO TÀI KHOẢN",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary)),
                const SizedBox(height: 30),
                _buildField(_nameController, "Họ và tên", Icons.person_outline,
                    Validators.validateFullName),
                const SizedBox(height: 15),
                _buildField(_emailController, "Email", Icons.email_outlined,
                    Validators.validateEmail),
                const SizedBox(height: 15),
                _buildField(_phoneController, "Số điện thoại",
                    Icons.phone_android_outlined, Validators.validatePhone,
                    isPhone: true),
                const SizedBox(height: 15),
                _buildField(_passwordController, "Mật khẩu", Icons.lock_outline,
                    Validators.validatePassword,
                    isPass: true),
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

  // --- WIDGET COMPONENTS (GIỮ NGUYÊN STYLE BẠN A) ---

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
              backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
              backgroundImage:
                  _imageFile != null ? FileImage(_imageFile!) : null,
              child: _imageFile == null
                  ? const Icon(Icons.camera_alt_outlined,
                      size: 45, color: AppColors.primary)
                  : null,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.edit, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      String? Function(String?)? val,
      {bool isPass = false, bool isPhone = false}) {
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
        errorStyle: const TextStyle(color: AppColors.error),
      ),
    );
  }

  Widget _buildDropdowns() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedGender,
            decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15)),
            items: ['Nam', 'Nữ']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _selectedGender = v!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedSkill,
            isExpanded: true,
            decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15)),
            items: ['Mới bắt đầu', 'Chơi ổn', 'Chơi tốt']
                .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: const TextStyle(fontSize: 13))))
                .toList(),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
        ),
        child: const Text("ĐĂNG KÝ",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.2)),
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
              TextSpan(
                  text: "Đăng nhập",
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold))
            ])));
  }
}
