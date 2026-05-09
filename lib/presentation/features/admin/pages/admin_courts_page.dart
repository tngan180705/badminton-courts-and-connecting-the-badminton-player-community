import 'package:badminton_app/data/repositories/court_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminCourtsPage extends ConsumerWidget {
  const AdminCourtsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(courtRepositoryProvider);

    return FutureBuilder(
      future: repo.getAllCourts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final courts = snapshot.data ?? [];

        if (courts.isEmpty) return const Center(child: Text('Không có sân'));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: courts.length,
          itemBuilder: (context, i) {
            final c = courts[i];
            return Card(
              child: ListTile(
                title: Text(c.name),
                subtitle: Text(c.address ?? ''),
              ),
            );
          },
        );
      },
    );
  }
}
