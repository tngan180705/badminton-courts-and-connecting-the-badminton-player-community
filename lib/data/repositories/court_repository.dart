import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/court_model.dart';
import '../models/sub_court_model.dart';

class CourtRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- PHẦN ĐỌC DỮ LIỆU (READ) ---

  // Lấy toàn bộ danh sách sân lớn (Dùng cho FutureProvider)
  Future<List<CourtModel>> getAllCourts() async {
    try {
      final snapshot = await _firestore.collection('courts').get();
      return snapshot.docs
          .map((doc) => CourtModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching all courts: $e');
      return [];
    }
  }

  // Stream lấy danh sách sân lớn realtime (Dùng cho Admin/Realtime updates)
  Stream<List<CourtModel>> watchAllCourts() {
    return _firestore.collection('courts').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CourtModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

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
      debugPrint('Error fetching sub-courts: $e');
      return [];
    }
  }

  // --- PHẦN QUẢN LÝ CỦA ADMIN (WRITE) ---

  Future<void> addCourt(CourtModel court) async {
    await _firestore.collection('courts').add(court.toFirestore());
  }

  Future<void> updateCourt(CourtModel court) async {
    await _firestore
        .collection('courts')
        .doc(court.courtId)
        .update(court.toFirestore());
  }

  Future<void> deleteCourt(String courtId) async {
    await _firestore.collection('courts').doc(courtId).delete();

    // Xóa các sub_courts liên quan
    final subCourts = await _firestore
        .collection('sub_courts')
        .where('court_id', isEqualTo: courtId)
        .get();

    for (var doc in subCourts.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> addSubCourt(SubCourtModel subCourt) async {
    await _firestore.collection('sub_courts').add(subCourt.toFirestore());
  }

  Future<void> updateSubCourt(SubCourtModel subCourt) async {
    await _firestore
        .collection('sub_courts')
        .doc(subCourt.subCourtId) // Đã đổi thành subCourtId cho khớp với Model
        .update(subCourt.toFirestore());
  }
}
