import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:frontend/core/common_widgets/toast_service.dart';
import 'package:frontend/core/network/supabase_client.dart';
import 'package:frontend/core/navigation/navigation_provider.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:frontend/features/daily_mood/data/mood_repository.dart';
import 'package:frontend/features/auth/application/auth_error_handler.dart';
import '../../stats/presentation/stats_provider.dart';
import '../../profile/presentation/profile_provider.dart';
import '../../newfeed/presentation/create_post_screen.dart';
import '../../newfeed/presentation/newfeed_provider.dart';
import '../domain/mood.dart';
import 'package:easy_debounce/easy_debounce.dart';

class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});

  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _selectedScore = 3;
  bool _isSubmitting = false;
  late VideoPlayerController _controller;

  final List<Map<String, dynamic>> _statusOptions = [
    {
      'score': 3, 
      'label': "I'm still okay", 
      'subtitle': "Feeling steady and balanced.",
      'color': const Color(0xFF4CAF50), 
      'icon': Icons.sentiment_satisfied_rounded
    },
    {
      'score': 2, 
      'label': "I'm not okay yet", 
      'subtitle': "Things are a bit rough right now.",
      'color': const Color(0xFF8C5E3C), 
      'icon': Icons.sentiment_neutral_rounded
    },
    {
      'score': 1, 
      'label': "Unemployed / Stressed", 
      'subtitle': "In a tough spot, looking for light.",
      'color': const Color(0xFFE91E63), 
      'icon': Icons.sentiment_very_dissatisfied_rounded
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/peace_bg_2.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.setVolume(0);
        _controller.play();
      });
    _loadLatestMood();
  }

  Future<void> _loadLatestMood() async {
    try {
      final repo = MoodRepository(ref.read(supabaseClientProvider));
      final latest = await repo.getLatestMood();
      if (latest != null && mounted) {
        setState(() {
          _selectedScore = latest.moodScore;
        });
      }
    } catch (e) {
      debugPrint("Error loading latest mood: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Video
          if (_controller.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
          // Light Refreshing Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "STATUS",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "How's life, bro?",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Are you doing okay today? I'm genuinely curious, so feel free to share! No AI in here, just us bros.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 48),
                  ..._statusOptions.map((option) => _buildPremiumCard(option)),
                  const SizedBox(height: 40),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(Map<String, dynamic> option) {
    final isSelected = _selectedScore == option['score'];
    final color = option['color'] as Color;

    return GestureDetector(
      onTap: () => setState(() => _selectedScore = option['score']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.85) : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected ? color.withOpacity(1.0) : Colors.white.withOpacity(0.4),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected 
            ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 25, spreadRadius: -5)]
            : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                option['icon'], 
                color: isSelected ? color : Colors.black38, 
                size: 32
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option['label'],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w700,
                      color: isSelected ? Colors.black : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option['subtitle'],
                    overflow: TextOverflow.visible, // Allow it to wrap if really needed, but Expanded keeps it constrained
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.black54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Stabilize layout by always reserving space for the icon
            SizedBox(
              width: 28,
              height: 28,
              child: isSelected 
                ? Icon(Icons.check_circle_rounded, color: color, size: 28)
                : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isSubmitting ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: _isSubmitting ? Colors.white.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3), 
              offset: const Offset(0, 10), 
              blurRadius: 20,
              spreadRadius: -2
            ),
          ],
        ),
        child: Center(
          child: _isSubmitting
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                )
              : const Text(
                  "UPDATE MY STATUS",
                  style: TextStyle(
                    color: Colors.black, 
                    fontSize: 16, 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
        ),
      ),
    );
  }

  void _submit() {
    EasyDebounce.debounce(
      'submit_mood',
      const Duration(milliseconds: 1000), // Protect against multiple rapid taps
      () async {
        if (!mounted || _isSubmitting) return;
        
        // Optimistically set loading
        setState(() => _isSubmitting = true);
        
        final repo = MoodRepository(ref.read(supabaseClientProvider));
        
        try {
          // Logic Guard: Check if same status already submitted today
          final latestToday = await repo.getLatestMood();
          if (latestToday != null && 
              latestToday.moodScore == _selectedScore && 
              latestToday.createdAt?.day == DateTime.now().day &&
              latestToday.createdAt?.month == DateTime.now().month &&
              latestToday.createdAt?.year == DateTime.now().year) {
            ToastService.showInfo("You already set this status today, bro! No need to spam.");
            if (mounted) setState(() => _isSubmitting = false);
            return;
          }

          final mood = DailyMood(moodScore: _selectedScore, feelingText: "");
          await repo.submitMood(mood);

          // Invalidate providers to refresh stats and profile history
          ref.invalidate(communityStatsProvider);
          ref.invalidate(myMoodHistoryProvider);
          // Also invalidate feed so it can see updated active badges
          ref.read(newfeedProvider.notifier).state++;

          ToastService.showSuccess("Status updated.");
          
          if (mounted) {
            _showSharePrompt();
          }
        } catch (e) {
          ToastService.showError(AuthErrorHandler.getErrorMessage(e));
        } finally {
          if (mounted) setState(() => _isSubmitting = false);
        }
      },
    );
  }

  void _showSharePrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 32),
            const Text(
              "Share the vibe?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedScore == 3 
                  ? "What's making you feel okay today?" 
                  : "Why are you not okay yet? What risks are you facing?",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            FutureBuilder<String>(
              future: _getRandomQuote(_selectedScore),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24)));
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    "\"${snapshot.data ?? 'Keep pushing, bro!'}\"",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14, 
                      color: Colors.white, 
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _finishFlow();
                    },
                    child: const Text("Maybe later", style: TextStyle(color: Colors.white38)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to create post directly
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreatePostScreen()),
                      ).then((_) {
                        // After coming back from CreatePostScreen (even if cancelled),
                        // we still want to go to Feed tab to see potential new post
                        _finishFlow();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Post to Feed", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ).then((_) {
      if (mounted && _isSubmitting) setState(() => _isSubmitting = false);
    });
  }

  void _finishFlow() {
    // Redirect to Feed tab after a small delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(navigationIndexProvider.notifier).state = 1;
      }
    });
  }

  Future<String> _getRandomQuote(int score) async {
    try {
      String fileName;
      if (score == 3) {
        fileName = 'assets/quotes/imStillFine.json';
      } else if (score == 2) {
        fileName = 'assets/quotes/imNotFine.json';
      } else {
        fileName = 'assets/quotes/imUnemployed.json';
      }

      final String response = await rootBundle.loadString(fileName);
      final data = await json.decode(response);
      final List<dynamic> quotes = data['quotes'];
      
      if (quotes.isEmpty) return "Keep the vibe, bro!";
      
      final random = Random();
      return quotes[random.nextInt(quotes.length)];
    } catch (e) {
      debugPrint("Error loading quotes: $e");
      return "Tough times never last, but tough people do.";
    }
  }
}
