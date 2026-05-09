import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/court_model.dart';
import '../models/sub_court_model.dart';

final courtRepositoryProvider =
    Provider<CourtRepository>((ref) => CourtRepository());

class CourtRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      print('❌ getSubCourtsByCourtId error: $e');
      return [];
    }
  }
Future<int> getTotalSubCourts() async {  try {
    // FIX: đếm sub courts thay vì courts
    final snapshot = await _firestore.collection('sub_courts').get();

    return snapshot.docs.length;
  } catch (e) {
    print('❌ getTotalCourts error: $e');
    return 0;
  }
}

  Future<List<CourtModel>> getAllCourts() async {
    try {
      final snapshot = await _firestore.collection('courts').get();
      return snapshot.docs
          .map((doc) => CourtModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ getAllCourts error: $e');
      return [];
    }
  }
}