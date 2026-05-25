class DailyMood {
  final String? id;
  final int moodScore;
  final String feelingText;
  final String? aiSuperPower;
  final String? moneyTip;
  final DateTime? createdAt;

  DailyMood({
    this.id,
    required this.moodScore,
    required this.feelingText,
    this.aiSuperPower,
    this.moneyTip,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'mood_score': moodScore,
    'feeling_text': feelingText,
    'ai_super_power': aiSuperPower,
    'money_tip': moneyTip,
  };

  factory DailyMood.fromJson(Map<String, dynamic> json) => DailyMood(
    id: json['id']?.toString(),
    moodScore: json['mood_score'],
    feelingText: json['feeling_text'] ?? '',
    aiSuperPower: json['ai_super_power'],
    moneyTip: json['money_tip'],
    createdAt: DateTime.parse(json['created_at']).toLocal(),
  );
}
