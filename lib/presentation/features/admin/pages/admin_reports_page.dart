import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/transaction_model.dart';

// ─────────────────────────────────────────────
// DATA HELPERS
// ─────────────────────────────────────────────

class _MonthStat {
  final String label; // "T1/2025"
  final double revenue;
  final int bookings;

  const _MonthStat(
      {required this.label, required this.revenue, required this.bookings});
}

enum _ReportRange { last3, last6, thisYear }

// ─────────────────────────────────────────────
// REPOSITORY EXTENSION  (inline — không cần sửa repo gốc)
// ─────────────────────────────────────────────

Future<List<TransactionModel>> _fetchAllTransactions() async {
  final snap =
      await FirebaseFirestore.instance.collection('transactions').get();
  return snap.docs
      .map((d) => TransactionModel.fromFirestore(d.data(), d.id))
      .toList();
}

Future<int> _fetchTotalBookings() async {
  final snap =
      await FirebaseFirestore.instance.collection('bookings').get();
  return snap.size;
}

// ─────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  _ReportRange _range = _ReportRange.last6;
  late Future<_ReportData> _future;

  static final _currency = NumberFormat('#,##0', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ReportData> _load() async {
    final txList = await _fetchAllTransactions();
    final totalBookings = await _fetchTotalBookings();
    return _ReportData(transactions: txList, totalBookings: totalBookings);
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ReportData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snap.hasError) {
          return Center(
              child: Text('Lỗi: ${snap.error}',
                  style: const TextStyle(color: AppColors.error)));
        }

        final data = snap.data!;
        final months = data.getMonthStats(_range);

        final totalRevenue =
            months.fold<double>(0, (s, m) => s + m.revenue);
        final totalTx = data.getFilteredTransactions(_range).length;
        final avgMonthly =
            months.isEmpty ? 0.0 : totalRevenue / months.length;
        final maxRevenue =
            months.isEmpty ? 1.0 : months.map((m) => m.revenue).reduce((a, b) => a > b ? a : b);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              _ReportHeader(onRefresh: _refresh),
              AppSizes.hLarge,

              // ── Range selector ──
              _RangeSelector(
                  range: _range,
                  onChanged: (r) => setState(() => _range = r)),
              AppSizes.hMedium,

              // ── KPI Row ──
              _KpiRow(
                totalRevenue: totalRevenue,
                totalTx: totalTx,
                avgMonthly: avgMonthly,
                totalBookings: data.totalBookings,
                currency: _currency,
              ),
              AppSizes.hLarge,

              // ── Bar Chart ──
              _BarChart(
                months: months,
                maxRevenue: maxRevenue,
                currency: _currency,
              ),
              AppSizes.hLarge,

              // ── By Payment Method ──
              _MethodBreakdown(
                  transactions: data.getFilteredTransactions(_range),
                  currency: _currency),
              AppSizes.hLarge,

              // ── Recent Transactions ──
              _RecentTransactions(
                  transactions: data.getFilteredTransactions(_range),
                  currency: _currency),

              AppSizes.hLarge,
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// REPORT DATA MODEL
// ─────────────────────────────────────────────

class _ReportData {
  final List<TransactionModel> transactions;
  final int totalBookings;

  const _ReportData(
      {required this.transactions, required this.totalBookings});

  List<TransactionModel> getFilteredTransactions(_ReportRange range) {
    final now = DateTime.now();
    final cutoff = switch (range) {
      _ReportRange.last3 =>
        DateTime(now.year, now.month - 2, 1),
      _ReportRange.last6 =>
        DateTime(now.year, now.month - 5, 1),
      _ReportRange.thisYear => DateTime(now.year, 1, 1),
    };
    return transactions.where((t) => t.createdAt.isAfter(cutoff)).toList();
  }

  List<_MonthStat> getMonthStats(_ReportRange range) {
    final filtered = getFilteredTransactions(range);
    final Map<String, _MonthBuilder> map = {};

    for (final tx in filtered) {
      final key =
          'T${tx.createdAt.month}/${tx.createdAt.year}';
      map.putIfAbsent(key,
          () => _MonthBuilder(label: key, date: DateTime(tx.createdAt.year, tx.createdAt.month)));
      map[key]!.revenue += tx.amount;
      map[key]!.bookings++;
    }

    final list = map.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return list
        .map((b) =>
            _MonthStat(label: b.label, revenue: b.revenue, bookings: b.bookings))
        .toList();
  }
}

class _MonthBuilder {
  final String label;
  final DateTime date;
  double revenue = 0;
  int bookings = 0;

  _MonthBuilder({required this.label, required this.date});
}

// ─────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Báo cáo doanh thu', style: AppTextStyles.heading1),
            SizedBox(height: 4),
            Text('Phân tích chi tiết theo thời gian',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        IconButton.filled(
          style: IconButton.styleFrom(backgroundColor: AppColors.primary),
          icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
          onPressed: onRefresh,
          tooltip: 'Làm mới',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// RANGE SELECTOR
// ─────────────────────────────────────────────

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.range, required this.onChanged});

  final _ReportRange range;
  final ValueChanged<_ReportRange> onChanged;

  static const _options = [
    (_ReportRange.last3, '3 tháng'),
    (_ReportRange.last6, '6 tháng'),
    (_ReportRange.thisYear, 'Năm nay'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
      ),
      child: Row(
        children: _options.map((opt) {
          final (value, label) = opt;
          final selected = range == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// KPI ROW
// ─────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.totalRevenue,
    required this.totalTx,
    required this.avgMonthly,
    required this.totalBookings,
    required this.currency,
  });

  final double totalRevenue;
  final int totalTx;
  final double avgMonthly;
  final int totalBookings;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Big revenue card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.cardPadding),
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
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tổng doanh thu',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currency.format(totalRevenue),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4, left: 4),
                    child: Text('đ',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.spaceMedium),

        // 3 small cards
        Row(
          children: [
            Expanded(
              child: _SmallKpi(
                icon: Icons.receipt_long_rounded,
                label: 'Giao dịch',
                value: totalTx.toString(),
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSizes.spaceSmall),
            Expanded(
              child: _SmallKpi(
                icon: Icons.trending_up_rounded,
                label: 'TB/tháng',
                value: '${currency.format(avgMonthly)}đ',
                color: const Color(0xFF5B8A3C),
              ),
            ),
            const SizedBox(width: AppSizes.spaceSmall),
            Expanded(
              child: _SmallKpi(
                icon: Icons.event_available_rounded,
                label: 'Đặt sân',
                value: totalBookings.toString(),
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SmallKpi extends StatelessWidget {
  const _SmallKpi({
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.3),
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BAR CHART (custom — không cần thư viện ngoài)
// ─────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.months,
    required this.maxRevenue,
    required this.currency,
  });

  final List<_MonthStat> months;
  final double maxRevenue;
  final NumberFormat currency;

  static const _chartHeight = 160.0;

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(Icons.bar_chart_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Doanh thu theo tháng',
                  style: AppTextStyles.heading2),
            ],
          ),

          const SizedBox(height: AppSizes.spaceLarge),

          if (months.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Không có dữ liệu',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            SizedBox(
              height: _chartHeight + 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: months.map((m) {
                  final ratio = maxRevenue > 0 ? m.revenue / maxRevenue : 0.0;
                  return Expanded(
                    child: _Bar(
                      month: m,
                      ratio: ratio,
                      maxHeight: _chartHeight,
                      currency: currency,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.month,
    required this.ratio,
    required this.maxHeight,
    required this.currency,
  });

  final _MonthStat month;
  final double ratio;
  final double maxHeight;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final barH = (ratio * maxHeight).clamp(4.0, maxHeight);

    return GestureDetector(
      onTap: () => _showTooltip(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Value on top
            Text(
              ratio > 0.1
                  ? '${(month.revenue / 1000000).toStringAsFixed(1)}M'
                  : '',
              style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),

            // Bar
            Container(
              height: barH,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, AppColors.primary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
              ),
            ),

            const SizedBox(height: 6),

            // Month label
            Text(
              month.label,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showTooltip(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${month.label}: ${currency.format(month.revenue)}đ  •  ${month.bookings} giao dịch',
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PAYMENT METHOD BREAKDOWN
// ─────────────────────────────────────────────

class _MethodBreakdown extends StatelessWidget {
  const _MethodBreakdown(
      {required this.transactions, required this.currency});

  final List<TransactionModel> transactions;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final Map<String, double> byMethod = {};
    for (final t in transactions) {
      byMethod[t.paymentMethod] = (byMethod[t.paymentMethod] ?? 0) + t.amount;
    }

    final total = byMethod.values.fold<double>(0, (s, v) => s + v);

    if (byMethod.isEmpty) return const SizedBox.shrink();

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
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: const Icon(Icons.pie_chart_rounded,
                    color: AppColors.secondary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Theo hình thức thanh toán',
                  style: AppTextStyles.heading2),
            ],
          ),
          const SizedBox(height: AppSizes.spaceMedium),
          ...byMethod.entries.toList().asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final pct = total > 0 ? e.value / total : 0.0;
            final colors = [
              AppColors.primary,
              AppColors.secondary,
              const Color(0xFF5B8A3C),
              AppColors.accent,
            ];
            final color = colors[i % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(e.key,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text(
                        '${currency.format(e.value)}đ  (${(pct * 100).toInt()}%)',
                        style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      minHeight: 7,
                      value: pct,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// RECENT TRANSACTIONS TABLE
// ─────────────────────────────────────────────

class _RecentTransactions extends StatefulWidget {
  const _RecentTransactions(
      {required this.transactions, required this.currency});

  final List<TransactionModel> transactions;
  final NumberFormat currency;

  @override
  State<_RecentTransactions> createState() => _RecentTransactionsState();
}

class _RecentTransactionsState extends State<_RecentTransactions> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.transactions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final shown = _expanded ? sorted : sorted.take(5).toList();

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
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B8A3C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: Color(0xFF5B8A3C), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Giao dịch gần đây',
                      style: AppTextStyles.heading2),
                ],
              ),
              Text('${sorted.length} giao dịch',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),

          const SizedBox(height: AppSizes.spaceMedium),

          if (shown.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Không có giao dịch',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else ...[
            ...shown.map((t) => _TxRow(tx: t, currency: widget.currency)),

            if (sorted.length > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _expanded
                        ? 'Thu gọn'
                        : 'Xem thêm ${sorted.length - 5} giao dịch',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.tx, required this.currency});

  final TransactionModel tx;
  final NumberFormat currency;

  Color get _statusColor => switch (tx.status) {
        'confirmed' => const Color(0xFF5B8A3C),
        'rejected' => AppColors.error,
        _ => AppColors.secondary,
      };

  String get _statusLabel => switch (tx.status) {
        'confirmed' => 'Xác nhận',
        'rejected' => 'Từ chối',
        _ => 'Chờ',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Row(
        children: [
          // Type icon
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: const Icon(Icons.payments_rounded,
                size: 15, color: AppColors.primary),
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.transactionId,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                Text(
                  DateFormat('dd/MM/yyyy  HH:mm').format(tx.createdAt),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Amount + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${currency.format(tx.amount)}đ',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5B8A3C)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel,
                    style: TextStyle(
                        fontSize: 10,
                        color: _statusColor,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}