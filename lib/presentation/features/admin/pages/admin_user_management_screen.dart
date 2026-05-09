import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../widgets/user_list_item.dart';

class AdminUserManagementScreen extends ConsumerStatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  ConsumerState<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends ConsumerState<AdminUserManagementScreen> {
  String _searchQuery = '';
  String _filterStatus = 'Tất cả';
  String _filterRole = 'Tất cả vai trò';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Column(
      children: [
        // Search & Filter Header
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF4A6136),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5CA),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm theo tên, email...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildIconButton(Icons.tune, 'Lọc'),
                  const SizedBox(width: 10),
                  _buildIconButton(Icons.download, 'CSV'),
                ],
              ),
              const SizedBox(height: 15),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả', Icons.people_outline),
                    const SizedBox(width: 8),
                    _buildFilterChip('Hoạt động', Icons.check_circle_outline),
                    const SizedBox(width: 8),
                    _buildFilterChip('Bị khoá', Icons.block_outlined),
                    const SizedBox(width: 15),
                    const VerticalDivider(color: Colors.white24, thickness: 1),
                    _buildRoleDropdown(),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Result Count
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(
                'Hiển thị ',
                style: TextStyle(color: Colors.black54),
              ),
              usersAsync.when(
                data: (users) {
                  final filtered = _filterUsers(users);
                  return Text(
                    '${filtered.length} / ${users.length} người dùng',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  );
                },
                loading: () => const Text('...'),
                error: (_, __) => const Text('0'),
              ),
            ],
          ),
        ),

        // User List
        Expanded(
          child: usersAsync.when(
            data: (users) {
              final filteredUsers = _filterUsers(users);
              if (filteredUsers.isEmpty) {
                return const Center(child: Text('Không tìm thấy người dùng nào'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  return UserListItem(userData: filteredUsers[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Lỗi: $e')),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _filterUsers(List<Map<String, dynamic>> users) {
    return users.where((u) {
      final nameMatch = (u['full_name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final emailMatch = (u['email'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool statusMatch = true;
      if (_filterStatus == 'Hoạt động') statusMatch = (u['is_locked'] ?? false) == false;
      if (_filterStatus == 'Bị khoá') statusMatch = (u['is_locked'] ?? false) == true;

      bool roleMatch = true;
      if (_filterRole != 'Tất cả vai trò') {
        roleMatch = (u['role'] ?? 'player').toString().toUpperCase() == _filterRole.toUpperCase();
      }

      return (nameMatch || emailMatch) && statusMatch && roleMatch;
    }).toList();
  }

  Widget _buildIconButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5CA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _filterStatus == label;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD9DF92) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white24),
        ),
        child: Row(
          children: [
            if (isSelected) const Icon(Icons.check, size: 16, color: Color(0xFF4A6136)),
            const SizedBox(width: 4),
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF4A6136) : Colors.white70),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF4A6136) : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD9DF92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterRole,
          items: ['Tất cả vai trò', 'Admin', 'Player'].map((r) {
            return DropdownMenuItem(value: r, child: Text(r));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _filterRole = val);
          },
          style: const TextStyle(color: Color(0xFF4A6136), fontWeight: FontWeight.bold),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4A6136)),
        ),
      ),
    );
  }
}
