import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiService {
  // URL của Server Python (Sử dụng IP thực của máy tính cho LDPlayer)
  static const String _baseUrl = 'http://192.168.110.67:8000';

  static bool get isConfigured => true;

  AiService();

  Future<String> sendMessage(String message, String contextData) async {
    print('AI_DEBUG: Sending message to Python Backend...');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'context': contextData,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['response'] ?? 'AI không phản hồi.';
      } else {
        return '❌ Lỗi Server Python (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      print('AI_DEBUG: Connection Error -> $e');
      return '❌ Không thể kết nối tới Server Python. Hãy đảm bảo bạn đã chạy "python main.py"';
    }
  }

  void resetChat() {
    // Không cần reset trên backend đơn giản
  }
}

final aiServiceProvider = Provider<AiService>((ref) => AiService());