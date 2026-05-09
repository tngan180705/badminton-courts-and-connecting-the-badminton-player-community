class AdminStatsModel {
  final int totalUsers;
  final int totalCourts;
  final int totalBookings;
  final int todayBookings;
  final double totalRevenue;

  const AdminStatsModel({
    required this.totalUsers,
    required this.totalCourts,
    required this.totalBookings,
    required this.todayBookings,
    required this.totalRevenue,
  });

  factory AdminStatsModel.empty() {
    return const AdminStatsModel(
      totalUsers: 0,
      totalCourts: 0,
      totalBookings: 0,
      todayBookings: 0,
      totalRevenue: 0,
    );
  }

  factory AdminStatsModel.fromMap(Map<String, dynamic> map) {
    return AdminStatsModel(
      totalUsers: map['total_users'] ?? 0,
      totalCourts: map['total_courts'] ?? 0,
      totalBookings: map['total_bookings'] ?? 0,
      todayBookings: map['today_bookings'] ?? 0,
      totalRevenue:
          (map['total_revenue'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_users': totalUsers,
      'total_courts': totalCourts,
      'total_bookings': totalBookings,
      'today_bookings': todayBookings,
      'total_revenue': totalRevenue,
    };
  }

  AdminStatsModel copyWith({
    int? totalUsers,
    int? totalCourts,
    int? totalBookings,
    int? todayBookings,
    double? totalRevenue,
  }) {
    return AdminStatsModel(
      totalUsers: totalUsers ?? this.totalUsers,
      totalCourts: totalCourts ?? this.totalCourts,
      totalBookings:
          totalBookings ?? this.totalBookings,
      todayBookings:
          todayBookings ?? this.todayBookings,
      totalRevenue:
          totalRevenue ?? this.totalRevenue,
    );
  }
}