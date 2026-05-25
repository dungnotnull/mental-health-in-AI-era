import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common_widgets/toast_service.dart';
import 'package:frontend/core/network/supabase_client.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/profile/domain/profile.dart';
import '../data/profile_repository.dart';
import '../data/subscription_repository.dart';
import 'premium_screen.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:frontend/features/newfeed/domain/post.dart';
import 'package:frontend/features/newfeed/presentation/widgets/post_card.dart';
import 'package:frontend/core/common_widgets/loading_indicator.dart';
import '../../newfeed/presentation/newfeed_provider.dart';
import 'edit_profile_screen.dart';
import 'profile_provider.dart';
import 'package:frontend/features/newfeed/data/post_repository.dart';
import 'package:frontend/features/daily_mood/domain/mood.dart';
import 'package:frontend/features/daily_mood/presentation/widgets/mood_history_card.dart';
import 'widgets/following_list_popup.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    // Listen to manual refresh signals (e.g. from PostCard delete)
    ref.listen(newfeedProvider, (_, __) {
      ref.read(profilePagingControllerProvider).refresh();
      ref.invalidate(myProfileProvider);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "MY PROFILE",
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 20, 
            letterSpacing: 1.5,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _handleLogout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(profilePagingControllerProvider).refresh();
          ref.invalidate(myProfileProvider);
          ref.invalidate(followingListProvider);
          ref.invalidate(myMoodHistoryProvider);
        },
        child: CustomScrollView(
          slivers: [
            _ProfileHeader(),

            // Mood History Header
            _buildAnimatedSliver(
              index: 1,
              child: const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 30, 16, 15),
                  child: Text(
                    "MY PROGRESS",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                  ),
                ),
              ),
            ),

            _buildAnimatedSliver(index: 2, child: const _MoodHistoryPreview()),

            _buildAnimatedSliver(
              index: 3,
              child: const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 35, 16, 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "FOLLOWING BROTHERS",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                      ),
                      _ShowAllButton(),
                    ],
                  ),
                ),
              ),
            ),

            _buildAnimatedSliver(index: 4, child: const _FollowingListPreview()),
            
            // Post Feed Header
            _buildAnimatedSliver(
              index: 5,
              child: const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 35, 16, 10),
                  child: Text(
                    "MY POSTS",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                  ),
                ),
              ),
            ),

            _buildAnimatedSliver(index: 6, child: const _MyPostsList()),
            
            SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
      ToastService.showSuccess("Logout successful. See you later!");
    } catch (e) {
      ToastService.showError("Logout failed: ${e.toString()}");
    }
  }

  Widget _buildAnimatedSliver({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return SliverOpacity(
          opacity: value.clamp(0.0, 1.0),
          sliver: child!,
        );
      },
      child: child,
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myProfileAsync = ref.watch(myProfileProvider);
    final moodHistoryAsync = ref.watch(myMoodHistoryProvider);
    final subRepo = SubscriptionRepository(ref.watch(supabaseClientProvider));

    return SliverToBoxAdapter(
      child: myProfileAsync.when(
        loading: () => const SizedBox(height: 200, child: Center(child: BroLoadingIndicator())),
        error: (err, stack) => const SizedBox.shrink(),
        data: (profile) {
          final badges = profile.getBadges(moodHistoryAsync.value ?? []);
          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutQuart,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar Section
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.blue.withOpacity(0.1), width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.grey.shade100,
                              backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                              child: profile.avatarUrl == null ? const Icon(Icons.person, size: 45, color: Colors.grey) : null,
                            ),
                          ),
                          if (profile.isPremium)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.blue, 
                                  shape: BoxShape.circle, 
                                  border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                                ),
                                child: const Icon(Icons.verified, color: Colors.white, size: 16),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Info Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              profile.fullName ?? "Anonymous Bro",
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                            ),
                            Text(
                              "@${profile.username ?? 'bro'}",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: badges.map((badge) => _buildBadgeChip(badge)).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Location & Occupation
                  if (profile.country != null || profile.occupation != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (profile.country != null)
                          _buildHeaderBadge(
                            label: profile.country!,
                            icon: _getCountryFlag(profile.country!),
                            color: Colors.green.shade50,
                            textColor: Colors.green.shade700,
                          ),
                        if (profile.occupation != null)
                          _buildHeaderBadge(
                            label: profile.occupation!,
                            icon: _getOccupationIcon(profile.occupation!),
                            color: Colors.blue.shade50,
                            textColor: Colors.blue.shade700,
                          ),
                      ],
                    ),
                  
                  if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Text(
                        profile.bio!,
                        style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeaderButton(
                          context,
                          icon: Icons.edit_note_rounded,
                          label: "Edit Profile",
                          onPressed: () async {
                            final result = await Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile))
                            );
                            if (result == true) {
                              ref.invalidate(myProfileProvider);
                              ref.read(profilePagingControllerProvider).refresh();
                            }
                          },
                        ),
                      ),
                      if (subRepo.isConfigured && !profile.isPremium) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildHeaderButton(
                            context,
                            icon: Icons.auto_awesome_rounded,
                            label: "Upgrade",
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
                            },
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed, Color? color}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color != null ? Colors.white : Colors.black87),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.grey.shade100,
        foregroundColor: color != null ? Colors.white : Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildHeaderBadge({required String label, required String icon, required Color color, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  String _getCountryFlag(String countryName) {
    final countries = {
      'Việt Nam': '🇻🇳', 'Singapore': '🇸🇬', 'United States': '🇺🇸',
      'Japan': '🇯🇵', 'South Korea': '🇰🇷', 'Thailand': '🇹🇭', 'Australia': '🇦🇺',
      'United Kingdom': '🇬🇧', 'Germany': '🇩🇪', 'France': '🇫🇷', 'Canada': '🇨🇦'
    };
    return countries[countryName] ?? '🌍';
  }

  String _getOccupationIcon(String occupationName) {
    final icons = {
      'Developer': '💻', 'Designer': '🎨', 'Doctor': '⚕️',
      'Student': '📚', 'Entrepreneur': '🚀', 'Unemployed': '⏳', 'Other': '🤝',
      'Teacher': '👨‍🏫', 'Engineer': '⚙️', 'Artist': '🎭', 'Freelancer': '🏠'
    };
    return icons[occupationName] ?? '👤';
  }

  Widget _buildBadgeChip(String label) {
    Color color;
    IconData icon;
    
    if (label == "Ultimate Bro") {
      color = Colors.amber.shade700;
      icon = Icons.stars_rounded;
    } else if (label == "Active Bro") {
      color = Colors.blue.shade700;
      icon = Icons.local_fire_department_rounded;
    } else {
      color = Colors.grey.shade600;
      icon = Icons.timer_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _FollowingListPreview extends ConsumerWidget {
  const _FollowingListPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 100,
        child: ref.watch(followingListProvider).when(
          loading: () => const BroLoadingIndicator(size: 20),
          error: (err, stack) => const SizedBox.shrink(),
          data: (following) {
            if (following.isEmpty) {
              return const Center(
                child: Text(
                  "You're not following any brothers yet.", 
                  style: TextStyle(color: Colors.grey, fontSize: 13)
                )
              );
            }
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: following.length,
              itemBuilder: (context, index) {
                final item = following[index];
                final followedProfile = item['profile'] as Profile;
                final latestMood = item['latest_mood'] as DailyMood?;
                
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 15),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: followedProfile.avatarUrl != null 
                              ? NetworkImage(followedProfile.avatarUrl!) 
                              : null,
                            child: followedProfile.avatarUrl == null 
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
                      const SizedBox(height: 6),
                      Text(
                        followedProfile.fullName?.split(' ')[0] ?? "Bro",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MoodHistoryPreview extends ConsumerWidget {
  const _MoodHistoryPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 140,
        child: ref.watch(myMoodHistoryProvider).when(
          loading: () => const BroLoadingIndicator(size: 30),
          error: (err, stack) => const SizedBox.shrink(),
          data: (history) {
            if (history.isEmpty) {
              return const Center(
                child: Text(
                  "No mood logs yet, bro. Keep pushing!", 
                  style: TextStyle(color: Colors.grey, fontSize: 13)
                )
              );
            }
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: history.length,
              itemBuilder: (context, index) => MoodHistoryCard(mood: history[index]),
            );
          },
        ),
      ),
    );
  }
}

class _MyPostsList extends ConsumerWidget {
  const _MyPostsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagingController = ref.watch(profilePagingControllerProvider);

    return PagedSliverList<int, Post>(
      pagingController: pagingController,
      builderDelegate: PagedChildBuilderDelegate<Post>(
        itemBuilder: (context, post, index) => PostCard(
          post: post,
          onLike: () async {
            final newIsLiked = !post.isLiked;
            final newLikesCount = (newIsLiked ? post.likesCount + 1 : post.likesCount - 1).clamp(0, 999999);
            
            final updatedPost = post.copyWith(
              isLiked: newIsLiked,
              likesCount: newLikesCount,
            );

            final items = List<Post>.from(pagingController.itemList ?? []);
            if (index < items.length) {
              items[index] = updatedPost;
              pagingController.itemList = items;
            }

            try {
              await ref.read(postRepositoryProvider).toggleLike(post.id, post.isLiked);
            } catch (error) {
              final rollbackItems = List<Post>.from(pagingController.itemList ?? []);
              if (index < rollbackItems.length) {
                rollbackItems[index] = post;
                pagingController.itemList = rollbackItems;
              }
              ToastService.showError("Failed to update like");
            }
          },
          onComment: () {
            final updatedPost = post.copyWith(
              commentsCount: post.commentsCount + 1,
            );
            final items = List<Post>.from(pagingController.itemList ?? []);
            if (index < items.length) {
              items[index] = updatedPost;
              pagingController.itemList = items;
            }
          },
        ),
        firstPageProgressIndicatorBuilder: (_) => const BroLoadingIndicator(),
        newPageProgressIndicatorBuilder: (_) => const Padding(
          padding: EdgeInsets.all(16.0),
          child: BroLoadingIndicator(size: 30),
        ),
        noItemsFoundIndicatorBuilder: (_) => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text("You haven't posted anything yet, bro."),
          ),
        ),
      ),
    );
  }
}

class _ShowAllButton extends StatelessWidget {
  const _ShowAllButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const FollowingListPopup(),
        );
      },
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Show All",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Icon(Icons.chevron_right, size: 16, color: Colors.blue),
        ],
      ),
    );
  }
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
