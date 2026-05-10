import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_booking_card.dart';

class AdminBookingManagementScreen extends ConsumerStatefulWidget {
  const AdminBookingManagementScreen({super.key});

  @override
  ConsumerState<AdminBookingManagementScreen> createState() => _AdminBookingManagementScreenState();
}

class _AdminBookingManagementScreenState extends ConsumerState<AdminBookingManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  bool _is7DaysFilter = false;
  String? _selectedSubCourtId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(adminBookingsProvider);
    final subCourtsAsync = ref.watch(subCourtsListProvider);
    final now = DateTime.now();
    final next7Days = List.generate(8, (i) => DateTime(now.year, now.month, now.day).add(Duration(days: i)));
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Column(
      children: [
        // Filters Header
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF4A6136),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Ngày:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5CA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DateTime>(
                          value: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
                          isExpanded: true,
                          items: next7Days.map((date) => DropdownMenuItem(
                            value: date,
                            child: Text(
                              date.day == now.day ? 'Hôm nay (${dateFormatter.format(date)})' : dateFormatter.format(date),
                            ),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedDate = val);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildFilterChip('7 ngày tới', _is7DaysFilter, () {
                    setState(() => _is7DaysFilter = !_is7DaysFilter);
                  }),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Text('Sân:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: subCourtsAsync.when(
                      data: (subCourts) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9DF92),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSubCourtId,
                            hint: const Text('Tất cả sân'),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Tất cả sân')),
                              ...subCourts.map((sc) => DropdownMenuItem(
                                value: sc['id'],
                                child: Text(sc['sub_court_name'] ?? 'Sân ${sc['id']}'),
                              )),
                            ],
                            onChanged: (val) => setState(() => _selectedSubCourtId = val),
                          ),
                        ),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('Lỗi'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Tabs
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4A6136),
          indicatorColor: const Color(0xFF4A6136),
          tabs: const [
            Tab(text: 'Sắp tới'),
            Tab(text: 'Yêu cầu huỷ'),
          ],
        ),

        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(bookingsAsync, 'upcoming'),
              _buildBookingList(bookingsAsync, 'cancellation_pending'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD9DF92) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4A6136) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingList(AsyncValue<List<Map<String, dynamic>>> bookingsAsync, String type) {
    return bookingsAsync.when(
      data: (bookings) {
        final filtered = _filterBookings(bookings, type);
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  type == 'upcoming' ? 'Không có lịch đặt sắp tới' : 'Không có yêu cầu huỷ nào',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return AdminBookingCard(bookingData: filtered[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }

  List<Map<String, dynamic>> _filterBookings(List<Map<String, dynamic>> bookings, String type) {
    final now = DateTime.now();
    return bookings.where((b) {
      DateTime bDate;
      if (b['booking_date'] is Timestamp) {
        bDate = (b['booking_date'] as Timestamp).toDate();
      } else if (b['booking_date'] is String) {
        bDate = DateTime.tryParse(b['booking_date'] as String) ?? DateTime.now();
      } else {
        bDate = (b['booking_date'] as DateTime?) ?? DateTime.now();
      }
      
      final isSameDay = bDate.year == _selectedDate.year && bDate.month == _selectedDate.month && bDate.day == _selectedDate.day;
      
      // Time filter for today
      bool isFuture = true;
      if (isSameDay && bDate.year == now.year && bDate.month == now.month && bDate.day == now.day) {
        final startTimeStr = b['start_time']?.toString() ?? '00:00';
        final startParts = startTimeStr.split(':');
        if (startParts.length == 2) {
          final startHour = int.tryParse(startParts[0]) ?? 0;
          final startMin = int.tryParse(startParts[1]) ?? 0;
          final startDateTime = DateTime(now.year, now.month, now.day, startHour, startMin);
          if (now.isAfter(startDateTime)) {
            isFuture = false; // Past match
          }
        }
      }

      bool dateMatch = isSameDay && isFuture;
      if (_is7DaysFilter) {
        final sevenDaysLater = now.add(const Duration(days: 7));
        dateMatch = bDate.isAfter(now.subtract(const Duration(seconds: 1))) && bDate.isBefore(sevenDaysLater.add(const Duration(days: 1)));
      }

      bool courtMatch = true;
      if (_selectedSubCourtId != null) {
        courtMatch = b['sub_court_id'] == _selectedSubCourtId;
      }

      if (type == 'cancellation_pending') {
        return b['status'] == 'cancellation_pending' && courtMatch;
      } else {
        // Upcoming includes confirmed and ongoing
        final isUpcoming = b['status'] == 'confirmed' || b['status'] == 'ongoing' || b['status'] == 'completed';
        return isUpcoming && dateMatch && courtMatch;
      }
    }).toList();
  }
}
