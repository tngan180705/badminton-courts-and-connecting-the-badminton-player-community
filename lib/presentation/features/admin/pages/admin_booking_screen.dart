import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/sub_court_model.dart';
import '../../court/providers/court_provider.dart';
import './admin_main_screen.dart';

import '../../transaction/pages/viet_qr_payment_screen.dart';

class AdminBookingScreen extends ConsumerStatefulWidget {
  const AdminBookingScreen({super.key});

  @override
  ConsumerState<AdminBookingScreen> createState() => _AdminBookingScreenState();
}

class _AdminBookingScreenState extends ConsumerState<AdminBookingScreen> {
  late DateTime _selectedDate;
  SubCourtModel? _selectedSubCourt;
  final List<int> _selectedHours = [];
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _paymentMethod = 'Tiền mặt'; // 'Tiền mặt' or 'Chuyển khoản'
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  List<DateTime> _getNext7Days() {
    final now = DateTime.now();
    return List.generate(7, (i) => DateTime(now.year, now.month, now.day).add(Duration(days: i)));
  }

  Future<List<int>> _getAvailableHours(String subCourtId, DateTime date) async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    int startHour = 5;
    if (isToday) {
      startHour = now.hour; 
      if (startHour < 5) startHour = 5;
    }

    const int endHour = 22;

    final bookingsSnapshot = await db
        .collection('bookings')
        .where('sub_court_id', isEqualTo: subCourtId)
        .where('booking_date', isEqualTo: Timestamp.fromDate(date))
        .get();

    final bookedHours = <int>{};
    for (final doc in bookingsSnapshot.docs) {
      final status = doc['status'] as String?;
      if (status == 'cancelled') continue; 

      final startStr = doc['start_time'] as String?;
      final endStr = doc['end_time'] as String?;
      if (startStr != null && endStr != null) {
        final s = int.parse(startStr.split(':')[0]);
        final e = int.parse(endStr.split(':')[0]);
        for (int h = s; h < e; h++) {
          bookedHours.add(h);
        }
      }
    }

    final available = <int>[];
    for (int h = 5; h <= endHour; h++) {
      if (!bookedHours.contains(h)) {
        available.add(h);
      }
    }
    return available;
  }

  double _calculatePrice(List<int> hours) {
    if (hours.isEmpty) return 0;
    double total = 0;
    for (final h in hours) {
      final isGolden = (h >= 5 && h < 7) || (h >= 20 && h < 22);
      total += isGolden ? 40000 : 150000;
    }
    return total;
  }

  Future<void> _handleConfirm() async {
    if (_selectedSubCourt == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn sân')));
      return;
    }
    if (_selectedHours.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn giờ')));
      return;
    }
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập thông tin khách')));
      return;
    }

    _selectedHours.sort();
    for (int i = 0; i < _selectedHours.length - 1; i++) {
      if (_selectedHours[i+1] != _selectedHours[i] + 1) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn các khung giờ liên tiếp')));
        return;
      }
    }

    final startTime = '${_selectedHours.first.toString().padLeft(2, '0')}:00';
    final endTime = '${(_selectedHours.last + 1).toString().padLeft(2, '0')}:00';
    final totalPrice = _calculatePrice(_selectedHours);

    if (_paymentMethod == 'Tiền mặt') {
      setState(() => _isSaving = true);
      await _saveBooking();
      if (mounted) {
        // Chuyển sang tab Đặt lịch (Index 3)
        ref.read(adminMenuIndexProvider.notifier).state = 3;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt sân tiền mặt thành công!')));
        setState(() => _isSaving = false);
      }
    } else {
      // Chuyển khoản
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VietQRPaymentScreen(
            paymentType: 'full_payment',
            totalAmount: totalPrice,
            payAmount: totalPrice,
            courtName: 'Sân Cầu Lông Phạm Như Xương',
            subCourtName: _selectedSubCourt!.subCourtName,
            formattedDate: DateFormat('dd/MM/yyyy').format(_selectedDate),
            startTime: startTime,
            endTime: endTime,
            fullName: _nameController.text.trim(),
            onPaymentConfirmed: () async {
              await _saveBooking();
              if (mounted) {
                // Chuyển sang tab Dashboard (Index 0)
                ref.read(adminMenuIndexProvider.notifier).state = 0;
              }
            },
            popCount: 1,
          ),
        ),
      );
    }
  }

  Future<void> _saveBooking() async {
    try {
      final db = FirebaseFirestore.instance;
      
      // 1. Generate Booking ID
      final snapshot = await db.collection('bookings').get();
      int maxNum = 0;
      for (final doc in snapshot.docs) {
        if (doc.id.startsWith('BK_')) {
          final num = int.tryParse(doc.id.replaceFirst('BK_', '')) ?? 0;
          if (num > maxNum) maxNum = num;
        }
      }
      final bookingId = 'BK_${(maxNum + 1).toString().padLeft(3, '0')}';

      _selectedHours.sort();
      final startTime = '${_selectedHours.first.toString().padLeft(2, '0')}:00';
      final endTime = '${(_selectedHours.last + 1).toString().padLeft(2, '0')}:00';
      final totalPrice = _calculatePrice(_selectedHours);

      // 2. Create Booking
      await db.collection('bookings').doc(bookingId).set({
        'player_id': 'ADMIN_BOOKING',
        'sub_court_id': _selectedSubCourt!.subCourtId,
        'booking_date': Timestamp.fromDate(_selectedDate),
        'start_time': startTime,
        'end_time': endTime,
        'status': 'confirmed',
        'total_price': totalPrice.toInt(),
        'payment_method': _paymentMethod == 'Tiền mặt' ? 'Tiền mặt' : 'Chuyển khoản ngân hàng (Admin)',
        'check_in_status': false,
        'created_at': Timestamp.now(),
        'customer_name': _nameController.text.trim(),
        'customer_phone': _phoneController.text.trim(),
      });

      // 3. Create confirmed transaction record (for dashboard revenue)
      final txSnapshot = await db.collection('transactions').get();
      int maxTx = 0;
      for (final doc in txSnapshot.docs) {
        if (doc.id.startsWith('TX_')) {
          final num = int.tryParse(doc.id.replaceFirst('TX_', '')) ?? 0;
          if (num > maxTx) maxTx = num;
        }
      }
      final txId = 'TX_${(maxTx + 1).toString().padLeft(3, '0')}';
      
      await db.collection('transactions').doc(txId).set({
        'user_id': 'ADMIN_BOOKING',
        'booking_id': bookingId,
        'amount': totalPrice.toInt(),
        'type': 'payment',
        'payment_type': 'full_payment',
        'status': 'confirmed', // Confirmed immediately for admin
        'payment_method': _paymentMethod == 'Tiền mặt' ? 'cash' : 'bank_transfer',
        'transfer_content': 'ADMIN_${_nameController.text.trim()}_$bookingId',
        'created_at': Timestamp.now(),
      });

      // 4. Create Match Post (Full)
      final mpSnapshot = await db.collection('match_posts').get();
      int maxMP = 0;
      for (final doc in mpSnapshot.docs) {
        if (doc.id.startsWith('MP_')) {
          final num = int.tryParse(doc.id.replaceFirst('MP_', '')) ?? 0;
          if (num > maxMP) maxMP = num;
        }
      }
      final matchPostId = 'MP_${(maxMP + 1).toString().padLeft(3, '0')}';

      await db.collection('match_posts').doc(matchPostId).set({
        'host_id': 'ADMIN_BOOKING',
        'booking_id': bookingId,
        'title': 'Sân đã đặt (Admin)',
        'description': 'Khách: ${_nameController.text.trim()}',
        'slots_needed': 0,
        'status': 'full',
        'skill_level': 'Tất cả',
        'created_at': Timestamp.now(),
      });

      if (mounted) {
        setState(() {
          _selectedHours.clear();
          _nameController.clear();
          _phoneController.clear();
        });
      }
    } catch (e) {
      print('❌ Lỗi lưu booking admin: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subCourtsAsync = ref.watch(homeSubCourtsProvider);
    final next7Days = _getNext7Days();
    final totalPrice = _calculatePrice(_selectedHours);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Select Date
            const Text('1. Chọn ngày', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DateTime>(
                  isExpanded: true,
                  value: _selectedDate,
                  items: next7Days.map((d) {
                    final label = DateFormat('dd/MM/yyyy').format(d);
                    final isToday = d.year == DateTime.now().year && d.month == DateTime.now().month && d.day == DateTime.now().day;
                    return DropdownMenuItem(
                      value: d,
                      child: Text(isToday ? 'Hôm nay ($label)' : label),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() {
                      _selectedDate = val;
                      _selectedHours.clear();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Select Sub-court
            const Text('2. Chọn sân', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            subCourtsAsync.when(
              data: (list) {
                if (_selectedSubCourt == null && list.isNotEmpty) {
                  // Don't auto-set here during build, do it once or handle null
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<SubCourtModel>(
                      isExpanded: true,
                      value: _selectedSubCourt,
                      hint: const Text('Chọn sân'),
                      items: list.map((sc) => DropdownMenuItem(
                        value: sc,
                        child: Text(sc.subCourtName),
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedSubCourt = val;
                          _selectedHours.clear();
                        });
                      },
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Lỗi tải sân: $e'),
            ),
            const SizedBox(height: 20),

            // 3. Time Slots
            if (_selectedSubCourt != null) ...[
              const Text('3. Chọn giờ (Lọc giờ trống)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              FutureBuilder<List<int>>(
                future: _getAvailableHours(_selectedSubCourt!.subCourtId, _selectedDate),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final available = snapshot.data ?? [];
                  if (available.isEmpty) {
                    return const Center(child: Text('Hết giờ trống cho sân này', style: TextStyle(color: Colors.red)));
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(18, (index) {
                      final hour = index + 5; // 5:00 to 22:00
                      final isAvailable = available.contains(hour);
                      final isSelected = _selectedHours.contains(hour);

                      return FilterChip(
                        label: Text('${hour.toString().padLeft(2, '0')}:00'),
                        selected: isSelected,
                        onSelected: isAvailable ? (val) {
                          setState(() {
                            if (val) {
                              _selectedHours.add(hour);
                            } else {
                              _selectedHours.remove(hour);
                            }
                          });
                        } : null,
                        selectedColor: const Color(0xFFD9DF92),
                        checkmarkColor: const Color(0xFF4A6136),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF4A6136) : (isAvailable ? Colors.black87 : Colors.grey),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: Colors.white,
                        disabledColor: Colors.grey[200],
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            // 4. Customer Info
            const Text('4. Thông tin khách hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Tên khách hàng',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Số điện thoại',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 20),

            // 5. Payment Method
            const Text('5. Hình thức thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _paymentMethod = 'Tiền mặt'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _paymentMethod == 'Tiền mặt' ? const Color(0xFF4A6136).withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _paymentMethod == 'Tiền mặt' ? const Color(0xFF4A6136) : Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.money, color: _paymentMethod == 'Tiền mặt' ? const Color(0xFF4A6136) : Colors.grey),
                          const SizedBox(width: 8),
                          Text('Tiền mặt', style: TextStyle(color: _paymentMethod == 'Tiền mặt' ? const Color(0xFF4A6136) : Colors.black87, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _paymentMethod = 'Chuyển khoản'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _paymentMethod == 'Chuyển khoản' ? const Color(0xFF4A6136).withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _paymentMethod == 'Chuyển khoản' ? const Color(0xFF4A6136) : Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code, color: _paymentMethod == 'Chuyển khoản' ? const Color(0xFF4A6136) : Colors.grey),
                          const SizedBox(width: 8),
                          Text('Chuyển khoản', style: TextStyle(color: _paymentMethod == 'Chuyển khoản' ? const Color(0xFF4A6136) : Colors.black87, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 6. Summary & Confirm
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4A6136),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán:', style: TextStyle(color: Colors.white70)),
                      Text(
                        '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(totalPrice)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD9DF92),
                        foregroundColor: const Color(0xFF4A6136),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('XÁC NHẬN ĐẶT SÂN', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
