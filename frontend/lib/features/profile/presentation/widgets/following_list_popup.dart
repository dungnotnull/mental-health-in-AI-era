import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/profile/data/follow_repository.dart';
import 'package:frontend/features/profile/domain/profile.dart';
import 'package:frontend/features/daily_mood/domain/mood.dart';
import 'package:frontend/core/common_widgets/loading_indicator.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class FollowingListPopup extends ConsumerStatefulWidget {
  const FollowingListPopup({super.key});

  @override
  ConsumerState<FollowingListPopup> createState() => _FollowingListPopupState();
}

class _FollowingListPopupState extends ConsumerState<FollowingListPopup> {
  static const _pageSize = 10;
  final PagingController<int, Map<String, dynamic>> _pagingController = PagingController(firstPageKey: 0);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final repo = ref.read(followRepositoryProvider);
      final newItems = await repo.getFollowingWithLatestStatus(page: pageKey, pageSize: _pageSize);
      
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "MY BROTHERS",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: PagedListView<int, Map<String, dynamic>>(
              pagingController: _pagingController,
              padding: const EdgeInsets.symmetric(vertical: 10),
              builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
                itemBuilder: (context, item, index) {
                  final profile = item['profile'] as Profile;
                  final latestMood = item['latest_mood'] as DailyMood?;
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: profile.avatarUrl != null 
                            ? NetworkImage(profile.avatarUrl!) 
                            : null,
                          child: profile.avatarUrl == null 
                            ? const Icon(Icons.person, color: Colors.grey) 
                            : null,
                        ),
                        if (latestMood != null)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getMoodIcon(latestMood.moodScore),
                                size: 14,
                                color: _getMoodColor(latestMood.moodScore),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      profile.fullName ?? "Anonymous Bro",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "@${profile.username ?? "bro"}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    trailing: latestMood != null 
                      ? Text(
                          _getMoodLabel(latestMood.moodScore),
                          style: TextStyle(
                            color: _getMoodColor(latestMood.moodScore),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        )
                      : const Text(
                          "No status",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                  );
                },
                firstPageErrorIndicatorBuilder: (_) => const Center(child: Text("Failed to load bros.")),
                noItemsFoundIndicatorBuilder: (_) => const Center(child: Text("You haven't followed any brothers yet.")),
                firstPageProgressIndicatorBuilder: (_) => const BroLoadingIndicator(),
                newPageProgressIndicatorBuilder: (_) => const BroLoadingIndicator(size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMoodIcon(int score) {
    if (score == 1) return Icons.sentiment_very_dissatisfied_rounded;
    if (score == 2) return Icons.sentiment_neutral_rounded;
    return Icons.sentiment_satisfied_rounded;
  }

  Color _getMoodColor(int score) {
    if (score == 1) return const Color(0xFFE91E63);
    if (score == 2) return const Color(0xFFFF9800);
    return const Color(0xFF4CAF50);
  }

  String _getMoodLabel(int score) {
    if (score == 1) return "Stressed";
    if (score == 2) return "Not Okay";
    return "Still Okay";
  }
}
