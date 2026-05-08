import 'package:flutter/material.dart';

class ReputationBar extends StatelessWidget {
  final double score; // 0.0 to 5.0
  final double minScore = 0.0;
  final double maxScore = 5.0;

  const ReputationBar({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final pointerPosition = (score / maxScore) * width;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // The Gradient Bar
                Container(
                  height: 12,
                  width: width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFE57373), // Red
                        Color(0xFFFFB74D), // Orange
                        Color(0xFFFFF176), // Yellow
                        Color(0xFF81C784), // Green
                        Color(0xFF43A047), // Dark Green
                      ],
                    ),
                  ),
                ),
                // The Pointer
                Positioned(
                  left: pointerPosition - 15,
                  top: -32,
                  child: SizedBox(
                    width: 30,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          score.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 24,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0', style: TextStyle(fontSize: 10, color: Colors.black54)),
            Text('3.0', style: TextStyle(fontSize: 10, color: Colors.black54)),
            // Removed the 5.0 label here to avoid overlap with pointer
            SizedBox(width: 10), 
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          '⚠ Dưới 3.0 tài khoản sẽ bị tạm khóa.',
          style: TextStyle(fontSize: 9, color: Colors.redAccent, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
