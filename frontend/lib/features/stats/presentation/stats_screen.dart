import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/application/auth_error_handler.dart';
import 'package:frontend/core/common_widgets/loading_indicator.dart';
import '../domain/mood_stat.dart';
import 'stats_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(communityStatsProvider);
    final totalBrosAsync = ref.watch(totalBrosProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Clean modern background
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          "COMMUNITY STATS",
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 20, 
            letterSpacing: 1.5,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(communityStatsProvider);
              ref.invalidate(totalBrosProvider);
            },
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const BroLoadingIndicator(),
        error: (err, stack) => Center(child: Text(AuthErrorHandler.getErrorMessage(err))),
        data: (stats) {
          int total = 0;
          for (var s in stats) total += s.count;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(communityStatsProvider);
              ref.invalidate(totalBrosProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  totalBrosAsync.when(
                    data: (total) => _buildTotalCounter(total),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _buildTotalCounter(0),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "Real-time Mood Distribution",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ...stats.map((s) => _buildStatCard(s, total)),
                  const SizedBox(height: 40),
                  const Text(
                    "Stay strong, brothers. We are in this together.",
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black45),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalCounter(int total) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "TOTAL BROS LOGGED",
            style: TextStyle(
              color: Colors.black54,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "$total",
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(MoodStat stat, int total) {
    final double percentage = total > 0 ? (stat.count / total) : 0;
    final color = _getMoodColor(stat.moodScore);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getMoodLabel(stat.moodScore),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${stat.count} bros",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Modern Flat Progress Bar
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(int score) {
    if (score == 1) return const Color(0xFFE57373); // muted red
    if (score == 2) return const Color(0xFF8C5E3C); // subdued earthy bronze
    return const Color(0xFF81C784); // soft green
  }

  String _getMoodLabel(int score) {
    if (score == 1) return "Unemployed 🔴";
    if (score == 2) return "Not Okay yet 🟠";
    return "Still Okay 🟢";
  }
}

