import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/supabase_client.dart';
import 'package:frontend/features/profile/data/profile_repository.dart';
import 'package:frontend/features/profile/data/follow_repository.dart';
import 'package:frontend/features/daily_mood/domain/mood.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:frontend/features/newfeed/domain/post.dart';
import 'package:frontend/features/profile/domain/profile.dart';

final myMoodHistoryProvider = FutureProvider.autoDispose<List<DailyMood>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getMyMoodHistory();
});

final followingListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(followRepositoryProvider);
  return repo.getFollowingWithLatestStatus(page: 0, pageSize: 5);
});

final myProfileProvider = FutureProvider.autoDispose<Profile>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getMyProfile();
});

final profilePagingControllerProvider = Provider.autoDispose<PagingController<int, Post>>((ref) {
  final controller = PagingController<int, Post>(firstPageKey: 0);
  
  controller.addPageRequestListener((pageKey) async {
    try {
      final repo = ref.read(profileRepositoryProvider);
      final newItems = await repo.getMyPosts(page: pageKey, pageSize: 10);
      final isLastPage = newItems.length < 10;
      if (isLastPage) {
        controller.appendLastPage(newItems);
      } else {
        controller.appendPage(newItems, pageKey + 1);
      }
    } catch (error) {
      controller.error = error;
    }
  });

  ref.onDispose(() => controller.dispose());
  return controller;
});
