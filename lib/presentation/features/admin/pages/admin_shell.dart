import 'package:badminton_app/presentation/features/admin/pages/admin_transactions_screen.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

import 'dashboard_screen.dart';
import 'admin_users_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() =>
      _AdminShellState();
}

class _AdminShellState
    extends State<AdminShell> {
  int index = 0;

  final pages = const [
    DashboardScreen(),

    AdminUsersPage(),

    Center(child: Text("Courts")),

    Center(child: Text("Bookings")),

    
    AdminTransactionsScreen(),
  ];

  final titles = const [
    "Dashboard",
    "Users",
    "Courts",
    "Bookings",
    "Transactions",
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width <
            900;

    return Scaffold(
      backgroundColor:
          AppColors.background,

      drawer:
          isMobile ? _buildSidebar() : null,

      appBar: AppBar(
        elevation: 0,

        backgroundColor:
            AppColors.primary,

        title: Text(
          titles[index],

          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        iconTheme: const IconThemeData(
          color: AppColors.white,
        ),
      ),

      body: Row(
        children: [
          // =========================
          // SIDEBAR DESKTOP
          // =========================

          if (!isMobile) _buildSidebar(),

          // =========================
          // PAGE CONTENT
          // =========================

          Expanded(
            child: pages[index],
          ),
        ],
      ),
    );
  }

  // ====================================
  // SIDEBAR
  // ====================================

  Widget _buildSidebar() {
    return Container(
      width: 260,

      color: AppColors.primary,

      child: Column(
        children: [
          const SizedBox(height: 30),

          // =========================
          // LOGO
          // =========================

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),

            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),

                  decoration: BoxDecoration(
                    color: AppColors.accent,

                    borderRadius:
                        BorderRadius.circular(
                      AppSizes.radiusL,
                    ),
                  ),

                  child: const Icon(
                    Icons.admin_panel_settings,
                    color:
                        AppColors.primary,
                  ),
                ),

                AppSizes.wMedium,

                const Expanded(
                  child: Text(
                    "ADMIN PANEL",

                    style: TextStyle(
                      color:
                          AppColors.white,

                      fontSize: 22,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // =========================
          // MENU
          // =========================

          _menuItem(
            icon: Icons.dashboard,
            title: "Dashboard",
            i: 0,
          ),

          _menuItem(
            icon: Icons.people,
            title: "Users",
            i: 1,
          ),

          _menuItem(
            icon: Icons.sports_tennis,
            title: "Courts",
            i: 2,
          ),

          _menuItem(
            icon: Icons.book_online,
            title: "Bookings",
            i: 3,
          ),

          _menuItem(
            icon: Icons.payments,
            title: "Transactions",
            i: 4,
          ),

          const Spacer(),

          // =========================
          // ADMIN INFO
          // =========================

          Container(
            margin: const EdgeInsets.all(
              16,
            ),

            padding: const EdgeInsets.all(
              16,
            ),

            decoration: BoxDecoration(
              color: Colors.white
                  .withOpacity(0.1),

              borderRadius:
                  BorderRadius.circular(
                AppSizes.radiusXL,
              ),
            ),

            child: const Row(
              children: [
                CircleAvatar(
                  radius: 24,

                  backgroundColor:
                      AppColors.accent,

                  child: Icon(
                    Icons.person,
                    color:
                        AppColors.primary,
                  ),
                ),

                SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        "Administrator",

                        style: TextStyle(
                          color:
                              AppColors
                                  .white,

                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        "System Manager",

                        style: TextStyle(
                          color: Colors
                              .white70,

                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====================================
  // MENU ITEM
  // ====================================

  Widget _menuItem({
    required IconData icon,
    required String title,
    required int i,
  }) {
    final selected = index == i;

    return InkWell(
      onTap: () {
        setState(() {
          index = i;
        });

        Navigator.pop(context);
      },

      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),

        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent
              : Colors.transparent,

          borderRadius:
              BorderRadius.circular(
            AppSizes.radiusXL,
          ),
        ),

        child: Row(
          children: [
            Icon(
              icon,

              color: selected
                  ? AppColors.primary
                  : AppColors.white,
            ),

            AppSizes.wMedium,

            Text(
              title,

              style: TextStyle(
                color: selected
                    ? AppColors.primary
                    : AppColors.white,

                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}