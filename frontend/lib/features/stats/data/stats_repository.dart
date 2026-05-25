import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/mood_stat.dart';

class StatsRepository {
  final SupabaseClient _client;
  StatsRepository(this._client);

  Future<List<MoodStat>> getCommunityStats() async {
    final data = await _client
        .from('community_mood_stats')
        .select();
    return (data as List).map((json) => MoodStat.fromJson(json)).toList();
  }

  Future<int> getTotalBrosCount() async {
    final response = await _client
        .from('profiles')
        .select('id');
    return (response as List).length;
  }
}
