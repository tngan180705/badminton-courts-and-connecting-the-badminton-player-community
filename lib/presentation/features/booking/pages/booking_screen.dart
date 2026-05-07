import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/sub_court_model.dart';
import '../widgets/booking_header.dart';
import '../widgets/booking_date_picker.dart';
import '../widgets/booking_time_picker.dart';
import '../widgets/booking_price_summary.dart';
import '../pages/booking_detail_screen.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String courtName;
  final SubCourtModel subCourt;

  const BookingScreen({
    super.key,
    required this.courtName,
    required this.subCourt,
  });

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  void _proceedToDetails() {
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đầy đủ ngày và giờ')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailScreen(
          courtName: widget.courtName,
          subCourt: widget.subCourt,
          bookingDate: _selectedDate!,
          startTime: _startTime!,
          endTime: _endTime!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt sân'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Tên sân
              BookingHeader(
                courtName: widget.courtName,
                subCourt: widget.subCourt,
              ),
              const SizedBox(height: 20),

              // Date picker
              BookingDatePicker(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                    _startTime = null;
                    _endTime = null;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Time picker
              if (_selectedDate != null)
                BookingTimePicker(
                  startTime: _startTime,
                  endTime: _endTime,
                  selectedDate: _selectedDate!,
                  onStartTimeSelected: (time) {
                    setState(() => _startTime = time);
                  },
                  onEndTimeSelected: (time) {
                    setState(() => _endTime = time);
                  },
                ),
              const SizedBox(height: 20),

              // Price summary
              if (_startTime != null && _endTime != null)
                BookingPriceSummary(
                  startTime: _startTime!,
                  endTime: _endTime!,
                ),
              const SizedBox(height: 32),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _proceedToDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tiếp tục',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
