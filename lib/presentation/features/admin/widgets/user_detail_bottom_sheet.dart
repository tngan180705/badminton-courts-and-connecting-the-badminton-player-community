import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailBottomSheet extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UserDetailBottomSheet({super.key, required this.userData});

  @override
  State<UserDetailBottomSheet> createState() => _UserDetailBottomSheetState();
}

class _UserDetailBottomSheetState extends State<UserDetailBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _selectedSkill;
  late String _selectedRole;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _nameController = TextEditingController(text: widget.userData['full_name']);
    _phoneController = TextEditingController(text: widget.userData['phone']);
    _selectedSkill = widget.userData['skill_level'] ?? 'Mới bắt đầu';
    _selectedRole = widget.userData['role'] ?? 'player';
    _isActive = !(widget.userData['is_locked'] ?? false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.userData['is_locked'] ?? false;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: const Color(0xFFE5E5CA),
                  backgroundImage: (widget.userData['avatar_base64'] != null && widget.userData['avatar_base64'].toString().isNotEmpty)
                      ? MemoryImage(base64Decode(widget.userData['avatar_base64']))
                      : null,
                  child: (widget.userData['avatar_base64'] == null || widget.userData['avatar_base64'].toString().isEmpty)
                      ? Text(
                          (widget.userData['full_name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF4A6136)),
                        )
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userData['full_name'] ?? 'N/A',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.userData['email'] ?? 'N/A',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildBadge(widget.userData['role']?.toString().toUpperCase() ?? 'PLAYER', const Color(0xFFE8F5E9), const Color(0xFF4A6136)),
                          const SizedBox(width: 8),
                          _buildBadge(isLocked ? 'LOCKED' : 'ACTIVE', isLocked ? Colors.red[50]! : Colors.green[50]!, isLocked ? Colors.red : Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF4A6136),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF4A6136),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Thông tin'),
              Tab(text: 'Chỉnh sửa'),
              Tab(text: 'Lịch sử'),
            ],
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildEditTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Edit Tab Implementation
  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Safety check: Don't allow admin to lock themselves (simplified check)
    // In a real app, you'd compare with FirebaseAuth.instance.currentUser.uid
    // Here we'll just proceed but you should be careful.

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userData['id']).update({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'skill_level': _selectedSkill,
        'role': _selectedRole,
        'is_locked': !_isActive,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật thông tin thành công')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildEditTab() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Họ và tên', _nameController, Icons.person),
            _buildTextField('Số điện thoại', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
            
            const SizedBox(height: 15),
            const Text('Trình độ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            _buildDropdown(['Mới bắt đầu', 'Chơi ổn', 'Chơi tốt'], _selectedSkill, (val) => setState(() => _selectedSkill = val!)),
            
            const SizedBox(height: 20),
            const Text('Vai trò', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            _buildDropdown(['player', 'admin'], _selectedRole, (val) => setState(() => _selectedRole = val!)),

            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Trạng thái tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_isActive ? 'Đang hoạt động' : 'Đã bị khóa'),
              value: _isActive,
              activeColor: const Color(0xFF4A6136),
              onChanged: (val) => setState(() => _isActive = val),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6136),
                  shape: RoundedRectangle_circular(12),
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('LƯU THAY ĐỔI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF4A6136)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4A6136), width: 2),
          ),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Không được để trống' : null,
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Thay thế RoundedRectangleBorder bằng helper function đơn giản nếu không muốn import
  OutlinedBorder RoundedRectangle_circular(double radius) => RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoTab() {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoRow(Icons.phone, 'Số điện thoại', widget.userData['phone'] ?? 'Chưa cập nhật'),
          _buildInfoRow(Icons.email, 'Email', widget.userData['email'] ?? 'Chưa cập nhật'),
          _buildInfoRow(Icons.wallet, 'Số dư ví', '${currencyFormatter.format(widget.userData['wallet_balance'] ?? 0)} đ'),
          _buildInfoRow(Icons.sports_tennis, 'Trình độ', widget.userData['skill_level'] ?? 'Mới bắt đầu'),
          _buildInfoRow(Icons.stars, 'Điểm uy tín', '${widget.userData['reliability_score'] ?? 100}%'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4A6136).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF4A6136), size: 20),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Color(0xFF4A6136),
            indicatorColor: Color(0xFF4A6136),
            tabs: [
              Tab(icon: Icon(Icons.calendar_month), text: 'Đặt lịch'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Giao dịch'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildHistoryList('Chưa có lịch sử đặt lịch'),
                _buildHistoryList('Chưa có lịch sử giao dịch'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(String emptyMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
