import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/core/common_widgets/toast_service.dart';
import 'package:frontend/core/network/supabase_client.dart';
import 'package:frontend/features/auth/application/auth_error_handler.dart';
import '../data/post_repository.dart';
import 'newfeed_provider.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:frontend/core/common_widgets/loading_indicator.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const CreatePostScreen({super.key, this.initialCategory});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  final List<XFile> _selectedImages = [];
  bool _isUploading = false;
  bool _showEmojiPicker = false;
  
  // Category selection
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'general';
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 2) {
      ToastService.showError("Max 2 photos, bro! 📸");
      return;
    }
    
    // Pick multiple images at once
    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 70,
    );
    
    if (images.isNotEmpty) {
      setState(() {
        // Only take up to what's left to reach 2
        final remainingSlots = 2 - _selectedImages.length;
        if (images.length > remainingSlots) {
          _selectedImages.addAll(images.take(remainingSlots));
          ToastService.showInfo("Only 2 photos allowed, bro! Keeping the first 2.");
        } else {
          _selectedImages.addAll(images);
        }
      });
    }
  }

  Future<void> _submitPost() async {
    if (_contentController.text.isEmpty) {
      ToastService.showError("Write something, bro...");
      return;
    }

    setState(() => _isUploading = true);
    try {
      final repo = ref.read(postRepositoryProvider);
      await repo.createPost(
        content: _contentController.text.trim(),
        images: _selectedImages,
        category: _selectedCategory == 'general' ? null : _selectedCategory,
      );
      ToastService.showSuccess("Post shared!");
      ref.read(newfeedProvider.notifier).state++;
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ToastService.showError(AuthErrorHandler.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildCategorySelector() {
    final categories = [
      {'id': 'general', 'label': 'General', 'icon': Icons.chat_bubble_outline},
      {'id': 'money_making', 'label': 'Money', 'icon': Icons.attach_money},
      {'id': 'recruitment', 'label': 'Jobs', 'icon': Icons.work_outline},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "POST TYPE",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: categories.map((cat) {
            final isSelected = _selectedCategory == cat['id'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat['id'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    right: cat['id'] != 'recruitment' ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                        color: isSelected ? Colors.white : Colors.black54,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cat['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "CREATE POST",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        actions: [
          _isUploading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: BroLoadingIndicator(size: 24),
                )
              : TextButton(
                  onPressed: _submitPost,
                  child: const Text(
                    "POST",
                    style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blue),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // Category Selector - Improved UI
                    _buildCategorySelector(),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _contentController,
                    maxLines: 8,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: "What's on your mind, bro?",
                      border: InputBorder.none,
                    ),
                    onTap: () {
                      if (_showEmojiPicker) setState(() => _showEmojiPicker = false);
                    },
                  ),
                  const SizedBox(height: 20),
                  // Image Preview
                  if (_selectedImages.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) => Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(File(_selectedImages[index].path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 17,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedImages.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                    color: Colors.orange,
                  ),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    setState(() => _showEmojiPicker = !_showEmojiPicker);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.image_outlined, color: Colors.blue),
                  onPressed: _pickImage,
                ),
                const Spacer(),
                Text(
                  "${_selectedImages.length}/2 photos",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _contentController.text += emoji.emoji;
                },
                config: const Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  skinToneConfig: SkinToneConfig(),
                  categoryViewConfig: CategoryViewConfig(),
                  bottomActionBarConfig: BottomActionBarConfig(),
                  searchViewConfig: SearchViewConfig(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
