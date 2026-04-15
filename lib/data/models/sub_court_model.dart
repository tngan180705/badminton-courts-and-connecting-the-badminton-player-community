class SubCourtModel {
  final String subCourtId; // Prefix: SCT_ (Document ID)
  final String courtId; // Prefix: CT_
  final String subCourtName;
  final bool isActive;

  SubCourtModel({
    required this.subCourtId,
    required this.courtId,
    required this.subCourtName,
    required this.isActive,
  });

  // Chuyển đổi từ dữ liệu Firestore sang Object Flutter
  factory SubCourtModel.fromFirestore(Map<String, dynamic> json, String id) {
    return SubCourtModel(
      subCourtId: id,
      courtId: json['court_id'] as String? ?? '',
      subCourtName: json['sub_court_name'] as String? ?? 'Sân chưa đặt tên',
      // Ép kiểu bool rõ ràng để tránh lỗi nếu Firebase lưu dạng khác
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
    );
  }

  // Chuyển đổi từ Object Flutter sang Map để lưu lên Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'court_id': courtId,
      'sub_court_name': subCourtName,
      'is_active': isActive,
    };
  }
}
