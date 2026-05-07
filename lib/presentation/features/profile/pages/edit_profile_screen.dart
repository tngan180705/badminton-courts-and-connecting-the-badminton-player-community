import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'package:badminton_app/core/constants/app_colors.dart';
import 'package:badminton_app/core/constants/app_sizes.dart';
import 'package:badminton_app/data/models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  late String _selectedSkill;
  late String _selectedGender;

  String? _avatarBase64;
  bool _isLoading = false;

  final List<String> _skillLevels = ['Mới bắt đầu', 'Chơi ổn', 'Chơi tốt'];
  final List<String> _genders = ['Nam', 'Nữ', 'Khác'];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.phone);
    _emailController = TextEditingController(text: widget.user.email);

    _selectedGender =
        _genders.contains(widget.user.gender) ? widget.user.gender : 'Nam';

    final skill = widget.user.skillLevel.trim();
    _selectedSkill =
        _skillLevels.contains(skill) ? skill : _skillLevels.first;

    _avatarBase64 = widget.user.avatarBase64;
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
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image == null) return;

    final bytes = await File(image.path).readAsBytes();

    setState(() {
      _avatarBase64 = base64Encode(bytes);
    });
  }

  Future<void> _saveProfile() async {
    final userId = widget.user.userId.trim();

    debugPrint("USER UPDATE ID: $userId");

    if (userId.isEmpty) {
      _showSnackBar("Không tìm thấy ID user");
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showSnackBar("Họ tên không được để trống");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'gender': _selectedGender,
        'skill_level': _selectedSkill,
        'avatar_base64': _avatarBase64 ?? '',
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get(); 

      if (!mounted) return;

      _showSnackBar("Cập nhật thành công!");

      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      debugPrint("Firestore error: $e");
      _showSnackBar("Lỗi hệ thống: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _avatarBase64 ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Chỉnh sửa hồ sơ",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // AVATAR
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: avatar.isNotEmpty
                        ? MemoryImage(base64Decode(avatar))
                        : null,
                    child: avatar.isEmpty
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            _buildTextField("Họ và tên", _nameController, Icons.person),
            const SizedBox(height: 15),

            _buildTextField(
              "Số điện thoại",
              _phoneController,
              Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              "Email",
              _emailController,
              Icons.email,
              readOnly: true,
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    "Giới tính",
                    _selectedGender,
                    _genders,
                    (v) {
                      if (v == null) return;
                      setState(() => _selectedGender = v);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdown(
                    "Trình độ",
                    _selectedSkill,
                    _skillLevels,
                    (v) {
                      if (v == null) return;
                      setState(() => _selectedSkill = v);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "LƯU THAY ĐỔI",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}