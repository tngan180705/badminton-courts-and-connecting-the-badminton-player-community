import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_activity_log_model.dart';

class LogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lưu lại hành động người dùng (view_court, book_court...)
  Future<void> logUserActivity(UserActivityLogModel log) async {
    await _firestore.collection('user_activity_logs').add(log.toFirestore());
  }
}
