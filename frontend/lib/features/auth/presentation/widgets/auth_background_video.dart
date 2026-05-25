import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AuthBackgroundVideo extends StatefulWidget {
  final Widget child;

  const AuthBackgroundVideo({super.key, required this.child});

  @override
  State<AuthBackgroundVideo> createState() => _AuthBackgroundVideoState();
}

class _AuthBackgroundVideoState extends State<AuthBackgroundVideo> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/peace_bg_1.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        _controller.setLooping(true);
        _controller.setVolume(0.0);
        if (mounted) {
          _controller.play();
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Video (Full-bleed)
          if (_controller.value.isInitialized)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            Container(color: const Color(0xFFE0F2F1)),

          // Lightest dark overlay for a brighter feel
          Container(
            color: Colors.black.withOpacity(0.08),
          ),

          // Main form content
          SafeArea(child: widget.child),
        ],
      ),
    );
  }
}
