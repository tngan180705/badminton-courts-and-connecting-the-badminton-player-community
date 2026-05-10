import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/ai_service.dart';
import '../../activity/pages/activity_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  AiChatState({
    this.messages = const [],
    this.isLoading = false,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  final Ref ref;

  AiChatNotifier(this.ref) : super(AiChatState()) {
    _sendInitialMessage();
  }

  void _sendInitialMessage() {
    state = state.copyWith(
      messages: [
        ChatMessage(
          text: 'Chào bạn! 👋 Tôi là trợ lý AI của BadmintonApp.\n\nTôi có thể giúp bạn:\n• Xem lịch chơi sắp tới\n• Gợi ý khung giờ phù hợp\n• Hỏi về trận đấu tiếp theo\n\nBạn muốn hỏi gì nào?',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    try {
      final contextData = await _buildContext();
      print('AI_DEBUG: Final Prompt Context:\n$contextData');
      final aiService = ref.read(aiServiceProvider);
      final responseText = await aiService.sendMessage(text.trim(), contextData);

      final aiMsg = ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
      );
    } catch (e) {
      print('AI_DEBUG: Notifier caught error: $e');
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            text: 'Xin lỗi, tôi đang gặp sự cố kết nối. ($e)',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
        isLoading: false,
      );
    }
  }

  void resetConversation() {
    state = AiChatState();
    _sendInitialMessage();
  }

  Future<String> _buildContext() async {
    final activitiesAsync = ref.read(userActivitiesProvider);
    final now = DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final dayNames = ['', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];

    String contextStr = 'Hôm nay: ${formatter.format(now)} (${dayNames[now.weekday]})\n';

    if (activitiesAsync.value != null && activitiesAsync.value!.isNotEmpty) {
      final all = activitiesAsync.value!;

      // Upcoming bookings
      final upcoming = all.where((a) {
        final date = (a['booking_date'] as Timestamp).toDate();
        final status = a['status'] as String;
        final endTime = a['end_time'] as String? ?? '23:59';
        try {
          final ep = endTime.split(':');
          final endDt = DateTime(date.year, date.month, date.day, int.parse(ep[0]), int.parse(ep[1]));
          return (status == 'confirmed' || status == 'ongoing') && endDt.isAfter(now);
        } catch (_) {
          return (status == 'confirmed' || status == 'ongoing') && date.isAfter(now);
        }
      }).toList();

      if (upcoming.isEmpty) {
        contextStr += 'Lịch sắp tới: Không có trận đấu nào.\n';
      } else {
        contextStr += 'Lịch sắp tới (${upcoming.length} trận):\n';
        for (var a in upcoming.take(5)) {
          final date = (a['booking_date'] as Timestamp).toDate();
          final start = a['start_time'] ?? '';
          final end = a['end_time'] ?? '';
          final subCourtName = a['sub_court_name'] ?? 'Sân';
          final courtName = a['court_name'] ?? '';
          final dow = dayNames[date.weekday];
          contextStr +=
              '  - $dow ${DateFormat('dd/MM/yyyy').format(date)}, $start-$end tại $subCourtName ($courtName)\n';
        }
      }

      // Past 30 days history
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final past = all.where((a) {
        final date = (a['booking_date'] as Timestamp).toDate();
        return date.isBefore(now) && date.isAfter(thirtyDaysAgo) && a['status'] != 'cancelled';
      }).toList();

      contextStr += '\nLịch sử 30 ngày qua: ${past.length} buổi chơi.\n';
      if (past.isNotEmpty) {
        final courts = <String>{};
        final times = <String>{};
        for (var a in past) {
          courts.add(a['sub_court_name'] ?? '');
          times.add(a['start_time'] ?? '');
        }
        contextStr += 'Sân hay đến: ${courts.where((s) => s.isNotEmpty).take(3).join(', ')}\n';
        contextStr += 'Khung giờ hay đặt: ${times.where((t) => t.isNotEmpty).take(3).join(', ')}\n';
      }
    } else {
      contextStr += 'Lịch sử đặt sân: Chưa có dữ liệu.\n';
    }

    return contextStr;
  }
}

final aiChatProvider =
    StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  return AiChatNotifier(ref);
});
