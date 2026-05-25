import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/network/supabase_client.dart';
import '../domain/comment.dart';

part 'comment_repository.g.dart';

class CommentRepository {
  final SupabaseClient _client;
  CommentRepository(this._client);

  // Stream realtime comment theo post_id
  Stream<List<AppComment>> getCommentsStream(int postId) {
    return _client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => AppComment.fromJson(json)).toList());
  }

  Future<void> sendComment(int postId, String content) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('comments').insert({
      'post_id': postId,
      'user_id': userId,
      'content': content,
    });
  }

  // Merged from newfeed version
  Future<void> createComment(int postId, String content) async {
    await sendComment(postId, content);
  }

  Future<List<Map<String, dynamic>>> getComments(int postId) async {
    final data = await _client
        .from('comments')
        .select('''
          *,
          profiles!comments_user_id_fkey(full_name, avatar_url)
        ''')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }
}

@riverpod
CommentRepository commentRepository(CommentRepositoryRef ref) {
  return CommentRepository(ref.watch(supabaseClientProvider));
}
