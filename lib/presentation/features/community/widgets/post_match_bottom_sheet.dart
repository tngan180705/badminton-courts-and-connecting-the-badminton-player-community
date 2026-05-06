import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/sub_court_model.dart';
import '../providers/community_provider.dart';

class PostMatchBottomSheet extends ConsumerStatefulWidget {
  const PostMatchBottomSheet({super.key});

  @override
  ConsumerState<PostMatchBottomSheet> createState() =>
      _PostMatchBottomSheetState();
}

class _PostMatchBottomSheetState extends ConsumerState<PostMatchBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  SubCourtModel? _selectedSubCourt;
  List<SubCourtModel> _subCourts = [];

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  int _slotsNeeded = 2;
  String _skillLevel = 'Mới bắt đầu';
  bool _isLoading = false;
  bool _isLoadingCourts = true;

  final DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSubCourts();
  }

  Future<void> _loadSubCourts() async {
    try {
      final courtSnapshot =
          await FirebaseFirestore.instance.collection('courts').limit(1).get();
      if (courtSnapshot.docs.isEmpty) return;

      final courtId = courtSnapshot.docs.first.id;
      final subCourtSnapshot = await FirebaseFirestore.instance
          .collection('sub_courts')
          .where('court_id', isEqualTo: courtId)
          .where('is_active', isEqualTo: true)
          .get();

      setState(() {
        _subCourts = subCourtSnapshot.docs
            .map((doc) => SubCourtModel.fromFirestore(doc.data(), doc.id))
            .toList();
        if (_subCourts.isNotEmpty) _selectedSubCourt = _subCourts.first;
        _isLoadingCourts = false;
      });
    } catch (e) {
      setState(() => _isLoadingCourts = false);
    }
  }

  // Chọn ngày
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? _now,
      firstDate: _now, // Không cho chọn ngày quá khứ
      lastDate: _now.add(const Duration(days: 7)), // Tối đa 7 ngày tới
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // Reset giờ nếu đổi ngày
        _startTime = null;
        _endTime = null;
      });
    }
  }

  // Chọn giờ bắt đầu
  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 18, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        // Reset giờ kết thúc nếu không hợp lệ
        if (_endTime != null && !_isEndTimeValid(picked, _endTime!)) {
          _endTime = null;
        }
      });
    }
  }

  // Chọn giờ kết thúc
  Future<void> _pickEndTime() async {
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn giờ bắt đầu trước')),
      );
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (_startTime!.hour + 1).clamp(0, 23),
        minute: _startTime!.minute,
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      if (!_isEndTimeValid(_startTime!, picked)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giờ kết thúc phải sau giờ bắt đầu!'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      setState(() => _endTime = picked);
    }
  }

  bool _isEndTimeValid(TimeOfDay start, TimeOfDay end) {
    return end.hour > start.hour ||
        (end.hour == start.hour && end.minute > start.minute);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubCourt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn sân')),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày')),
      );
      return;
    }
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn giờ bắt đầu và kết thúc')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final db = FirebaseFirestore.instance;

      // 1. Generate ID MP_XXX
      final matchPostId = await _generateMatchPostId();

      // 2. Tạo booking
      final bookingRef = await db.collection('bookings').add({
        'player_id': currentUser.uid,
        'sub_court_id': _selectedSubCourt!.subCourtId,
        'booking_date': Timestamp.fromDate(_selectedDate!),
        'start_time': _formatTime(_startTime!),
        'end_time': _formatTime(_endTime!),
        'status': 'confirmed',
        'total_price': 150000,
        'payment_method': 'wallet',
        'check_in_status': false,
        'created_at': Timestamp.now(),
      });

      // 3. Tạo match_post với ID cụ thể
      await db.collection('match_posts').doc(matchPostId).set({
        'host_id': currentUser.uid,
        'booking_id': bookingRef.id,
        'title': 'Tìm $_slotsNeeded người chơi',
        'description': 'Trình độ: $_skillLevel',
        'slots_needed': _slotsNeeded,
        'status': 'open',
        'skill_level': _skillLevel,
        'created_at': Timestamp.now(),
      });

      // 4. Refresh
      ref.invalidate(communityPostsProvider);
      ref.invalidate(filteredPostsProvider);
      ref.invalidate(myPostsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng tin thành công!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Đăng tin tìm đồng đội',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Chọn sân
              const Text('Sân :',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              _isLoadingCourts
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<SubCourtModel>(
                      value: _selectedSubCourt,
                      decoration: _inputDecoration('Chọn sân'),
                      items: _subCourts
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.subCourtName),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedSubCourt = val),
                      validator: (val) =>
                          val == null ? 'Vui lòng chọn sân' : null,
                    ),
              const SizedBox(height: 12),

              // Chọn ngày
              const Text('Ngày :',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        _selectedDate != null
                            ? _formatDate(_selectedDate!)
                            : 'Chọn ngày (trong 7 ngày tới)',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedDate != null
                              ? AppColors.textPrimary
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Chọn giờ bắt đầu + kết thúc
              const Text('Thời gian :',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  // Giờ bắt đầu
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickStartTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              _startTime != null
                                  ? _formatTime(_startTime!)
                                  : 'Bắt đầu',
                              style: TextStyle(
                                fontSize: 14,
                                color: _startTime != null
                                    ? AppColors.textPrimary
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('—',
                        style: TextStyle(
                            fontSize: 18, color: AppColors.textSecondary)),
                  ),
                  // Giờ kết thúc
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickEndTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled,
                                size: 18, color: AppColors.secondary),
                            const SizedBox(width: 8),
                            Text(
                              _endTime != null
                                  ? _formatTime(_endTime!)
                                  : 'Kết thúc',
                              style: TextStyle(
                                fontSize: 14,
                                color: _endTime != null
                                    ? AppColors.textPrimary
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Số người
              const Text('Cần thêm bao nhiêu người?',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _slotsNeeded,
                decoration: _inputDecoration('Số người'),
                items: [1, 2, 3, 4]
                    .map((n) => DropdownMenuItem(
                          value: n,
                          child: Text('$n người'),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _slotsNeeded = val!),
              ),
              const SizedBox(height: 12),

              // Trình độ
              const Text('Trình độ yêu cầu:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: ['Mới bắt đầu', 'Chơi ổn', 'Chơi tốt']
                    .map((level) => Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _skillLevel = level),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: level,
                                  groupValue: _skillLevel,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) =>
                                      setState(() => _skillLevel = val!),
                                ),
                                Flexible(
                                  child: Text(level,
                                      style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),

              // Nút đăng
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Đăng ngay',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

// Thêm function này vào _PostMatchBottomSheetState
  Future<String> _generateMatchPostId() async {
    final db = FirebaseFirestore.instance;

    // Lấy tất cả match_posts
    final snapshot = await db.collection('match_posts').get();

    // Tìm số lớn nhất hiện tại
    int maxNum = 0;
    for (final doc in snapshot.docs) {
      final id = doc.id;
      if (id.startsWith('MP_')) {
        final numStr = id.replaceFirst('MP_', '');
        final num = int.tryParse(numStr) ?? 0;
        if (num > maxNum) maxNum = num;
      }
    }

    // Increment và format
    final nextNum = maxNum + 1;
    return 'MP_${nextNum.toString().padLeft(3, '0')}';
  }
}
