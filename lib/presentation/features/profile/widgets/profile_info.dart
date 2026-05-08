import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ProfileInfo extends StatelessWidget {
  final String name;
  final String skillLevel;
  final String? avatarBase64;
  final int totalMatches;
  final double reliability;
  final double attendance;

  const ProfileInfo({
    super.key,
    required this.name,
    required this.skillLevel,
    this.avatarBase64,
    this.totalMatches = 0,
    this.reliability = 5.0,
    this.attendance = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Large Avatar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF4A6136), width: 2),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: (avatarBase64 != null && avatarBase64!.isNotEmpty)
                ? MemoryImage(base64Decode(avatarBase64!))
                : null,
            child: (avatarBase64 == null || avatarBase64!.isEmpty)
                ? const Icon(Icons.person, size: 50, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        // Name
        Text(
          name.toUpperCase(),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        // Skill Level
        Text(
          '[ Trình độ: $skillLevel ]',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF4A6136),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        // Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStat('Số trận', '$totalMatches'),
            _buildDivider(),
            _buildStat('Uy tín', '⭐ ${reliability.toStringAsFixed(1)}'),
            _buildDivider(),
            _buildStat('Chuyên cần', '${attendance.toInt()}%'),
          ],
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            children: [
              TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.normal)),
              TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Text('|', style: TextStyle(color: Colors.grey, fontSize: 16)),
    );
  }
}
