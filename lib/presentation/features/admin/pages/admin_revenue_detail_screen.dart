import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/repositories/transaction_repository.dart';

class AdminRevenueDetailScreen extends StatefulWidget {
  const AdminRevenueDetailScreen({super.key});

  @override
  State<AdminRevenueDetailScreen> createState() =>
      _AdminRevenueDetailScreenState();
}

class _AdminRevenueDetailScreenState extends State<AdminRevenueDetailScreen>
    with SingleTickerProviderStateMixin {
  final TransactionRepository _repository = TransactionRepository();

  late TabController _tabController;

  List<TransactionModel> _transactions = [];
  bool _loading = true;
  DateTimeRange? _customRange;
  String _filter = '3m';

  final currency = NumberFormat('#,##0', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final now = DateTime.now();
    DateTime start;

    switch (_filter) {
      case '6m':
        start = DateTime(now.year, now.month - 5, 1);
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        break;
      case 'lastYear':
        start = DateTime(now.year - 1, 1, 1);
        break;
      default:
        start = DateTime(now.year, now.month - 2, 1);
    }

    final end = _customRange?.end ?? now;
    if (_customRange != null) start = _customRange!.start;

    final data = await _repository.getTransactionsByDateRange(
      start: start,
      end: end,
    );

    setState(() {
      _transactions = data;
      _loading = false;
    });
  }

  // ==================== CALCULATIONS ====================
  double get totalRevenue =>
      _transactions.fold(0.0, (sum, e) => sum + e.amount);

  int get totalBookings =>
      _transactions.where((e) => e.bookingId != null).length;

  double get averageRevenue =>
      _transactions.isEmpty ? 0 : totalRevenue / _transactions.length;

  double get confirmedRevenue => _transactions
      .where((e) => e.status == 'confirmed')
      .fold(0.0, (sum, e) => sum + e.amount);

  double get confirmedPercent =>
      totalRevenue == 0 ? 0.0 : confirmedRevenue / totalRevenue;

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(innerBoxIsScrolled),
        ],
        body: _loading
            ? const Center(
                child: CircularProgressIndicator.adaptive(),
              )
            : Column(
                children: [
                  _buildFilterBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBarChartTab(),
                        _buildDonutChartTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ==================== SLIVER APP BAR ====================
  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 60,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
      title: const Text(
        'Chi tiết doanh thu',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: AppColors.white,
          letterSpacing: 0.3,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: Container(
          color: AppColors.primary,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.white.withOpacity(0.55),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 13.5,
            ),
            tabs: const [
              Tab(text: 'Biểu đồ cột'),
              Tab(text: 'Phân bổ doanh thu'),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== FILTER BAR ====================
  Widget _buildFilterBar() {
    const filters = [
      ('3m', '3 tháng'),
      ('6m', '6 tháng'),
      ('year', 'Năm nay'),
      ('lastYear', 'Năm trước'),
    ];

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.spaceMedium,
        AppSizes.screenPadding,
        AppSizes.spaceSmall,
      ),
      child: Row(
        children: filters.map((f) {
          final isSelected = _filter == f.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () async {
                setState(() {
                  _filter = f.$1;
                  _customRange = null;
                });
                await _loadData();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Text(
                  f.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.white : AppColors.textSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== KPI SECTION ====================
  Widget _buildKpis() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: Column(
        children: [
          _buildHeroCard(),
          AppSizes.hMedium,
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'Giao dịch',
                  value: _transactions.length.toString(),
                  icon: Icons.receipt_long_rounded,
                  iconColor: AppColors.secondary,
                ),
              ),
              AppSizes.wSmall,
              Expanded(
                child: _buildStatCard(
                  label: 'TB/giao dịch',
                  value: '${currency.format(averageRevenue)}đ',
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.accent,
                  valueSize: 13,
                ),
              ),
              AppSizes.wSmall,
              Expanded(
                child: _buildStatCard(
                  label: 'Đặt sân',
                  value: totalBookings.toString(),
                  icon: Icons.sports_soccer_rounded,
                  iconColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spaceLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng doanh thu',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spaceSmall, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded,
                        color: AppColors.accent, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      'Đã xác nhận ${(confirmedPercent * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSizes.hSmall,
          Text(
            '${currency.format(totalRevenue)}đ',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSizes.spaceMedium),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: confirmedPercent,
              backgroundColor: AppColors.white.withOpacity(0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${currency.format(confirmedRevenue)}đ đã xác nhận',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    double valueSize = 17,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: AppSizes.iconSize),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BAR CHART TAB ====================
  Widget _buildBarChartTab() {
    final grouped = _groupRevenue();
    if (grouped.isEmpty) return _buildEmptyState();

    final maxRevenue = grouped.map((e) => e.total).reduce(max);

    return ListView(
      padding: const EdgeInsets.only(
        top: AppSizes.spaceMedium,
        bottom: AppSizes.spaceLarge,
      ),
      children: [
        _buildKpis(),
        AppSizes.hMedium,
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPadding),
          child: _buildSectionTitle('Doanh thu theo thời gian'),
        ),
        AppSizes.hSmall,
        SizedBox(
          height: 280,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenPadding),
            child: _ModernBarChart(
              data: grouped,
              maxRevenue: maxRevenue,
              currency: currency,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        AppSizes.wSmall,
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  // ==================== DONUT CHART TAB ====================
  Widget _buildDonutChartTab() {
    final Map<String, double> typeMap = {};
    for (var tx in _transactions) {
      typeMap[tx.type] = (typeMap[tx.type] ?? 0) + tx.amount;
    }

    if (typeMap.isEmpty) return _buildEmptyState();

    final sortedEntries = typeMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      children: [
        _buildSectionTitle('Phân bổ theo loại'),
        AppSizes.hMedium,
        Center(
          child: SizedBox(
            height: 260,
            width: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(260, 260),
                  painter: _DonutPainter(data: typeMap, total: totalRevenue),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tổng',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currency.format(totalRevenue)}đ',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        AppSizes.hLarge,
        _buildSectionTitle('Chi tiết phân bổ'),
        AppSizes.hSmall,
        ...sortedEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final e = entry.value;
          final percent = (e.value / totalRevenue) * 100;
          final color = _donutColor(index);

          return Container(
            margin: const EdgeInsets.only(bottom: AppSizes.spaceSmall),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.cardPadding,
              vertical: AppSizes.spaceMedium,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                AppSizes.wMedium,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          backgroundColor:
                              AppColors.inputBorder.withOpacity(0.4),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSizes.wMedium,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${currency.format(e.value)}đ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${percent.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _donutColor(int index) {
    const colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.error,
      Color(0xFF5C8D89),
      Color(0xFFA67C52),
    ];
    return colors[index % colors.length];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.spaceLarge),
            decoration: BoxDecoration(
              color: AppColors.inputBorder.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 52,
              color: AppColors.textSecondary,
            ),
          ),
          AppSizes.hMedium,
          const Text(
            'Không có dữ liệu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSizes.hSmall,
          const Text(
            'Không có giao dịch trong khoảng thời gian này',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== GROUP DATA ====================
  List<_RevenueGroup> _groupRevenue() {
    final now = DateTime.now();
    final diffDays = _transactions.isEmpty
        ? 0
        : now.difference(_transactions.first.createdAt).inDays;

    final bool byDay = diffDays <= 60;

    final Map<String, List<TransactionModel>> grouped = {};

    for (var tx in _transactions) {
      final key = byDay
          ? DateFormat('dd/MM').format(tx.createdAt)
          : DateFormat('MM/yy').format(tx.createdAt);

      grouped.putIfAbsent(key, () => []).add(tx);
    }

    return grouped.entries
        .map((e) => _RevenueGroup(
              label: e.key,
              total: e.value.fold(0.0, (sum, t) => sum + t.amount),
              count: e.value.length,
            ))
        .toList();
  }
}

// ==================== MODERN BAR CHART ====================
class _ModernBarChart extends StatelessWidget {
  final List<_RevenueGroup> data;
  final double maxRevenue;
  final NumberFormat currency;

  const _ModernBarChart({
    required this.data,
    required this.maxRevenue,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    const barMaxHeight = 180.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.cardPadding,
        AppSizes.cardPadding,
        AppSizes.cardPadding,
        AppSizes.spaceSmall,
      ),
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
          // Y-axis labels row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Y-axis
              SizedBox(
                width: 48,
                height: barMaxHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatShort(maxRevenue),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatShort(maxRevenue / 2),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      '0',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: data.map((item) {
                      final barHeight = maxRevenue > 0
                          ? (item.total / maxRevenue) * barMaxHeight
                          : 0.0;

                      return GestureDetector(
                        onTap: () => _showDetail(context, item),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          child: _BarColumn(
                            item: item,
                            barHeight: barHeight,
                            barMaxHeight: barMaxHeight,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          // Divider line
          Container(
            margin: const EdgeInsets.only(
                top: AppSizes.spaceSmall, left: 56),
            height: 1,
            color: AppColors.inputBorder.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  String _formatShort(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  void _showDetail(BuildContext context, _RevenueGroup item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BarDetailSheet(item: item, currency: currency),
    );
  }
}

class _BarColumn extends StatelessWidget {
  final _RevenueGroup item;
  final double barHeight;
  final double barMaxHeight;

  const _BarColumn({
    required this.item,
    required this.barHeight,
    required this.barMaxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isTop = barHeight >= barMaxHeight * 0.9;

    return SizedBox(
      width: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Bar
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                height: barHeight.clamp(4.0, barMaxHeight),
                width: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ),
              if (isTop)
                Container(
                  width: 32,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.8),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${item.count}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ==================== BAR DETAIL BOTTOM SHEET ====================
class _BarDetailSheet extends StatelessWidget {
  final _RevenueGroup item;
  final NumberFormat currency;

  const _BarDetailSheet({required this.item, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSizes.spaceMedium),
      padding: const EdgeInsets.all(AppSizes.spaceLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.inputBorder,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          AppSizes.hMedium,
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: AppColors.primary, size: 24),
              ),
              AppSizes.wMedium,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chi tiết: ${item.label}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${item.count} giao dịch',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          AppSizes.hLarge,
          Container(
            padding: const EdgeInsets.all(AppSizes.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Doanh thu',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${currency.format(item.total)}đ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.primary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          AppSizes.hMedium,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: AppSizes.spaceMedium),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Đóng',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== DONUT PAINTER ====================
class _DonutPainter extends CustomPainter {
  final Map<String, double> data;
  final double total;

  _DonutPainter({required this.data, required this.total});

  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.error,
    Color(0xFF5C8D89),
    Color(0xFFA67C52),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 36.0;
    const gap = 0.03; // gap between arcs in radians

    double startAngle = -pi / 2;
    int index = 0;

    for (var entry in data.entries) {
      final sweepAngle = (entry.value / total) * 2 * pi - gap;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = _colors[index % _colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 95),
        startAngle + gap / 2,
        sweepAngle.clamp(0.01, 2 * pi),
        false,
        paint,
      );

      startAngle += sweepAngle + gap;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==================== DATA MODEL ====================
class _RevenueGroup {
  final String label;
  final double total;
  final int count;

  _RevenueGroup({required this.label, required this.total, required this.count});
}