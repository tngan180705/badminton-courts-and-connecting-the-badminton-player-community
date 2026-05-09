import 'package:badminton_app/presentation/features/admin/pages/admin_revenue_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/admin_stats_model.dart';
import '../providers/admin_stats_provider.dart';
import '../widgets/admin_stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static final _currencyFormat = NumberFormat('#,##0', 'vi_VN');
  static const int _bookingTarget = 500;
  static const double _revenueTarget = 50000000;
  static const int _userTarget = 1000;
  static const double _mobileBreakpoint = 900;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final isMobile = MediaQuery.of(context).size.width < _mobileBreakpoint;

    return statsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppSizes.spaceSmall),
            Text('Lỗi tải dữ liệu: $e',
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ──────────────────────────────
            _Header(),
            AppSizes.hLarge,

            // ── KPI CARDS ────────────────────────────
            _KpiGrid(
              stats: stats,
              isMobile: isMobile,
              currencyFormat: _currencyFormat,
            ),
            AppSizes.hLarge,

            // ── ANALYTICS + OVERVIEW ─────────────────
            if (isMobile) ...[
              _RevenueCard(stats: stats, currencyFormat: _currencyFormat),
              AppSizes.hMedium,
              _QuickStatsColumn(stats: stats),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _RevenueCard(
                        stats: stats, currencyFormat: _currencyFormat),
                  ),
                  AppSizes.wMedium,
                  Expanded(child: _QuickStatsColumn(stats: stats)),
                ],
              ),

            AppSizes.hLarge,

            // ── PROGRESS ─────────────────────────────
            _ProgressCard(
              stats: stats,
              bookingTarget: _bookingTarget,
              revenueTarget: _revenueTarget,
              userTarget: _userTarget,
              currencyFormat: _currencyFormat,
            ),

            AppSizes.hLarge,
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// HEADER
// ══════════════════════════════════════════════

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard', style: AppTextStyles.heading1),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.dashboard_rounded,
              color: Colors.white, size: 22),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// KPI GRID — 4 cards
// ══════════════════════════════════════════════

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.stats,
    required this.isMobile,
    required this.currencyFormat,
  });

  final AdminStatsModel stats;
  final bool isMobile;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCardData(
        label: 'Người dùng',
        value: stats.totalUsers.toString(),
        icon: Icons.people_alt_rounded,
        color: AppColors.primary,
        sub: 'Tổng tài khoản',
      ),
      _KpiCardData(
        label: 'Sân cầu lông',
        value: stats.totalCourts.toString(),
        icon: Icons.sports_tennis_rounded,
        color: AppColors.secondary,
        sub: 'Sân đang hoạt động',
      ),
      _KpiCardData(
        label: 'Đặt sân',
        value: stats.totalBookings.toString(),
        icon: Icons.event_available_rounded,
        color: const Color(0xFF5B8A3C),
        sub: 'Tổng lượt đặt',
      ),
      _KpiCardData(
        label: 'Doanh thu',
        value: '${currencyFormat.format(stats.totalRevenue)}đ',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.primary,
        sub: 'Tổng thu',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: AppSizes.spaceMedium,
        mainAxisSpacing: AppSizes.spaceMedium,
        childAspectRatio: isMobile ? 1.1 : 1.15,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _KpiCard(data: cards[i]),
    );
  }
}

class _KpiCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String sub;
  const _KpiCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.sub,
  });
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});
  final _KpiCardData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusXL),
      onTap: () {
        if (data.label == 'Doanh thu') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminRevenueDetailScreen(),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          boxShadow: [
            BoxShadow(
              color: data.color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: Icon(data.icon, color: data.color, size: 20),
            ),

            // Value + label
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: data.color,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// REVENUE CARD — gradient header
// ══════════════════════════════════════════════

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.stats, required this.currencyFormat});

  final AdminStatsModel stats;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient header ──
          Container(
            padding: const EdgeInsets.all(AppSizes.cardPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusXL),
                topRight: Radius.circular(AppSizes.radiusXL),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng doanh thu',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Giao dịch hoàn thành',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${stats.totalBookings} lượt',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Revenue number ──
          Padding(
            padding: const EdgeInsets.all(AppSizes.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(stats.totalRevenue),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -1,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4, left: 4),
                      child: Text(
                        'đ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spaceMedium),

                // ── Mini stats row ──
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.today_rounded,
                      label: 'Hôm nay',
                      value: '${stats.todayBookings} lượt',
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: AppSizes.spaceMedium),
                    _MiniStat(
                      icon: Icons.people_alt_rounded,
                      label: 'Người dùng',
                      value: stats.totalUsers.toString(),
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// QUICK STATS COLUMN — right side
// ══════════════════════════════════════════════

class _QuickStatsColumn extends StatelessWidget {
  const _QuickStatsColumn({required this.stats});
  final AdminStatsModel stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _QuickStatCard(
          icon: Icons.calendar_today_rounded,
          title: 'Đặt sân hôm nay',
          value: stats.todayBookings.toString(),
          color: AppColors.primary,
        ),
        AppSizes.hMedium,
        _QuickStatCard(
          icon: Icons.sports_tennis_rounded,
          title: 'Tổng sân',
          value: stats.totalCourts.toString(),
          color: AppColors.secondary,
        ),
        AppSizes.hMedium,
        _QuickStatCard(
          icon: Icons.people_alt_rounded,
          title: 'Tổng người dùng',
          value: stats.totalUsers.toString(),
          color: const Color(0xFF5B8A3C),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.cardPadding,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSizes.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          // Accent bar bên phải
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// PROGRESS CARD
// ══════════════════════════════════════════════

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.stats,
    required this.bookingTarget,
    required this.revenueTarget,
    required this.userTarget,
    required this.currencyFormat,
  });

  final AdminStatsModel stats;
  final int bookingTarget;
  final double revenueTarget;
  final int userTarget;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final bookingProgress =
        (stats.totalBookings / bookingTarget).clamp(0.0, 1.0);
    final revenueProgress =
        (stats.totalRevenue / revenueTarget).clamp(0.0, 1.0);
    final userProgress =
        (stats.totalUsers / userTarget).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: const Icon(Icons.track_changes_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: AppSizes.spaceSmall),
              const Text('Tiến độ mục tiêu',
                  style: AppTextStyles.heading2),
            ],
          ),
          AppSizes.hLarge,
          _ProgressRow(
            label: 'Đặt sân',
            current: stats.totalBookings,
            target: bookingTarget,
            unit: 'lượt',
            progress: bookingProgress,
            color: AppColors.primary,
            icon: Icons.event_available_rounded,
          ),
          const SizedBox(height: AppSizes.spaceMedium + 4),
          _ProgressRow(
            label: 'Doanh thu',
            current: stats.totalRevenue.toInt(),
            target: revenueTarget.toInt(),
            unit: 'đ',
            progress: revenueProgress,
            color: AppColors.secondary,
            icon: Icons.account_balance_wallet_rounded,
            format: currencyFormat,
          ),
          const SizedBox(height: AppSizes.spaceMedium + 4),
          _ProgressRow(
            label: 'Người dùng',
            current: stats.totalUsers,
            target: userTarget,
            unit: 'người',
            progress: userProgress,
            color: const Color(0xFF5B8A3C),
            icon: Icons.people_alt_rounded,
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.progress,
    required this.color,
    required this.icon,
    this.format,
  });

  final String label;
  final int current;
  final int target;
  final String unit;
  final double progress;
  final Color color;
  final IconData icon;
  final NumberFormat? format;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toInt();
    final currentStr = format?.format(current) ?? current.toString();
    final targetStr = format?.format(target) ?? target.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Text(
              '$currentStr / $targetStr $unit',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}