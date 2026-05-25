class MoodStat {
  final int moodScore;
  final int count;
  final DateTime date;

  MoodStat({required this.moodScore, required this.count, required this.date});

  factory MoodStat.fromJson(Map<String, dynamic> json) => MoodStat(
    moodScore: json['mood_score'] as int,
    count: int.parse(json['count'].toString()),
    date: DateTime.parse(json['stat_date'] ?? DateTime.now().toIso8601String()),
  );
}
