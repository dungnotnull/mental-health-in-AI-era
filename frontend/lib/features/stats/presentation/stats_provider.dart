import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/supabase_client.dart';
import '../data/stats_repository.dart';
import '../domain/mood_stat.dart';

final communityStatsProvider = FutureProvider.autoDispose<List<MoodStat>>((ref) async {
  final repo = StatsRepository(ref.watch(supabaseClientProvider));
  return repo.getCommunityStats();
});
final totalBrosProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = StatsRepository(ref.watch(supabaseClientProvider));
  return repo.getTotalBrosCount();
});
