import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/repositories/user_repository.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late String _selectedSkill;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['full_name']);
    _phoneController = TextEditingController(text: widget.userData['phone']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _selectedSkill = widget.userData['skill_level'] ?? 'Mới bắt đầu';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 400,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = widget.userData['id'];
      final updateData = <String, dynamic>{
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'skill_level': _selectedSkill,
      };

      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        updateData['avatar_base64'] = base64Encode(bytes);
      }

      await UserRepository().updateUser(userId: userId, data: updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công!'), backgroundColor: AppColors.primary),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5CA),
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAvatarPicker(),
              const SizedBox(height: 30),
              _buildTextField(_nameController, 'Họ và tên', Icons.person_outline, Validators.validateFullName),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, 'Số điện thoại', Icons.phone_android_outlined, Validators.validatePhone, isPhone: true),
              const SizedBox(height: 16),
              _buildTextField(_emailController, 'Email', Icons.email_outlined, Validators.validateEmail),
              const SizedBox(height: 16),
              _buildSkillDropdown(),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A6136),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Xác nhận', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4A6136), width: 2),
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: _imageFile != null 
                ? FileImage(_imageFile!) 
                : (widget.userData['avatar_base64'] != null && widget.userData['avatar_base64'].isNotEmpty 
                    ? MemoryImage(base64Decode(widget.userData['avatar_base64'])) as ImageProvider
                    : null),
              child: (_imageFile == null && (widget.userData['avatar_base64'] == null || widget.userData['avatar_base64'].isEmpty))
                ? const Icon(Icons.camera_alt_outlined, size: 40, color: Colors.white)
                : null,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFF4A6136), shape: BoxShape.circle),
            child: const Icon(Icons.edit, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String? Function(String?)? validator, {bool isPhone = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF4A6136)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'Trình độ chơi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: _selectedSkill,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.bar_chart, color: Color(0xFF4A6136)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
          items: ['Mới bắt đầu', 'Chơi ổn', 'Chơi tốt']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _selectedSkill = v!),
        ),
      ],
    );
  }
}
