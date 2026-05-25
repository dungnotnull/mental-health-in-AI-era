import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/features/newfeed/domain/post.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:frontend/core/storage/storage_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frontend/core/network/supabase_client.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

part 'post_repository.g.dart';

class PostRepository {
  final SupabaseClient _client;
  final StorageRepository _storage;
  PostRepository(this._client, this._storage);

  Future<List<Post>> getPostsPaginated(int page, int limit, {String? category}) async {
    final userId = _client.auth.currentUser?.id;
    final from = page * limit;
    final to = from + limit - 1;

    final initialQuery = _client.from('posts').select('''
      *,
      profiles!posts_user_id_fkey(
        full_name, 
        avatar_url, 
        country, 
        occupation,
        is_premium,
        daily_moods!daily_moods_user_id_fkey(mood_score, created_at)
      ),
      post_likes(user_id),
      comments(id)
    ''');
    
    final filteredQuery = category != null 
        ? initialQuery.eq('category', category) 
        : initialQuery;
    
    final data = await filteredQuery
        .order('created_at', referencedTable: 'profiles.daily_moods', ascending: false)
        .limit(10, referencedTable: 'profiles.daily_moods')
        .order('created_at', ascending: false)
        .range(from, to);
    return data.map((json) {
      return Post.fromJson(json, currentUserId: userId);
    }).toList();
  }

  // Logic Toggle Like cực nhanh
  Future<void> toggleLike(int postId, bool currentlyLiked) async {
    final userId = _client.auth.currentUser!.id;
    if (currentlyLiked) {
      await _client.from('post_likes').delete().match({
        'post_id': postId,
        'user_id': userId,
      });
    } else {
      await _client.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    }
  }

  // 1. Logic upload ảnh lên Supabase Storage với Compression
  Future<List<String>> uploadImages(List<XFile> files) async {
    List<String> uploadedUrls = [];
    final userId = _client.auth.currentUser!.id;
    final tempDir = await getTemporaryDirectory();

    for (var file in files) {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}";
      final filePath = "$userId/$fileName"; // Tổ chức folder theo userId
      final targetPath = p.join(tempDir.path, 'compressed_$fileName');

      // Compress image
      XFile? compressedFile;
      if (['.jpg', '.jpeg', '.png', '.webp'].contains(p.extension(file.path).toLowerCase())) {
        compressedFile = await FlutterImageCompress.compressAndGetFile(
          file.path,
          targetPath,
          quality: 70, // Giảm chất lượng xuống 70% để tiết kiệm dung lượng
          minWidth: 1080,
          minHeight: 1080,
        );
      }
      
      final uploadFile = compressedFile != null ? File(compressedFile.path) : File(file.path);

      final url = await _storage.uploadImage(
        bucket: 'posts_images',
        file: uploadFile,
        path: filePath,
      );
      uploadedUrls.add(url);
      
      // Clean up temp file
      if (compressedFile != null && await File(compressedFile.path).exists()) {
        await File(compressedFile.path).delete();
      }
    }
    return uploadedUrls;
  }

  // 2. Tạo bài viết hoàn chỉnh
  Future<void> createPost({
    required String content,
    List<XFile>? images,
    String? category,
  }) async {
    final userId = _client.auth.currentUser!.id;
    List<String> imageUrls = [];

    if (images != null && images.isNotEmpty) {
      imageUrls = await uploadImages(images);
    }

    await _client.from('posts').insert({
      'user_id': userId,
      'content': content,
      'image_urls': imageUrls,
      if (category != null) 'category': category,
    });
  }

  // 3. Cập nhật bài viết (Chỉ cho phép cập nhật text)
  Future<void> updatePost({
    required int postId,
    required String content,
  }) async {
    await _client.from('posts').update({
      'content': content,
    }).eq('id', postId);
  }

  // 4. Xóa bài viết và dọn dẹp media
  Future<void> deletePost({
    required int postId,
    required List<String> imageUrls,
  }) async {
    // 1. Xóa khỏi DB (FK cascade nên post_likes, comments sẽ tự xóa nếu DB type là vậy, 
    // nếu không thì phải xóa bằng tay. Giả định Supabase setup cascade).
    await _client.from('posts').delete().eq('id', postId);

    // 2. Dọn dẹp media
    if (imageUrls.isNotEmpty) {
      await _storage.deleteFiles(bucket: 'posts_images', paths: imageUrls);
    }
  }

  // Stream realtime update cho 1 bài viết
  Stream<void> watchPostChanges(int postId) {
    return _client
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('id', postId)
        .map((_) => null);
  }
}

@riverpod
PostRepository postRepository(PostRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  final storage = ref.watch(storageRepositoryProvider);
  return PostRepository(client, storage);
}
