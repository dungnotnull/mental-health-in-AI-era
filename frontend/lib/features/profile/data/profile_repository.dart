import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/features/profile/domain/profile.dart';
import 'package:frontend/features/newfeed/domain/post.dart';
import 'package:frontend/features/daily_mood/domain/mood.dart';
import 'package:frontend/core/storage/storage_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frontend/core/network/supabase_client.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

part 'profile_repository.g.dart';

class ProfileRepository {
  final SupabaseClient _client;
  final StorageRepository _storage;
  ProfileRepository(this._client, this._storage);

  // Lấy thông tin cá nhân
  Future<Profile> getMyProfile() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return Profile.fromJson(data);
  }

  // Lấy lịch sử Mood (Phân trang)
  Future<List<DailyMood>> getMyMoodHistory({int limit = 10}) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('daily_moods')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).map((json) => DailyMood.fromJson(json)).toList();
  }

  // 1. Logic upload avatar và xóa ảnh cũ với Compression
  Future<String> uploadAvatar(File file, {String? oldAvatarUrl}) async {
    final userId = _client.auth.currentUser!.id;
    final fileName = "avatar_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}";
    final filePath = "$userId/$fileName";
    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(tempDir.path, 'compressed_$fileName');

    // Xóa ảnh cũ nếu có
    if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
      try {
        await _storage.deleteFiles(bucket: 'avatars', paths: [oldAvatarUrl]);
      } catch (e) {
        // Log error but continue to upload new one
        print("Error deleting old avatar: $e");
      }
    }

    // Compress avatar
    XFile? compressedFile;
    if (['.jpg', '.jpeg', '.png', '.webp'].contains(p.extension(file.path).toLowerCase())) {
      compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 60, // Avatar có thể nén mạnh hơn
        minWidth: 512,
        minHeight: 512,
      );
    }
    
    final uploadFile = compressedFile != null ? File(compressedFile.path) : file;

    // Upload ảnh mới
    final url = await _storage.uploadImage(
      bucket: 'avatars',
      file: uploadFile,
      path: filePath,
    );
    
    // Clean up temp file
    if (compressedFile != null && await File(compressedFile.path).exists()) {
      await File(compressedFile.path).delete();
    }
    
    return url;
  }

  // Cập nhật Profile
  Future<void> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? country,
    String? occupation,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final updates = {
      if (fullName != null) 'full_name': fullName,
      if (username != null) 'username': username,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (country != null) 'country': country,
      if (occupation != null) 'occupation': occupation,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (updates.length <= 1) return; // Chỉ có updated_at thì thôi

    await _client.from('profiles').update(updates).eq('id', userId);
  }

  // Lấy lịch sử bài đăng của chính mình (Infinite Scroll)
  Future<List<Post>> getMyPosts({int page = 0, int pageSize = 10}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final from = page * pageSize;
    final to = from + pageSize - 1;

    final response = await _client
        .from('posts')
        .select('''
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
        ''')
        .eq('user_id', userId)
        .order('created_at', referencedTable: 'profiles.daily_moods', ascending: false)
        .limit(10, referencedTable: 'profiles.daily_moods')
        .order('created_at', ascending: false)
        .range(from, to);

    return (response as List).map((json) {
      return Post.fromJson(json, currentUserId: userId);
    }).toList();
  }
}

@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  final storage = ref.watch(storageRepositoryProvider);
  return ProfileRepository(client, storage);
}
