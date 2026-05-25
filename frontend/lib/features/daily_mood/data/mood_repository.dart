import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/storage/hive_client.dart';
import '../domain/mood.dart';

class MoodRepository {
  final SupabaseClient _client;
  MoodRepository(this._client);

  Future<void> submitMood(DailyMood mood) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await _client
        .from('daily_moods')
        .insert({
          ...mood.toJson(),
          'user_id': userId,
        })
        .select()
        .single();
    // Cache vào Hive ngay sau khi submit thành công
    await HiveClient.cacheMood(response);
  }

  Future<DailyMood?> getLatestMood() async {
    // 1. Ưu tiên lấy từ Hive (Offline-first)
    final cached = HiveClient.getCachedMood();
    if (cached != null)
      return DailyMood.fromJson(Map<String, dynamic>.from(cached));

    // 2. Nếu Hive trống, fetch từ Supabase
    final userId = _client.auth.currentUser?.id;
    final data = await _client
        .from('daily_moods')
        .select()
        .eq('user_id', userId!)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data != null) {
      await HiveClient.cacheMood(data);
      return DailyMood.fromJson(data);
    }
    return null;
  }
}

extension MoodAIRepository on MoodRepository {
  Future<Map<String, dynamic>> getAISuperPower(int score, String text) async {
    final response = await _client.functions.invoke(
      'grok-mood-analysis',
      body: {'mood_score': score, 'feeling_text': text},
    );
    return response.data as Map<String, dynamic>;
  }
}
