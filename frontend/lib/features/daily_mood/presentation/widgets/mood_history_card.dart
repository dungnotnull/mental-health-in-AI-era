import 'package:flutter/material.dart';
import '../../domain/mood.dart';

class MoodHistoryCard extends StatelessWidget {
  final DailyMood mood;
  const MoodHistoryCard({super.key, required this.mood});

  @override
  Widget build(BuildContext context) {
    final color = _getMoodColor(mood.moodScore);
    
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getMoodIcon(mood.moodScore), color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            _getMoodLabel(mood.moodScore),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(mood.createdAt),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(int score) {
    if (score == 1) return const Color(0xFFE91E63);
    if (score == 2) return const Color(0xFFFF9800);
    return const Color(0xFF4CAF50);
  }

  IconData _getMoodIcon(int score) {
    if (score == 1) return Icons.sentiment_very_dissatisfied_rounded;
    if (score == 2) return Icons.sentiment_neutral_rounded;
    return Icons.sentiment_satisfied_rounded;
  }

  String _getMoodLabel(int score) {
    if (score == 1) return "Stressed";
    if (score == 2) return "Not Okay";
    return "Still Okay";
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Today";
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return "Today";
    if (diff.inDays == 1) return "Yesterday";
    return "${date.day}/${date.month}";
  }
}
