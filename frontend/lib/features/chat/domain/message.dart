class ChatMessage {
  final int id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    senderId: json['sender_id'],
    receiverId: json['receiver_id'],
    content: json['content'],
    createdAt: DateTime.parse(json['created_at']),
  );
}
