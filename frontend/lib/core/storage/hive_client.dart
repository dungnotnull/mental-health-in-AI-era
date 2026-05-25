import 'package:hive_flutter/hive_flutter.dart';

class HiveClient {
  static const String moodBoxName = 'mood_cache';
  static const String settingsBoxName = 'settings_cache';
  static const String postBoxName = 'posts_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(postBoxName);

    // Mở các box cần thiết để dùng toàn app
    await Hive.openBox(moodBoxName);
    await Hive.openBox(settingsBoxName);
  }

  // Helper để lưu mood offline
  static Future<void> cacheMood(Map<String, dynamic> moodData) async {
    var box = Hive.box(moodBoxName);
    await box.put('latest_mood', moodData);
  }

  // Helper lấy mood offline khi không có mạng
  static dynamic getCachedMood() {
    return Hive.box(moodBoxName).get('latest_mood');
  }

  static Future<void> cachePosts(List<dynamic> posts) async {
    var box = Hive.box(postBoxName);
    await box.put('latest_feed', posts);
  }

  static List<dynamic> getCachedPosts() {
    return Hive.box(postBoxName).get('latest_feed', defaultValue: []);
  }
}
