import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/network/supabase_client.dart';
import '../domain/message.dart';

part 'chat_repository.g.dart';

class ChatRepository {
  final SupabaseClient _client;
  ChatRepository(this._client);

  // Tạo Room ID duy nhất cho 2 người (Logic: Sắp xếp ID nhỏ trước - lớn sau)
  String getRoomId(String otherId) {
    final myId = _client.auth.currentUser!.id;
    final ids = [myId, otherId]..sort();
    return "${ids[0]}_${ids[1]}";
  }

  // Stream tin nhắn realtime theo Room ID
  Stream<List<ChatMessage>> getMessagesStream(String otherId) {
    final roomId = getRoomId(otherId);
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order(
          'created_at',
          ascending: false,
        ) // Đảo ngược để dùng cho ListView.reversed
        .map((data) => data.map((json) => ChatMessage.fromJson(json)).toList());
  }

  Future<void> sendMessage(String receiverId, String content) async {
    final myId = _client.auth.currentUser!.id;
    await _client.from('messages').insert({
      'sender_id': myId,
      'receiver_id': receiverId,
      'room_id': getRoomId(receiverId),
      'content': content,
    });
  }
}

@riverpod
ChatRepository chatRepository(ChatRepositoryRef ref) {
  return ChatRepository(ref.watch(supabaseClientProvider));
}
