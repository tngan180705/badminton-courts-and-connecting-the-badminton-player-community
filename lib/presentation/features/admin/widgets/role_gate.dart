import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

import '../../../../data/repositories/user_repository.dart';

import '../../admin/pages/admin_shell.dart';
import '../../court/pages/home_screen.dart';

class RoleGate extends StatefulWidget {
  final String uid;

  const RoleGate({
    super.key,
    required this.uid,
  });

  @override
  State<RoleGate> createState() =>
      _RoleGateState();
}

class _RoleGateState
    extends State<RoleGate> {
  final UserRepository _repo =
      UserRepository();

  late final Future<dynamic> _future;

  @override
  void initState() {
    super.initState();

    _future = _repo
        .getUserByFirebaseUid(
      widget.uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,

      builder: (context, snapshot) {
        // =========================
        // LOADING
        // =========================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor:
                AppColors.background,

            body: Center(
              child:
                  CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        // =========================
        // ERROR
        // =========================

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor:
                AppColors.background,

            body: Center(
              child: Text(
                "Error: ${snapshot.error}",
              ),
            ),
          );
        }

        final user = snapshot.data;

        // =========================
        // USER NOT FOUND
        // =========================

        if (user == null) {
          return const Scaffold(
            backgroundColor:
                AppColors.background,

            body: Center(
              child: Text(
                "Không tìm thấy user",
              ),
            ),
          );
        }

        // =========================
        // ADMIN
        // =========================

        if (user.role == 'admin') {
          return const AdminShell();
        }

        // =========================
        // PLAYER
        // =========================

        return const HomeScreen();
      },
    );
  }
}