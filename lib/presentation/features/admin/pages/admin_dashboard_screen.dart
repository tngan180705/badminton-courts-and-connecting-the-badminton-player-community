import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../widgets/summary_card.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsStreamProvider);
    final now = DateTime.now();
    final dateFormatter = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN');
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bảng điều khiển',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A6136),
            ),
          ),
          Text(
            dateFormatter.format(now),
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 30),
          
          statsAsync.when(
            data: (stats) => Column(
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.2,
                  children: [
                    SummaryCard(
                      title: 'Người dùng',
                      value: '${stats['userCount']}',
                      icon: Icons.people,
                      color: const Color(0xFF4A6136),
                    ),
                    SummaryCard(
                      title: 'Sân cầu lông',
                      value: '${stats['courtCount']}',
                      icon: Icons.sports_tennis,
                      color: const Color(0xFF4A6136),
                    ),
                    SummaryCard(
                      title: 'Đặt sân',
                      value: '${stats['bookingCount']}',
                      icon: Icons.calendar_today,
                      color: const Color(0xFF4A6136),
                    ),
                    SummaryCard(
                      title: 'Doanh thu',
                      value: '${currencyFormatter.format(stats['totalRevenue'])}đ',
                      icon: Icons.account_balance_wallet,
                      color: const Color(0xFF4A6136),
                      isHighlighted: true,
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                
                // Bottom Big Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A6136), Color(0xFF7AA35B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A6136).withOpacity(0.3),
                        blurRadius: 15,
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
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tổng doanh thu',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Giao dịch hoàn thành',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${stats['bookingCount']} lượt',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Text(
                        '${currencyFormatter.format(stats['totalRevenue'])} đ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${stats['todayBookingCount']} lượt', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      const Text('Hôm nay', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.people, color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${stats['userCount']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      const Text('Người dùng', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Lỗi: $e')),
          ),
        ],
      ),
    );
  }
}
