import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:frontend/core/common_widgets/toast_service.dart';
import 'package:frontend/core/network/supabase_client.dart';
import '../../domain/post.dart';
import 'package:frontend/features/post_detail/data/comment_repository.dart';
import 'package:frontend/core/common_widgets/loading_indicator.dart';
import 'dart:async';
import 'package:frontend/features/newfeed/presentation/newfeed_provider.dart';
import '../edit_post_screen.dart';
import '../../data/post_repository.dart';
import 'package:frontend/features/auth/application/auth_error_handler.dart';
import 'package:frontend/features/profile/data/follow_repository.dart';

class PostCard extends ConsumerStatefulWidget {
  final Post post;
  final Function() onLike;
  final Function() onComment;

  const PostCard({super.key, required this.post, required this.onLike, required this.onComment});

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _showComments = false;
  bool _isSubmittingComment = false;
  final _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;
  StreamSubscription? _postSubscription;

  // We rely on widget.post for counts now to avoid duplication bugs
  // as the parent manages the PagingController state.
  late bool _localIsLiked;
  bool _isFollowing = false;
  bool _isTogglingFollow = false;
  bool _isProcessingLike = false;

  void _handleShare() {
    Share.share(
      'Bro xem bài này hay nè: "${widget.post.content}" \nXem thêm tại How r u bro?',
      subject: 'How r u bro?',
    );
    ToastService.showSuccess("Đã mở menu chia sẻ!");
  }

  Future<void> _toggleComments() async {
    setState(() {
      _showComments = !_showComments;
    });

    if (_showComments && _comments.isEmpty) {
      _fetchComments();
    }
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final repo = ref.read(commentRepositoryProvider);
      final comments = await repo.getComments(widget.post.id);
      setState(() => _comments = comments);
    } catch (e) {
      debugPrint("Error fetching comments: $e");
    } finally {
      setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmittingComment = true);
    try {
      final repo = ref.read(commentRepositoryProvider);
      await repo.createComment(widget.post.id, _commentController.text.trim());
      _commentController.clear();
      
      // Optimistic Update
      widget.onComment();
      
      _fetchComments();
      // ToastService.showSuccess("Commented, bro! 🤜🤛");
    } catch (e) {
      ToastService.showError("Failed to comment");
    } finally {
      setState(() => _isSubmittingComment = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _localIsLiked = widget.post.isLiked;
    _checkFollowStatus();
    _initRealtime();
  }

  Future<void> _checkFollowStatus() async {
    final myId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (myId == null || myId == widget.post.userId) return;

    final repo = ref.read(followRepositoryProvider);
    final isFollowing = await repo.isFollowing(widget.post.userId);
    if (mounted) {
      setState(() => _isFollowing = isFollowing);
    }
  }

  Future<void> _toggleFollow() async {
    if (_isTogglingFollow) return;
    setState(() => _isTogglingFollow = true);
    try {
      final repo = ref.read(followRepositoryProvider);
      if (_isFollowing) {
        await repo.unfollow(widget.post.userId);
        setState(() => _isFollowing = false);
        // ToastService.showSuccess("Unfollowed bro.");
      } else {
        await repo.follow(widget.post.userId);
        setState(() => _isFollowing = true);
        // ToastService.showSuccess("Following bro! 🤝");
      }
      // Invalidate following list to refresh Profile screen
      // Wait, we can't easily invalidate from here if we want instant update,
      // but the Profile list will refresh when user navigates back.
    } catch (e) {
      ToastService.showError("Failed to update follow status");
    } finally {
      if (mounted) setState(() => _isTogglingFollow = false);
    }
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.isLiked != widget.post.isLiked) {
      setState(() {
        _localIsLiked = widget.post.isLiked;
      });
    }
  }

  Future<void> _handleLike() async {
    // 1. Optimistic UI update instantly
    setState(() {
      _localIsLiked = !_localIsLiked;
      // Optionally update local like count here if we tracked it in state
    });

    // 2. Debounce the actual API call to prevent spamming
    EasyDebounce.debounce(
      'like_post_${widget.post.id}',
      const Duration(milliseconds: 500),
      () async {
        if (!mounted) return;
        setState(() => _isProcessingLike = true);
        try {
          await widget.onLike(); // Let the parent update the backend and state
        } finally {
          if (mounted) setState(() => _isProcessingLike = false);
        }
      },
    );
  }

  void _initRealtime() {
    _postSubscription = ref.read(postRepositoryProvider).watchPostChanges(widget.post.id).listen((_) {
      // Invalidate providers or trigger local refresh if necessary
      // For now, we rely on the stream to tell us something changed.
      // A more robust way would be to fetch the new counts.
      // But simpler for MVP: refresh specific providers that affect this card.
      // Actually, since the stream gives no data, we can just trigger a manual refresh of comments if open.
      if (_showComments) _fetchComments();
    });
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post?"),
        content: const Text("This will permanently remove your post and its media, bro."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("DELETE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        ToastService.showSuccess("Post deleted.");
        ref.read(newfeedProvider.notifier).state++;
      } catch (e) {
        ToastService.showError(AuthErrorHandler.getErrorMessage(e));
      }
    }
  }

  Future<void> _handleEdit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditPostScreen(post: widget.post)),
    );
    if (updated == true) {
      ref.read(newfeedProvider.notifier).state++;
    }
  }

  void _openGallery(int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _BroImageGallery(
              imageUrls: widget.post.imageUrls,
              initialIndex: initialIndex,
              heroPrefix: 'post_image_${widget.post.id}_',
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _postSubscription?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.12),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            leading: CircleAvatar(
              backgroundColor: Colors.grey[100],
              backgroundImage: widget.post.authorAvatar != null 
                ? CachedNetworkImageProvider(widget.post.authorAvatar!) 
                : null,
              child: widget.post.authorAvatar == null ? const Icon(Icons.person, color: Colors.grey) : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.post.authorName ?? "Bro User",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.post.authorCountry != null) ...[
                        const SizedBox(width: 6),
                        Text(_getCountryFlag(widget.post.authorCountry!), style: const TextStyle(fontSize: 14)),
                      ],
                    ],
                  ),
                ),
                if (widget.post.userId != ref.read(supabaseClientProvider).auth.currentUser?.id)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildFollowButton(),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        _formatDate(widget.post.createdAt),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      ...widget.post.authorBadges.map((badge) => _buildBadgeChip(badge)).toList(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (widget.post.authorOccupation != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_getOccupationIcon(widget.post.authorOccupation!), style: const TextStyle(fontSize: 10)),
                              const SizedBox(width: 4),
                              Text(
                                widget.post.authorOccupation!,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      if (widget.post.authorMoodScore != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.post.authorMoodScore!).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _getStatusColor(widget.post.authorMoodScore!).withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_getStatusIcon(widget.post.authorMoodScore!), style: const TextStyle(fontSize: 10)),
                              const SizedBox(width: 4),
                              Text(
                                _getStatusLabel(widget.post.authorMoodScore!),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _getStatusColor(widget.post.authorMoodScore!)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            trailing: widget.post.userId == ref.read(supabaseClientProvider).auth.currentUser?.id
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _handleEdit();
                      } else if (value == 'delete') {
                        _handleDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text("Edit Post")),
                      const PopupMenuItem(value: 'delete', child: Text("Delete Post", style: TextStyle(color: Colors.red))),
                    ],
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              widget.post.content, 
              style: const TextStyle(fontSize: 15, height: 1.4)
            ),
          ),
          if (widget.post.imageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                height: 240, // Slightly taller for better preview
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.post.imageUrls.length,
                  itemBuilder: (context, idx) {
                    final imageUrl = widget.post.imageUrls[idx];
                    return GestureDetector(
                      onTap: () => _openGallery(idx),
                      child: Container(
                        width: widget.post.imageUrls.length > 1 ? 280 : MediaQuery.of(context).size.width - 32,
                        margin: const EdgeInsets.only(right: 12),
                        child: Hero(
                          tag: 'post_image_${widget.post.id}_$idx',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[100],
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[100],
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          const Divider(height: 1),
          // Actions Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _buildActionButton(
                  icon: _localIsLiked ? Icons.favorite : Icons.favorite_border,
                  label: "${widget.post.likesCount}",
                  color: _localIsLiked ? Colors.red : Colors.grey[700],
                  onTap: _handleLike,
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: "${widget.post.commentsCount}",
                  color: _showComments ? Colors.blue : Colors.grey[700],
                  onTap: _toggleComments,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  color: Colors.grey[700],
                  onPressed: _handleShare,
                ),
              ],
            ),
          ),
          
          if (_showComments) ...[
            const Divider(height: 1),
            _buildCommentSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildFollowButton() {
    if (_isTogglingFollow) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
      );
    }

    return OutlinedButton(
      onPressed: _toggleFollow,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: _isFollowing ? Colors.grey[300]! : Colors.blue.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _isFollowing ? Colors.transparent : Colors.blue.withOpacity(0.05),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minimumSize: const Size(0, 28),
      ),
      child: Text(
        _isFollowing ? "Following" : "Follow",
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _isFollowing ? Colors.grey[600] : Colors.blue,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon, 
    required String label, 
    required Color? color, 
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Match card background
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Column(
        children: [
          if (_isLoadingComments)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: BroLoadingIndicator(size: 20),
            )
          else
            ..._comments.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: (c['profiles!comments_user_id_fkey'] ?? c['profiles'])?['avatar_url'] != null 
                      ? NetworkImage((c['profiles!comments_user_id_fkey'] ?? c['profiles'])['avatar_url']) 
                      : null,
                    child: (c['profiles!comments_user_id_fkey'] ?? c['profiles'])?['avatar_url'] == null ? const Icon(Icons.person, size: 14) : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5), // Subtle blue-grey for bubbles
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (c['profiles!comments_user_id_fkey'] ?? c['profiles'])?['full_name'] ?? "Bro",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(c['content'], style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
          
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: "Write a comment...",
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ),
              IconButton(
                icon: _isSubmittingComment 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send, color: Colors.blue),
                onPressed: _submitComment,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${date.day}/${date.month}";
  }

  String _getCountryFlag(String countryName) {
    final countries = {
      'Việt Nam': '🇻🇳', 'Singapore': '🇸🇬', 'United States': '🇺🇸',
      'Japan': '🇯🇵', 'South Korea': '🇰🇷', 'Thailand': '🇹🇭', 'Australia': '🇦🇺'
    };
    return countries[countryName] ?? '🌍';
  }

  String _getOccupationIcon(String occupationName) {
    final icons = {
      'Developer': '💻', 'Designer': '🎨', 'Doctor': '⚕️',
      'Student': '📚', 'Entrepreneur': '🚀', 'Unemployed': '⏳', 'Other': '🤝'
    };
    return icons[occupationName] ?? '👤';
  }

  Color _getStatusColor(int score) {
    if (score == 1) return const Color(0xFFE57373); // muted red
    if (score == 2) return const Color(0xFF8C5E3C); // subdued earthy bronze
    return const Color(0xFF66BB6A); // soft green
  }

  String _getStatusIcon(int score) {
    if (score == 1) return '🔴';
    if (score == 2) return '🟡';
    return '🟢';
  }

  String _getStatusLabel(int score) {
    if (score == 1) return 'unemployed';
    if (score == 2) return 'not okay yet';
    return 'still okay';
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
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _BroImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String heroPrefix;

  const _BroImageGallery({
    required this.imageUrls, 
    required this.initialIndex,
    required this.heroPrefix,
  });

  @override
  State<_BroImageGallery> createState() => _BroImageGalleryState();
}

class _BroImageGalleryState extends State<_BroImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Center(
                  child: Hero(
                    tag: '${widget.heroPrefix}$index', 
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrls[index],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white24),
                    ),
                  ),
                ),
              );
            },
          ),
          // Back button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Page Indicator
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index ? Colors.white : Colors.white38,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
