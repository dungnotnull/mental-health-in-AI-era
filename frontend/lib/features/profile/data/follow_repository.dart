import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frontend/core/network/supabase_client.dart';
import 'package:frontend/features/profile/domain/profile.dart';
import 'package:frontend/features/daily_mood/domain/mood.dart';

part 'follow_repository.g.dart';

class FollowRepository {
  final SupabaseClient _client;
  FollowRepository(this._client);

  Future<void> follow(String targetId) async {
    final myId = _client.auth.currentUser!.id;
    await _client.from('follows').insert({
      'follower_id': myId,
      'following_id': targetId,
    });
  }

  Future<void> unfollow(String targetId) async {
    final myId = _client.auth.currentUser!.id;
    await _client.from('follows').delete().match({
      'follower_id': myId,
      'following_id': targetId,
    });
  }

  Future<bool> isFollowing(String targetId) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return false;
    
    final data = await _client
        .from('follows')
        .select()
        .match({
          'follower_id': myId,
          'following_id': targetId,
        })
        .maybeSingle();
    return data != null;
  }

  Future<List<Map<String, dynamic>>> getFollowingWithLatestStatus({int page = 0, int pageSize = 10}) async {
    final myId = _client.auth.currentUser!.id;
    
    final from = page * pageSize;
    final to = from + pageSize - 1;

    // Fetch profiles followed by me, including their latest mood
    // Optimized to avoid N+1 queries using Supabase nested selects
    final response = await _client
        .from('follows')
        .select('''
          following_id,
          profiles:following_id (
            id,
            full_name,
            username,
            avatar_url,
            daily_moods (
              mood_score,
              created_at
            )
          )
        ''')
        .eq('follower_id', myId)
        .order('created_at', referencedTable: 'profiles.daily_moods', ascending: false)
        .limit(1, referencedTable: 'profiles.daily_moods')
        .range(from, to);

    if (response == null) return [];

    final List<Map<String, dynamic>> result = [];
    for (var item in response as List) {
      final profileData = item['profiles'];
      if (profileData == null) continue;

      final moods = profileData['daily_moods'] as List;
      final latestMood = moods.isNotEmpty ? moods[0] : null;

      result.add({
        'profile': Profile.fromJson(profileData),
        'latest_mood': latestMood != null ? DailyMood.fromJson(latestMood) : null,
      });
    }
    return result;
  }
}

@riverpod
FollowRepository followRepository(FollowRepositoryRef ref) {
  return FollowRepository(ref.watch(supabaseClientProvider));
}
