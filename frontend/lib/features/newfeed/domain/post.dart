class Post {
  final int id;
  final String userId;
  final String content;
  final List<String> imageUrls;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final bool isLiked; // Trường ảo, fetch bằng query hoặc join
  final String? category;
  final String? authorName;
  final String? authorAvatar;
  final String? authorCountry;
  final String? authorOccupation;
  final int? authorMoodScore;
  final List<String> authorBadges;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    required this.imageUrls,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    this.isLiked = false,
    this.category,
    this.authorName,
    this.authorAvatar,
    this.authorCountry,
    this.authorOccupation,
    this.authorMoodScore,
    this.authorBadges = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final profile = json['profiles!posts_user_id_fkey'] ?? json['profiles'];
    return Post(
      id: json['id'],
      userId: json['user_id'],
      content: json['content'],
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      likesCount: (json['post_likes'] != null ? (json['post_likes'] as List).length : 0).clamp(0, 9999999),
      commentsCount: (json['comments'] != null ? (json['comments'] as List).length : 0).clamp(0, 9999999),
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      isLiked: json['post_likes'] != null && (json['post_likes'] as List).any((l) => l['user_id'] == currentUserId),
      category: json['category'],
      authorName: (profile != null) 
          ? (profile is List && profile.isNotEmpty ? profile[0]['full_name'] : profile['full_name']) 
          : 'Anonymous Bro',
      authorAvatar: (profile != null) 
          ? (profile is List && profile.isNotEmpty ? profile[0]['avatar_url'] : profile['avatar_url']) 
          : null,
      authorCountry: (profile != null) 
          ? (profile is List && profile.isNotEmpty ? profile[0]['country'] : profile['country']) 
          : null,
      authorOccupation: (profile != null) 
          ? (profile is List && profile.isNotEmpty ? profile[0]['occupation'] : profile['occupation']) 
          : null,
      authorMoodScore: (() {
        final profileData = (profile is List && profile.isNotEmpty) ? profile[0] : profile;
        if (profileData == null) return null;
        final moods = profileData['daily_moods'];
        if (moods == null) return null;
        final moodList = moods is List ? moods : [moods];
        if (moodList.isEmpty) return null;
        return moodList[0]['mood_score'] as int?;
      })(),
      authorBadges: (() {
        final profileData = (profile is List && profile.isNotEmpty) ? profile[0] : profile;
        if (profileData == null) return <String>[];
        
        final List<String> badges = [];
        if (profileData['is_premium'] == true) badges.add("Ultimate Bro");
        
        final moods = profileData['daily_moods'];
        if (moods is List && moods.length >= 7) {
          if (_hasSevenDayStreak(moods)) {
            badges.add("Active Bro");
          } else {
            badges.add("Busy Bro");
          }
        } else if (moods != null) {
          badges.add("Busy Bro");
        }
        return badges;
      })(),
    );
  }

  static bool _hasSevenDayStreak(List<dynamic> moodList) {
    if (moodList.isEmpty) return false;
    
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final recentDates = moodList
          .take(10) // Only check recent ones
          .map((m) {
            final date = DateTime.parse(m['created_at']);
            return DateTime(date.year, date.month, date.day);
          })
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      if (recentDates.isEmpty) return false;

      // Check if the most recent mood is today or yesterday
      final mostRecent = recentDates.first;
      if (today.difference(mostRecent).inDays > 1) return false;

      int streak = 1;
      for (int i = 0; i < recentDates.length - 1; i++) {
        if (recentDates[i].difference(recentDates[i+1]).inDays == 1) {
          streak++;
          if (streak >= 7) return true;
        } else {
          break;
        }
      }
      return streak >= 7;
    } catch (_) {
      return false;
    }
  }

  Post copyWith({
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
  }) {
    return Post(
      id: id,
      userId: userId,
      content: content,
      imageUrls: imageUrls,
      likesCount: (likesCount ?? this.likesCount).clamp(0, 9999999),
      commentsCount: (commentsCount ?? this.commentsCount).clamp(0, 9999999),
      createdAt: createdAt,
      isLiked: isLiked ?? this.isLiked,
      category: category,
      authorName: authorName,
      authorAvatar: authorAvatar,
      authorCountry: authorCountry,
      authorOccupation: authorOccupation,
      authorMoodScore: authorMoodScore,
      authorBadges: authorBadges,
    );
  }
}
