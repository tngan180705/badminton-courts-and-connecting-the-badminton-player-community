import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

class AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        AppSizes.cardPadding,
      ),

      decoration: BoxDecoration(
        color: AppColors.white,

        borderRadius: BorderRadius.circular(
          AppSizes.radiusXL,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.05,
            ),

            blurRadius: 12,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: color.withOpacity(0.12),

              borderRadius:
                  BorderRadius.circular(
                AppSizes.radiusL,
              ),
            ),

            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),

          AppSizes.wMedium,

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    color:
                        AppColors.textSecondary,

                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  value,
                  style: AppTextStyles
                      .heading2
                      .copyWith(
                        color: color,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}