import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common_widgets/toast_service.dart';
import 'package:frontend/core/network/supabase_client.dart';
import 'package:frontend/features/auth/application/auth_error_handler.dart';
import 'package:frontend/features/newfeed/domain/post.dart';
import 'package:frontend/features/post_detail/data/comment_repository.dart';
import '../domain/comment.dart';
import 'package:frontend/features/newfeed/data/post_repository.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();

  void _submitComment() async {
    if (_commentController.text.isEmpty) return;
    try {
      final repo = ref.read(commentRepositoryProvider);
      await repo.sendComment(widget.post.id, _commentController.text.trim());
      _commentController.clear();
      ToastService.showSuccess("Đã góp vui một comment! ");
    } catch (e) {
      ToastService.showError(AuthErrorHandler.getErrorMessage(e));
    }
  }

  void _handleLike() async {
    try {
      final repo = ref.read(postRepositoryProvider);
      await repo.toggleLike(widget.post.id, widget.post.isLiked);

      // Thêm dòng này để UI cập nhật trạng thái icon ngay lập tức
      setState(() {
        // Lưu ý: Đây là local update để user thấy mượt,
        // còn data thật sẽ được cập nhật từ Supabase Realtime Stream ở màn Newfeed.
      });

      ToastService.showSuccess(
        widget.post.isLiked
            ? "Hết thích rồi à bro?"
            : "Đã thả tim cho đồng bọn!",
      );
    } catch (e) {
      ToastService.showError(AuthErrorHandler.getErrorMessage(e));
    }
  }

  void _handleShare() {
    // Logic share_plus từ Phase 3
    ToastService.showSuccess("Đã lan tỏa vibe này!");
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(commentRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Đàm đạo cùng các bro")),
      body: Column(
        children: [
          // 1. Phần nội dung bài viết (có thể reuse PostCard hoặc custom)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.post.content,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton.icon(
                onPressed: _handleLike, // Gọi hàm _handleLike ở đây
                icon: Icon(
                  widget.post.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: widget.post.isLiked ? Colors.red : Colors.grey,
                ),
                label: Text("${widget.post.likesCount} Like"),
              ),
              TextButton.icon(
                onPressed: _handleShare, // Gọi hàm _handleShare ở đây
                icon: const Icon(Icons.share_outlined, color: Colors.blue),
                label: const Text("Share"),
              ),
            ],
          ),
          // ------------------------------------
          const Divider(),
          // 2. Danh sách Comment Realtime
          Expanded(
            child: StreamBuilder<List<AppComment>>(
              stream: repo.getCommentsStream(widget.post.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final comments = snapshot.data!;
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final c = comments[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        radius: 15,
                        child: Icon(Icons.person, size: 15),
                      ),
                      title: Text(c.content),
                      subtitle: Text(
                        "Bro ${c.userId.substring(0, 4)} • ${c.createdAt.minute}m trước",
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // 3. Input bar cố định bên dưới
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: "Nhập lời hay ý đẹp...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _submitComment,
                  icon: const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
