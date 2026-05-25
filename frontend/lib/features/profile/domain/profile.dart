import 'package:frontend/features/daily_mood/domain/mood.dart';

class Profile {
  final String id;
  final String? username;
  final String? fullName;
  final String? bio;
  final String? avatarUrl;
  final bool isPremium;
  final DateTime? premiumUntil;
  final String? country;
  final String? occupation;

  Profile({
    required this.id,
    this.username,
    this.fullName,
    this.bio,
    this.avatarUrl,
    this.isPremium = false,
    this.premiumUntil,
    this.country,
    this.occupation,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'],
    username: json['username'],
    fullName: json['full_name'],
    bio: json['bio'],
    avatarUrl: json['avatar_url'],
    isPremium: json['is_premium'] ?? false,
    premiumUntil: json['premium_until'] != null
        ? DateTime.parse(json['premium_until'])
        : null,
    country: json['country'],
    occupation: json['occupation'],
  );

  List<String> getBadges(List<DailyMood> moodHistory) {
    final List<String> badges = [];
    
    // Ultimate Bro (Premium)
    if (isPremium) {
      badges.add("Ultimate Bro");
    }

    // Active/Busy Bro Logic
    if (_hasSevenDayStreak(moodHistory)) {
      badges.add("Active Bro");
    } else {
      badges.add("Busy Bro");
    }

    return badges;
  }

  bool _hasSevenDayStreak(List<DailyMood> history) {
    if (history.length < 7) return false;
    
    // Simple check: do we have 7 entries with different consecutive days?
    // Sort history by date descending
    final sorted = List<DailyMood>.from(history)
      ..sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

    int streak = 0;
    DateTime? lastDate;

    for (var mood in sorted) {
      if (mood.createdAt == null) continue;
      final date = DateTime(mood.createdAt!.year, mood.createdAt!.month, mood.createdAt!.day);
      
      if (lastDate == null) {
        streak = 1;
        lastDate = date;
      } else {
        final diff = lastDate.difference(date).inDays;
        if (diff == 1) {
          streak++;
          lastDate = date;
        } else if (diff > 1) {
          // Streak broken
          break;
        }
        // if diff == 0, it's the same day, continue
      }
      
      if (streak >= 7) return true;
    }
    
    return streak >= 7;
  }
}
