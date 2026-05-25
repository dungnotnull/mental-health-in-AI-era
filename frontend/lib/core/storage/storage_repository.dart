import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frontend/core/network/supabase_client.dart';

part 'storage_repository.g.dart';

class StorageRepository {
  final SupabaseClient _client;
  StorageRepository(this._client);

  /// Uploads an image to the specified bucket and returns the public URL.
  Future<String> uploadImage({
    required String bucket,
    required File file,
    required String path,
  }) async {
    // Basic verification: only allow image files based on extension
    final ext = p.extension(file.path).toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.heif'].contains(ext)) {
      throw Exception('Only image files are allowed, bro! (Got: $ext)');
    }

    try {
      print("DEBUG: Uploading to $bucket: $path");
      await _client.storage.from(bucket).upload(
        path,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true), // Use upsert: true to avoid "already exists" errors
      );
    } catch (e) {
      print("DEBUG: Storage Upload Error: $e");
      rethrow;
    }

    return _client.storage.from(bucket).getPublicUrl(path);
  }

  /// Deletes a file or list of files from the specified bucket.
  Future<void> deleteFiles({
    required String bucket,
    required List<String> paths,
  }) async {
    if (paths.isEmpty) return;
    
    // Convert URLs to paths if necessary (Supabase getPublicUrl returns full URL)
    // For deletion, we need the path within the bucket.
    final List<String> relativePaths = paths.map((url) {
      if (url.startsWith('http')) {
        // Simple extraction logic: find the part after the bucket name
        final parts = url.split(bucket + '/');
        return parts.length > 1 ? parts.last : url;
      }
      return url;
    }).toList();

    try {
      print("DEBUG: Deleting from $bucket: $relativePaths");
      await _client.storage.from(bucket).remove(relativePaths);
    } catch (e) {
      print("DEBUG: Storage Delete Error: $e");
      // Don't rethrow here if it's just a cleanup failure
    }
  }
}

@riverpod
StorageRepository storageRepository(StorageRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return StorageRepository(client);
}
