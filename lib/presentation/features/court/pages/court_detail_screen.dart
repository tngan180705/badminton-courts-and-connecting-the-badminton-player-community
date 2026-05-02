import 'package:flutter/material.dart';
import '../../../../data/models/court_model.dart';

class CourtDetailScreen extends StatelessWidget {
  final CourtModel court; // Nhận dữ liệu truyền sang

  const CourtDetailScreen({super.key, required this.court});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(court.name),
        backgroundColor: const Color(0xFFA2AD5B),
      ),
      body: Center(
        child: Text(
          "Đây là chi tiết sân: ${court.name}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
