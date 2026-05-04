import 'package:flutter/material.dart';
import '../../../../data/models/sub_court_model.dart';

class CourtDetailScreen extends StatelessWidget {
  final SubCourtModel subCourt;
  final String courtName;

  const CourtDetailScreen({
    super.key,
    required this.subCourt,
    required this.courtName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subCourt.subCourtName),
        backgroundColor: const Color(0xFFA2AD5B),
      ),
      body: Center(
        child: Text(
          "Chi tiết: $courtName - ${subCourt.subCourtName}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
