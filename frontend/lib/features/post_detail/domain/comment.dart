class AppComment {
  final int id;
  final int postId;
  final String userId;
  final String content;
  final DateTime createdAt;

  AppComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory AppComment.fromJson(Map<String, dynamic> json) => AppComment(
    id: json['id'],
    postId: json['post_id'],
    userId: json['user_id'],
    content: json['content'],
    createdAt: DateTime.parse(json['created_at']).toLocal(),
  );
}
