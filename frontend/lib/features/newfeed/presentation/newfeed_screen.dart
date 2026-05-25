import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:frontend/core/network/supabase_client.dart';
import 'package:frontend/core/navigation/navigation_provider.dart';
import 'package:frontend/core/common_widgets/loading_indicator.dart';
import 'package:frontend/core/common_widgets/toast_service.dart';
import '../data/post_repository.dart';
import '../domain/post.dart';
import 'widgets/post_card.dart';
import 'create_post_screen.dart';
import 'newfeed_provider.dart';
import '../../../core/common_widgets/video_player_widget.dart';

class NewfeedScreen extends ConsumerStatefulWidget {
  const NewfeedScreen({super.key});

  @override
  ConsumerState<NewfeedScreen> createState() => _NewfeedScreenState();
}

class _NewfeedScreenState extends ConsumerState<NewfeedScreen> {
  final List<String> _quotes = [
  "Everything will get better, keep pushing, don't give up!",
  "Success is not final, failure is not fatal: it is the courage to continue that counts.",
  "Hardships often prepare ordinary people for an extraordinary destiny.",
  "Believe in yourself and all that you are. You are stronger than you think.",
  "The brotherhood is here for you. Stay strong, bro!",
  "AI is just a machine; we are humans who know how to try and love each other every single day.",
  "Algorithms can predict the future, but only human hustle can create it.",
  "No machine can ever replicate the fire in your soul. Keep grinding, bro.",
  "Tough times never last, but tough people do.",
  "They can automate tasks, but they can never automate our brotherhood and resilience.",
  "Small progress is still progress. Be proud of your human effort today.",
  "A setback is just a setup for a massive comeback.",
  "You are building resilience that no software update could ever install.",
  "Don't let a bad chapter convince you the whole book is bad.",
  "We are all rooting for you. Keep that human spirit burning!",
  "Your value doesn't decrease just because a machine learned to do your old job.",
  "Fall down seven times, stand up eight. That's a human glitch machines will never understand.",
  "The storm will pass, and you will emerge stronger than ever.",
  "Keep grinding, bro. Your human intuition is your ultimate superpower.",
  "Every expert was once a beginner. Give yourself time to grow.",
  "You are capable of amazing things. Never doubt that.",
  "Focus on the step in front of you, not the whole staircase.",
  "Good things are coming down the road. Just keep walking.",
  "Your empathy is your greatest asset. Protect it and use it well.",
  "It's okay to rest, but never quit. We're in this together.",
  "AI doesn't have a heart to break or a dream to chase. You do. Keep chasing.",
  "Breathe. You're going to figure this out like you always do.",
  "A smooth sea never made a skilled sailor. Embrace the waves.",
  "Your future needs your unique human touch. Keep showing up.",
  "Big journeys begin with small, quiet steps.",
  "You are writing a comeback story that no AI could ever generate.",
  "Don't stress over what you can't control. Focus on your own hustle.",
  "The sun will rise, and we will try again.",
  "You're not starting from scratch; you're starting from human experience.",
  "Keep the faith, bro. Hard work and patience always pay off.",
  "Even the longest night turns into morning. Hang in there.",
  "Machines process data, but we process emotions, heal, and grow stronger.",
  "Channel your frustration into fuel for your next big move.",
  "You are a work of art and a work in progress at the same time.",
  "Let your hope be bigger than your fear today.",
  "The only way out is through. Keep moving forward.",
  "You're stronger than any technological shift thrown your way.",
  "Celebrate the small wins today. They add up to big victories.",
  "Nobody can be you, and that is your biggest power.",
  "Keep your vision clear and your hustle quiet.",
  "You are planting seeds right now. Soon, you will see them bloom.",
  "Don't look back; you're not going that way.",
  "Your mind is a powerful thing. Fill it with positive thoughts.",
  "We fall, we break, we fail. But then, we rise, we heal, we overcome.",
  "Take a deep breath. You are doing much better than you realize.",
  "Every day is a fresh start. Make today count.",
  "You are the author of your own life. Write a brilliant next chapter.",
  "Stay patient and trust your journey. Your time is coming.",
  "Obstacles are just detours in the right direction.",
  "We're standing right beside you, bro. Let's conquer today together!"
]
;
  late String _currentQuote;

  @override
  void initState() {
    super.initState();
    _currentQuote = _quotes[DateTime.now().millisecond % _quotes.length];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  // Floating Bubbles Background
                  const Positioned.fill(child: _FloatingBubbles()),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 20, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "BRO'S VIBE SPACE",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "\"$_currentQuote\"",
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showSituationVideos(context),
                      icon: const Icon(Icons.play_circle_fill, size: 18),
                      label: const Text("Watch Current Situation", style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                const TabBar(
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black38,
                  indicatorColor: Colors.black,
                  indicatorWeight: 3,
                  tabs: [
                    Tab(text: "General Feed"),
                    Tab(text: "AI Money Ideas"),
                    Tab(text: "Recruitment"),
                  ],
                ),
              ),
            ),
          ],
          body: const TabBarView(
            children: [
              PostListTab(
                category: null,
                banner: "How’s work going today? Is life with AI still treating you well?",
              ),
              PostListTab(
                category: 'money_making',
                banner: "A place for you to share ways to make money with AI. We want real experiences from the community, not empty AI-generated knowledge.",
              ),
              PostListTab(
                category: 'recruitment',
                banner: "Looking for talent or a new opportunity? Share your recruitment needs and support the brotherhood here!",
              ),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () {
                final tabController = DefaultTabController.of(context);
                String? initialCategory;
                if (tabController.index == 1) {
                  initialCategory = 'money_making';
                } else if (tabController.index == 2) {
                  initialCategory = 'recruitment';
                }
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreatePostScreen(initialCategory: initialCategory),
                  ),
                );
              },
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }

  void _showSituationVideos(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Current Situation",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    children: [
                      const _VideoLabel(label: "Companies cut thousands of jobs amid corporate AI push"),
                      const VideoPlayerWidget(
                        assetPath: 'assets/intro1.mp4', 
                        height: 220,
                        autoPlay: false,
                        muteInitial: false,
                      ),
                      const SizedBox(height: 20),
                      const _VideoLabel(label: "AI Will Replace Many, MANY Jobs…, Hinton Warns Of AI Job Crisis In 2026 | These Jobs Are NOT Safe"),
                      const VideoPlayerWidget(
                        assetPath: 'assets/intro2.mp4', 
                        height: 220,
                        autoPlay: false,
                        muteInitial: false,
                      ),
                      const SizedBox(height: 20),
                      const _VideoLabel(label: "WARNING: AI Is About to Replace These 40 Jobs — Are You Safe?"),
                      const VideoPlayerWidget(
                        assetPath: 'assets/intro3.mp4', 
                        height: 220,
                        autoPlay: false,
                        muteInitial: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoLabel extends StatelessWidget {
  final String label;
  const _VideoLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0, right: 8.0),
            child: Icon(Icons.play_arrow, size: 16, color: Colors.blue),
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: const Color(0xFFF5F7FA),
      elevation: shrinkOffset > 0 ? 2 : 0,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class PostListTab extends ConsumerStatefulWidget {
  final String? category;
  final String? banner;
  const PostListTab({super.key, this.category, this.banner});

  @override
  ConsumerState<PostListTab> createState() => _PostListTabState();
}

class _PostListTabState extends ConsumerState<PostListTab> {
  static const _pageSize = 10;
  final PagingController<int, Post> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final repo = ref.read(postRepositoryProvider);
      final newItems = await repo.getPostsPaginated(
        pageKey,
        _pageSize,
        category: widget.category,
      );
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
  Widget build(BuildContext context) {
    final repo = ref.watch(postRepositoryProvider);
    
    // Auto refresh when navigating to Feed tab
    ref.listen(navigationIndexProvider, (previous, next) {
      if (next == 1) {
        _pagingController.refresh();
      }
    });

    // Listen to manual refresh signals (e.g. from PostCard delete)
    ref.listen(newfeedProvider, (_, __) {
      _pagingController.refresh();
    });

    return RefreshIndicator(
      onRefresh: () => Future.sync(() => _pagingController.refresh()),
      child: PagedListView<int, Post>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<Post>(
          itemBuilder: (context, post, index) {
            final card = PostCard(
              post: post,
              onLike: () async {
                // Optimistic UI update: Toggle like state locally
                final newIsLiked = !post.isLiked;
                final newLikesCount = (newIsLiked ? post.likesCount + 1 : post.likesCount - 1).clamp(0, 999999);
                
                final updatedPost = post.copyWith(
                  isLiked: newIsLiked,
                  likesCount: newLikesCount,
                );

                // Update the paging controller directly
                final items = List<Post>.from(_pagingController.itemList ?? []);
                if (index < items.length) {
                  items[index] = updatedPost;
                  _pagingController.itemList = items;
                }

                try {
                  await repo.toggleLike(post.id, post.isLiked);
                  // No need to refresh, the local update is enough
                } catch (e) {
                  // Rollback on error
                  final rollbackItems = List<Post>.from(_pagingController.itemList ?? []);
                  if (index < rollbackItems.length) {
                    rollbackItems[index] = post;
                    _pagingController.itemList = rollbackItems;
                  }
                  ToastService.showError("Failed to update like");
                }
              },
              onComment: () {
                // Optimistic UI update for comments
                final updatedPost = post.copyWith(
                  commentsCount: post.commentsCount + 1,
                );
                final items = List<Post>.from(_pagingController.itemList ?? []);
                if (index < items.length) {
                  items[index] = updatedPost;
                  _pagingController.itemList = items;
                }
              },
            );

            final animatedCard = TweenAnimationBuilder<double>(
              key: ValueKey('post_${post.id}'),
              duration: Duration(milliseconds: 500 + (index % 5 * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: card,
            );

            if (index == 0 && widget.banner != null) {
              return Column(
                children: [
                  _buildBanner(),
                  animatedCard,
                ],
              );
            }
            return animatedCard;
          },
          firstPageProgressIndicatorBuilder: (_) => const BroLoadingIndicator(),
          newPageProgressIndicatorBuilder: (_) => const Padding(
            padding: EdgeInsets.all(16.0),
            child: BroLoadingIndicator(size: 30),
          ),
          firstPageErrorIndicatorBuilder: (context) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  "Something went wrong, bro!\n${_pagingController.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _pagingController.refresh(),
                  child: const Text("TRY AGAIN"),
                ),
              ],
            ),
          ),
        ),
        noItemsFoundIndicatorBuilder: (_) => const Center(
          child: Text("Chưa có bài viết nào bro ơi..."),
        ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1000),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.tips_and_updates, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              widget.banner!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}

class _FloatingBubbles extends StatelessWidget {
  const _FloatingBubbles();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: Stack(
          children: List.generate(6, (index) {
          final size = 40.0 + (index * 20.0);
          final left = (index * 60.0) % (MediaQuery.of(context).size.width - size);
          
          return TweenAnimationBuilder<double>(
            duration: Duration(seconds: 5 + index),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              final verticalOffset = -50 + (100 * value);
              return Positioned(
                left: left,
                top: verticalOffset + (index * 30),
                child: Opacity(
                  opacity: (0.1 - (0.05 * value)).clamp(0, 1),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.blue.withOpacity(0.4),
                          Colors.blue.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            onEnd: () {}, // Handled by continuous builder if necessary, but TweenAnimationBuilder is enough for simple loop if we reset it. 
            // Actually let's use a simpler infinite animation for performance.
          );
        }),
      ),
    ),
  );
 }
}
