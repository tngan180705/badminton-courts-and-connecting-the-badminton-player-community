class SubCourtModel {
  final String subCourtId; // Prefix: SCT_ (Document ID)
  final String courtId; // Prefix: CT_
  final String subCourtName;
  final bool isActive;
  final String status; // active / maintenance / closed

  SubCourtModel({
    required this.subCourtId,
    required this.courtId,
    required this.subCourtName,
    required this.isActive,
    required this.status,
  });

  factory SubCourtModel.fromFirestore(Map<String, dynamic> json, String id) {
    return SubCourtModel(
      subCourtId: id,
      // Fix: dùng toString() thay vì ép kiểu trực tiếp
      courtId: json['court_id']?.toString() ?? '',
      subCourtName: json['sub_court_name']?.toString() ?? 'Sân chưa đặt tên',
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      status: json['status']?.toString() ?? 'active',
    );
  }
  // Chuyển đổi từ Object Flutter sang Map để lưu lên Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'court_id': courtId,
      'sub_court_name': subCourtName,
      'is_active': isActive,
      'status': status,
    };
  }
}
