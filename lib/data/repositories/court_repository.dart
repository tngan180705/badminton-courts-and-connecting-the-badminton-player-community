import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/court_model.dart';
import '../models/sub_court_model.dart';

class CourtRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy danh sách sân con dựa trên ID của sân lớn
  Future<List<SubCourtModel>> getSubCourtsByCourtId(String courtId) async {
    try {
      final snapshot = await _firestore
          .collection('sub_courts')
          .where('court_id', isEqualTo: courtId)
          .get();

      return snapshot.docs
          .map((doc) => SubCourtModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // In lỗi ra để debug nếu có vấn đề về quyền truy cập Firestore
      print('Error fetching sub-courts: $e');
      return [];
    }
  }

  // Tiện tay tạo luôn hàm lấy sân lớn nếu sau này cần dùng
  Future<List<CourtModel>> getAllCourts() async {
    final snapshot = await _firestore.collection('courts').get();
    return snapshot.docs
        .map((doc) => CourtModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }
}
