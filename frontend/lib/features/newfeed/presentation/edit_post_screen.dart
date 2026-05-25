import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common_widgets/toast_service.dart';
import 'package:frontend/core/common_widgets/loading_indicator.dart';
import 'package:frontend/features/newfeed/data/post_repository.dart';
import 'package:frontend/features/newfeed/domain/post.dart';
import 'package:frontend/features/auth/application/auth_error_handler.dart';

class EditPostScreen extends ConsumerStatefulWidget {
  final Post post;
  const EditPostScreen({super.key, required this.post});

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  late final TextEditingController _contentController;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post.content);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (_contentController.text.trim().isEmpty) {
      ToastService.showError("Content cannot be empty, bro!");
      return;
    }

    setState(() => _isUpdating = true);
    try {
      await ref.read(postRepositoryProvider).updatePost(
        postId: widget.post.id,
        content: _contentController.text.trim(),
      );
      ToastService.showSuccess("Post updated!");
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ToastService.showError(AuthErrorHandler.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "EDIT POST",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        actions: [
          _isUpdating
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: BroLoadingIndicator(size: 24),
                )
              : TextButton(
                  onPressed: _handleUpdate,
                  child: const Text(
                    "UPDATE",
                    style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blue),
                  ),
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _contentController,
              maxLines: 8,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                hintText: "Update your thoughts...",
                border: InputBorder.none,
              ),
              autofocus: true,
            ),
            const Spacer(),
            if (widget.post.imageUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Note: Images cannot be changed during edit to keep it simple, bro!",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
