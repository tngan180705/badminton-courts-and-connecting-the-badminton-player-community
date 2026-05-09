import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/repositories/user_repository.dart';
import '../providers/admin_users_provider.dart';

// ═══════════════════════════════════════════════════════════
// FILTER STATE  (enum + data class)
// ═══════════════════════════════════════════════════════════

enum _StatusFilter { all, active, disabled }

enum _RoleFilter { all, admin, player }

class _AdvancedFilter {
  final _StatusFilter status;
  final _RoleFilter role;
  final String? skillLevel;
  final DateTimeRange? joinedRange;

  const _AdvancedFilter({
    this.status = _StatusFilter.all,
    this.role = _RoleFilter.all,
    this.skillLevel,
    this.joinedRange,
  });

  bool get hasActive =>
      status != _StatusFilter.all ||
      role != _RoleFilter.all ||
      skillLevel != null ||
      joinedRange != null;

  _AdvancedFilter copyWith({
    _StatusFilter? status,
    _RoleFilter? role,
    Object? skillLevel = _sentinel,
    Object? joinedRange = _sentinel,
  }) {
    return _AdvancedFilter(
      status: status ?? this.status,
      role: role ?? this.role,
      skillLevel:
          skillLevel == _sentinel ? this.skillLevel : skillLevel as String?,
      joinedRange: joinedRange == _sentinel
          ? this.joinedRange
          : joinedRange as DateTimeRange?,
    );
  }
}

const _sentinel = Object();

// ═══════════════════════════════════════════════════════════
// PAGE
// ═══════════════════════════════════════════════════════════

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  String _search = '';
  _AdvancedFilter _filter = const _AdvancedFilter();
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Apply filter + search ──────────────────────────────
  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> users) {
    final q = _search.toLowerCase();

    return users.where((u) {
      final name = (u['full_name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final role = (u['role'] ?? 'player').toString();
      final active = u['is_active'] ?? true;
      final skill = (u['skill_level'] ?? '').toString();
      final createdAt = u['created_at'];

      // Search
      final matchSearch = q.isEmpty || name.contains(q) || email.contains(q);

      // Status filter
      final matchStatus = switch (_filter.status) {
        _StatusFilter.all => true,
        _StatusFilter.active => active == true,
        _StatusFilter.disabled => active == false,
      };

      // Role filter
      final matchRole = switch (_filter.role) {
        _RoleFilter.all => true,
        _RoleFilter.admin => role == 'admin',
        _RoleFilter.player => role == 'player',
      };

      // Skill filter
      final matchSkill =
          _filter.skillLevel == null || skill == _filter.skillLevel;

      // Date range filter
      bool matchDate = true;
      if (_filter.joinedRange != null && createdAt is DateTime) {
        matchDate = createdAt.isAfter(
                _filter.joinedRange!.start.subtract(const Duration(days: 1))) &&
            createdAt.isBefore(
                _filter.joinedRange!.end.add(const Duration(days: 1)));
      }

      return matchSearch && matchStatus && matchRole && matchSkill && matchDate;
    }).toList();
  }

  // ── Export CSV ─────────────────────────────────────────
  void _exportCsv(List<Map<String, dynamic>> users) {
    final filtered = _applyFilter(users);
    final buf = StringBuffer();
    buf.writeln(
        'ID,Họ tên,Email,Điện thoại,Giới tính,Vai trò,Trình độ,Ví (đ),Độ tin cậy,Trạng thái,Ngày tham gia');

    for (final u in filtered) {
      final createdAt = u['created_at'];
      final dateStr = createdAt is DateTime
          ? DateFormat('dd/MM/yyyy').format(createdAt)
          : '';

      buf.writeln([
        u['id'] ?? '',
        u['full_name'] ?? '',
        u['email'] ?? '',
        u['phone'] ?? '',
        u['gender'] ?? '',
        u['role'] ?? 'player',
        u['skill_level'] ?? '',
        (u['wallet_balance'] as num?)?.toInt() ?? 0,
        (u['reliability_score'] as num?)?.toInt() ?? 100,
        (u['is_active'] ?? true) ? 'Hoạt động' : 'Bị khoá',
        dateStr,
      ].map((e) => '"$e"').join(','));
    }

    // Show CSV in dialog (no file-system access in Flutter web/mobile)
    showDialog(
      context: context,
      builder: (_) => _CsvExportDialog(csv: buf.toString(), count: filtered.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersStreamProvider);

    return Column(
      children: [
        // ── TOOLBAR ──────────────────────────────────────
        _Toolbar(
          searchCtrl: _searchCtrl,
          filter: _filter,
          onSearch: (v) => setState(() => _search = v),
          onFilterChanged: (f) => setState(() => _filter = f),
          onExport: () => usersAsync.whenData(_exportCsv),
        ),

        // ── ACTIVE FILTER CHIPS ──────────────────────────
        if (_filter.hasActive)
          _ActiveFilterBar(
            filter: _filter,
            onClear: () => setState(() => _filter = const _AdvancedFilter()),
          ),

        // ── LIST ─────────────────────────────────────────
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(
              child:
                  Text('Lỗi: $e', style: const TextStyle(color: AppColors.error)),
            ),
            data: (users) {
              final filtered = _applyFilter(users);

              if (filtered.isEmpty) {
                return _EmptyState(query: _search, hasFilter: _filter.hasActive);
              }

              return Column(
                children: [
                  // Stats bar
                  _StatsBar(total: users.length, shown: filtered.length),

                  // List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _UserCard(
                        data: filtered[i],
                        onChanged: () => ref.invalidate(adminUsersStreamProvider),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TOOLBAR
// ═══════════════════════════════════════════════════════════

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.searchCtrl,
    required this.filter,
    required this.onSearch,
    required this.onFilterChanged,
    required this.onExport,
  });

  final TextEditingController searchCtrl;
  final _AdvancedFilter filter;
  final ValueChanged<String> onSearch;
  final ValueChanged<_AdvancedFilter> onFilterChanged;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        children: [
          // Row: Search + Filter btn + Export btn
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchCtrl,
                  onChanged: onSearch,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên, email…',
                    hintStyle: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.primary, size: 20),
                    suffixIcon: searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon:
                                const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              searchCtrl.clear();
                              onSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusXL),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Advanced filter button
              _ToolbarBtn(
                icon: Icons.tune_rounded,
                label: 'Lọc',
                badge: filter.hasActive,
                color: filter.hasActive ? AppColors.primary : AppColors.textSecondary,
                onTap: () => _showAdvancedFilter(context),
              ),

              const SizedBox(width: 8),

              // Export button
              _ToolbarBtn(
                icon: Icons.download_rounded,
                label: 'CSV',
                color: AppColors.secondary,
                onTap: onExport,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Quick role + status row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...[
                  (_StatusFilter.all, 'Tất cả', Icons.people_rounded),
                  (_StatusFilter.active, 'Hoạt động', Icons.check_circle_rounded),
                  (_StatusFilter.disabled, 'Bị khoá', Icons.block_rounded),
                ].map((c) {
                  final (val, label, icon) = c;
                  final sel = filter.status == val;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      selected: sel,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon,
                              size: 12,
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              )),
                        ],
                      ),
                      selectedColor: AppColors.accent,
                      backgroundColor: AppColors.background,
                      checkmarkColor: AppColors.primary,
                      side: BorderSide.none,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      onSelected: (_) => onFilterChanged(
                          filter.copyWith(status: val)),
                    ),
                  );
                }),

                Container(
                    width: 1, height: 24, color: AppColors.inputBorder),
                const SizedBox(width: 6),

                ...[
                  (_RoleFilter.all, 'Tất cả vai trò'),
                  (_RoleFilter.admin, 'Admin'),
                  (_RoleFilter.player, 'Player'),
                ].map((c) {
                  final (val, label) = c;
                  final sel = filter.role == val;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: FilterChip(
                      selected: sel,
                      label: Text(label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          )),
                      selectedColor: AppColors.accent,
                      backgroundColor: AppColors.background,
                      checkmarkColor: AppColors.primary,
                      side: BorderSide.none,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      onSelected: (_) =>
                          onFilterChanged(filter.copyWith(role: val)),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAdvancedFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdvancedFilterSheet(
        current: filter,
        onApply: onFilterChanged,
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  const _ToolbarBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (badge)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: AppColors.error, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ADVANCED FILTER BOTTOM SHEET
// ═══════════════════════════════════════════════════════════

class _AdvancedFilterSheet extends StatefulWidget {
  const _AdvancedFilterSheet({required this.current, required this.onApply});

  final _AdvancedFilter current;
  final ValueChanged<_AdvancedFilter> onApply;

  @override
  State<_AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<_AdvancedFilterSheet> {
  late _AdvancedFilter _local;

  static const _skills = [
    'Mới bắt đầu', 'Chơi ổn', 'Chơi tốt'
  ];

  @override
  void initState() {
    super.initState();
    _local = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bộ lọc nâng cao',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: () => setState(
                    () => _local = const _AdvancedFilter()),
                child: const Text('Xóa tất cả',
                    style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Skill level
          const Text('Trình độ',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _FilterOption(
                label: 'Tất cả',
                selected: _local.skillLevel == null,
                onTap: () => setState(
                    () => _local = _local.copyWith(skillLevel: null)),
              ),
              ..._skills.map((s) => _FilterOption(
                    label: s,
                    selected: _local.skillLevel == s,
                    onTap: () => setState(
                        () => _local = _local.copyWith(skillLevel: s)),
                  )),
            ],
          ),

          const SizedBox(height: 20),

          // Date range
          const Text('Ngày tham gia',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          GestureDetector(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: now,
                initialDateRange: _local.joinedRange ??
                    DateTimeRange(
                      start: now.subtract(const Duration(days: 30)),
                      end: now,
                    ),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: AppColors.white,
                      surface: AppColors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setState(() => _local = _local.copyWith(joinedRange: picked));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: _local.joinedRange != null
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range_rounded,
                      size: 18,
                      color: _local.joinedRange != null
                          ? AppColors.primary
                          : AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    _local.joinedRange != null
                        ? '${DateFormat('dd/MM/yyyy').format(_local.joinedRange!.start)} → ${DateFormat('dd/MM/yyyy').format(_local.joinedRange!.end)}'
                        : 'Chọn khoảng thời gian',
                    style: TextStyle(
                        fontSize: 13,
                        color: _local.joinedRange != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary),
                  ),
                  const Spacer(),
                  if (_local.joinedRange != null)
                    GestureDetector(
                      onTap: () => setState(
                          () => _local = _local.copyWith(joinedRange: null)),
                      child: const Icon(Icons.clear_rounded,
                          size: 16, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                widget.onApply(_local);
                Navigator.pop(context);
              },
              child: const Text('Áp dụng',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  const _FilterOption(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ACTIVE FILTER BAR (khi đang có filter)
// ═══════════════════════════════════════════════════════════

class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({required this.filter, required this.onClear});

  final _AdvancedFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final tags = <String>[];
    if (filter.skillLevel != null) tags.add('Trình độ: ${filter.skillLevel}');
    if (filter.joinedRange != null) {
      tags.add(
          '${DateFormat('dd/MM').format(filter.joinedRange!.start)}–${DateFormat('dd/MM').format(filter.joinedRange!.end)}');
    }

    return Container(
      color: AppColors.accent.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded,
              size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Wrap(
              spacing: 6,
              children: tags
                  .map((t) => Chip(
                        label:
                            Text(t, style: const TextStyle(fontSize: 11)),
                        backgroundColor: AppColors.accent.withOpacity(0.3),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 28),
                foregroundColor: AppColors.error),
            child: const Text('Xóa lọc', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// STATS BAR
// ═══════════════════════════════════════════════════════════

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.total, required this.shown});

  final int total;
  final int shown;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Hiển thị $shown / $total người dùng',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// USER CARD
// ═══════════════════════════════════════════════════════════

class _UserCard extends StatefulWidget {
  const _UserCard({required this.data, required this.onChanged});

  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _loading = false;

  Future<void> _update(Map<String, dynamic> patch) async {
    setState(() => _loading = true);
    try {
      await UserRepository()
          .updateUser(userId: widget.data['id'], data: patch);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final name = d['full_name'] ?? '';
    final email = d['email'] ?? '';
    final role = (d['role'] ?? 'player').toString();
    final active = d['is_active'] ?? true;
    final phone = d['phone'] ?? '';
    final skill = d['skill_level'] ?? '';
    final wallet = (d['wallet_balance'] as num?)?.toDouble() ?? 0;
    final score = (d['reliability_score'] as num?)?.toDouble() ?? 100;
    final isAdmin = role == 'admin';

    return GestureDetector(
      onTap: () => _showDetail(context, d),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          border: Border.all(
            color: active
                ? Colors.transparent
                : AppColors.error.withOpacity(0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Main row ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _Avatar(name: name, isAdmin: isAdmin, isActive: active),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(name,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (!active)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('LOCKED',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(email,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _Chip(
                                label: isAdmin ? 'ADMIN' : 'PLAYER',
                                color: isAdmin
                                    ? AppColors.error
                                    : AppColors.primary),
                            const SizedBox(width: 6),
                            _Chip(
                                label: skill,
                                color: AppColors.secondary),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Loading / actions
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary)),
                    )
                  else
                    _Actions(
                      isActive: active,
                      isAdmin: isAdmin,
                      onToggleActive: () => _update({'is_active': !active}),
                      onToggleRole: () =>
                          _update({'role': isAdmin ? 'player' : 'admin'}),
                    ),
                ],
              ),
            ),

            // ── Stats strip ──────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppSizes.radiusXL),
                  bottomRight: Radius.circular(AppSizes.radiusXL),
                ),
              ),
              child: Row(
                children: [
                  _StatChip(
                      icon: Icons.phone_rounded,
                      label: phone.isNotEmpty ? phone : '–',
                      color: AppColors.primary),
                  _StatChip(
                      icon: Icons.account_balance_wallet_rounded,
                      label:
                          '${NumberFormat('#,##0', 'vi_VN').format(wallet)}đ',
                      color: AppColors.secondary),
                  _StatChip(
                      icon: Icons.star_rounded,
                      label: '${score.toInt()}%',
                      color: const Color(0xFF5B8A3C)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(data: d, onChanged: widget.onChanged),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ACTION BUTTONS
// ═══════════════════════════════════════════════════════════

class _Actions extends StatelessWidget {
  const _Actions({
    required this.isActive,
    required this.isAdmin,
    required this.onToggleActive,
    required this.onToggleRole,
  });

  final bool isActive;
  final bool isAdmin;
  final VoidCallback onToggleActive;
  final VoidCallback onToggleRole;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionBtn(
          label: isActive ? 'Khoá' : 'Mở',
          icon: isActive ? Icons.lock_rounded : Icons.lock_open_rounded,
          color: isActive ? AppColors.error : const Color(0xFF5B8A3C),
          onTap: onToggleActive,
        ),
        const SizedBox(height: 6),
        _ActionBtn(
          label: isAdmin ? 'Demote' : 'Promote',
          icon: isAdmin
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
          color: AppColors.secondary,
          onTap: onToggleRole,
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 30,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon, size: 13),
        label: Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700)),
        onPressed: onTap,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// USER DETAIL BOTTOM SHEET  (với tab: Info / Edit / Lịch sử)
// ═══════════════════════════════════════════════════════════

class _UserDetailSheet extends ConsumerStatefulWidget {
  const _UserDetailSheet({required this.data, required this.onChanged});

  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  @override
  ConsumerState<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends ConsumerState<_UserDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final name = d['full_name'] ?? '';
    final email = d['email'] ?? '';
    final role = (d['role'] ?? 'player').toString();
    final active = d['is_active'] ?? true;
    final userId = d['id'] ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.45,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.inputBorder,
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  _Avatar(
                      name: name,
                      isAdmin: role == 'admin',
                      isActive: active,
                      radius: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: AppTextStyles.heading2
                                .copyWith(fontSize: 17)),
                        Text(email,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _Chip(
                                label: role.toUpperCase(),
                                color: role == 'admin'
                                    ? AppColors.error
                                    : AppColors.primary),
                            const SizedBox(width: 6),
                            _Chip(
                                label: active ? 'ACTIVE' : 'LOCKED',
                                color: active
                                    ? const Color(0xFF5B8A3C)
                                    : AppColors.error),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tab bar
            Container(
              color: AppColors.white,
              child: TabBar(
                controller: _tab,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'Thông tin'),
                  Tab(text: 'Chỉnh sửa'),
                  Tab(text: 'Lịch sử'),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  // TAB 1 – Info
                  _InfoTab(data: d, scrollCtrl: controller),

                  // TAB 2 – Edit
                  _EditTab(
                    data: d,
                    onSaved: () {
                      widget.onChanged();
                      Navigator.pop(context);
                    },
                  ),

                  // TAB 3 – History
                  _HistoryTab(userId: userId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 1 — INFO
// ═══════════════════════════════════════════════════════════

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.data, required this.scrollCtrl});

  final Map<String, dynamic> data;
  final ScrollController scrollCtrl;

  @override
  Widget build(BuildContext context) {
    final phone = data['phone'] ?? '';
    final gender = data['gender'] ?? '';
    final skill = data['skill_level'] ?? '';
    final wallet = (data['wallet_balance'] as num?)?.toDouble() ?? 0;
    final score = (data['reliability_score'] as num?)?.toDouble() ?? 100;
    final createdAt = data['created_at'];
    final dateStr = createdAt is DateTime
        ? DateFormat('dd/MM/yyyy').format(createdAt)
        : '–';

    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(20),
      children: [
        _DetailRow(
            icon: Icons.phone_rounded, label: 'Điện thoại', value: phone),
        _DetailRow(icon: Icons.wc_rounded, label: 'Giới tính', value: gender),
        _DetailRow(
            icon: Icons.sports_tennis_rounded,
            label: 'Trình độ',
            value: skill),
        _DetailRow(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Số dư ví',
          value: '${NumberFormat('#,##0', 'vi_VN').format(wallet)}đ',
          valueColor: AppColors.primary,
        ),
        _DetailRow(
          icon: Icons.star_rounded,
          label: 'Độ tin cậy',
          value: '${score.toInt()}%',
          valueColor: score >= 80
              ? const Color(0xFF5B8A3C)
              : score >= 50
                  ? AppColors.secondary
                  : AppColors.error,
        ),
        _DetailRow(
          icon: Icons.calendar_today_rounded,
          label: 'Ngày tham gia',
          value: dateStr,
        ),
        _DetailRow(
          icon: Icons.badge_rounded,
          label: 'User ID',
          value: data['id'] ?? '',
          valueColor: AppColors.textSecondary,
        ),
        const SizedBox(height: 16),

        // Reliability bar
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Độ tin cậy',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text('${score.toInt()}%',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: score / 100,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(
                  score >= 80
                      ? const Color(0xFF5B8A3C)
                      : score >= 50
                          ? AppColors.secondary
                          : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 2 — EDIT
// ═══════════════════════════════════════════════════════════

class _EditTab extends StatefulWidget {
  const _EditTab({required this.data, required this.onSaved});

  final Map<String, dynamic> data;
  final VoidCallback onSaved;

  @override
  State<_EditTab> createState() => _EditTabState();
}

class _EditTabState extends State<_EditTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _scoreCtrl;
  late final TextEditingController _walletCtrl;
  late String _gender;
  late String _skillLevel;
  late bool _isActive;
  late String _role;
  bool _saving = false;

  static const _genders = ['Nam', 'Nữ', 'Khác'];
  static const _skills = [
    'Mới bắt đầu', 'Chơi ổn', 'Chơi tốt'
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _nameCtrl =
        TextEditingController(text: d['full_name'] ?? '');
    _phoneCtrl = TextEditingController(text: d['phone'] ?? '');
    _scoreCtrl = TextEditingController(
        text: ((d['reliability_score'] as num?)?.toInt() ?? 100).toString());
    _walletCtrl = TextEditingController(
        text: ((d['wallet_balance'] as num?)?.toInt() ?? 0).toString());
    _gender = (d['gender'] ?? 'Nam').toString();
    _skillLevel = (d['skill_level'] ?? 'Mới bắt đầu').toString();
    _isActive = d['is_active'] ?? true;
    _role = (d['role'] ?? 'player').toString();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _scoreCtrl.dispose();
    _walletCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await UserRepository().updateUser(
        userId: widget.data['id'],
        data: {
          'full_name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'gender': _gender,
          'skill_level': _skillLevel,
          'is_active': _isActive,
          'role': _role,
          'reliability_score': double.tryParse(_scoreCtrl.text) ?? 100,
          'wallet_balance': double.tryParse(_walletCtrl.text) ?? 0,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Cập nhật thành công'),
              backgroundColor: Color(0xFF5B8A3C)),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Họ tên
            _FormField(
              label: 'Họ và tên',
              controller: _nameCtrl,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Không được bỏ trống' : null,
            ),

            const SizedBox(height: 14),

            // Điện thoại
            _FormField(
              label: 'Số điện thoại',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 14),

            // Giới tính
            _DropdownField<String>(
              label: 'Giới tính',
              value: _gender,
              items: _genders,
              onChanged: (v) => setState(() => _gender = v!),
            ),

            const SizedBox(height: 14),

            // Trình độ
            _DropdownField<String>(
              label: 'Trình độ',
              value: _skillLevel,
              items: _skills,
              onChanged: (v) => setState(() => _skillLevel = v!),
            ),

            const SizedBox(height: 14),

            // Wallet
            _FormField(
              label: 'Số dư ví (đ)',
              controller: _walletCtrl,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  double.tryParse(v ?? '') == null ? 'Nhập số hợp lệ' : null,
            ),

            const SizedBox(height: 14),

            // Reliability score
            _FormField(
              label: 'Độ tin cậy (%)',
              controller: _scoreCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null) return 'Nhập số hợp lệ';
                if (n < 0 || n > 100) return 'Phải từ 0–100';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Toggle: Trạng thái
            _SwitchRow(
              label: 'Tài khoản hoạt động',
              value: _isActive,
              activeColor: const Color(0xFF5B8A3C),
              onChanged: (v) => setState(() => _isActive = v),
            ),

            const SizedBox(height: 8),

            // Toggle: Vai trò
            _SwitchRow(
              label: 'Là Admin',
              value: _role == 'admin',
              activeColor: AppColors.error,
              onChanged: (v) =>
                  setState(() => _role = v ? 'admin' : 'player'),
            ),

            const SizedBox(height: 28),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white))
                    : const Text('Lưu thay đổi',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: value,
              items: items
                  .map((i) => DropdownMenuItem(
                      value: i,
                      child: Text(i.toString(),
                          style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        Switch(
          value: value,
          activeColor: activeColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 3 — HISTORY (booking + transaction)
// ═══════════════════════════════════════════════════════════

class _HistoryTab extends ConsumerStatefulWidget {
  const _HistoryTab({required this.userId});

  final String userId;

  @override
  ConsumerState<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<_HistoryTab>
    with SingleTickerProviderStateMixin {
  late TabController _sub;

  @override
  void initState() {
    super.initState();
    _sub = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _sub.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub tab bar
        Container(
          color: AppColors.background.withOpacity(0.5),
          child: TabBar(
            controller: _sub,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(
                  icon: Icon(Icons.book_online_rounded, size: 16),
                  text: 'Bookings'),
              Tab(
                  icon: Icon(Icons.receipt_long_rounded, size: 16),
                  text: 'Giao dịch'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _sub,
            children: [
              _BookingHistoryList(userId: widget.userId),
              _TransactionHistoryList(userId: widget.userId),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookingHistoryList extends ConsumerWidget {
  const _BookingHistoryList({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userBookingsProvider(userId));

    return async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(
          child: Text('Lỗi: $e',
              style: const TextStyle(color: AppColors.error))),
      data: (bookings) {
        if (bookings.isEmpty) {
          return const _HistoryEmpty(label: 'Chưa có booking nào');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _BookingTile(data: bookings[i]),
        );
      },
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? '').toString();
    final courtName = data['court_name'] ?? data['court_id'] ?? '–';
    final date = data['booking_date'] ?? '–';
    final totalPrice = (data['total_price'] as num?)?.toInt() ?? 0;
    final createdAt = data['created_at'];
    final dateStr = createdAt is DateTime
        ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt)
        : '';

    final statusColor = switch (status) {
      'confirmed' => const Color(0xFF5B8A3C),
      'cancelled' => AppColors.error,
      'pending' => AppColors.secondary,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sports_tennis_rounded,
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(courtName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text(dateStr,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${NumberFormat('#,##0', 'vi_VN').format(totalPrice)}đ',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionHistoryList extends ConsumerWidget {
  const _TransactionHistoryList({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userTransactionsProvider(userId));

    return async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(
          child: Text('Lỗi: $e',
              style: const TextStyle(color: AppColors.error))),
      data: (transactions) {
        if (transactions.isEmpty) {
          return const _HistoryEmpty(label: 'Chưa có giao dịch nào');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _TransactionTile(data: transactions[i]),
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final type = (data['type'] ?? '').toString();
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final status = (data['status'] ?? '').toString();
    final createdAt = data['created_at'];
    final dateStr = createdAt is DateTime
        ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt)
        : '';

    final isDeposit = type == 'deposit' || amount > 0;
    final amountColor =
        isDeposit ? const Color(0xFF5B8A3C) : AppColors.error;
    final amountPrefix = isDeposit ? '+' : '-';

    final statusColor = switch (status) {
      'completed' || 'success' => const Color(0xFF5B8A3C),
      'failed' => AppColors.error,
      _ => AppColors.secondary,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: amountColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDeposit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 18,
              color: amountColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.isEmpty ? 'Giao dịch' : type,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text(dateStr,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountPrefix${NumberFormat('#,##0', 'vi_VN').format(amount.abs())}đ',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: amountColor),
              ),
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded,
              size: 48, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CSV EXPORT DIALOG
// ═══════════════════════════════════════════════════════════

class _CsvExportDialog extends StatelessWidget {
  const _CsvExportDialog({required this.csv, required this.count});

  final String csv;
  final int count;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.download_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Export CSV ($count users)'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dữ liệu CSV đã được tạo. Copy nội dung bên dưới hoặc lưu vào file.',
            style:
                TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            height: 160,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                csv,
                style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SHARED SMALL WIDGETS
// ═══════════════════════════════════════════════════════════

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query, required this.hasFilter});

  final String query;
  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 56,
              color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            query.isNotEmpty
                ? 'Không tìm thấy "$query"'
                : hasFilter
                    ? 'Không có user phù hợp với bộ lọc'
                    : 'Không có người dùng',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.isAdmin,
    required this.isActive,
    this.radius = 22,
  });

  final String name;
  final bool isAdmin;
  final bool isActive;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bg = isAdmin
        ? AppColors.error.withOpacity(0.15)
        : AppColors.primary.withOpacity(0.12);
    final fg = isAdmin ? AppColors.error : AppColors.primary;

    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: bg,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: fg,
                fontSize: radius * 0.9),
          ),
        ),
        if (!isActive)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  color: AppColors.white, shape: BoxShape.circle),
              child: const Icon(Icons.lock_rounded,
                  size: 10, color: AppColors.error),
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}