import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:frontend/core/common_widgets/loading_indicator.dart';
import 'package:frontend/core/common_widgets/full_video_screen.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String assetPath;
  final double height;
  final bool autoPlay;
  final bool looping;
  final bool muteInitial;

  const VideoPlayerWidget({
    super.key,
    required this.assetPath,
    this.height = 200,
    this.autoPlay = true,
    this.looping = true,
    this.muteInitial = true,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showPlayIndicator = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      widget.assetPath,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
          if (widget.autoPlay) {
            _controller.play();
          }
          if (widget.looping) {
            _controller.setLooping(true);
          }
          _controller.setVolume(widget.muteInitial ? 0.0 : 1.0);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_initialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
      _showPlayIndicator = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showPlayIndicator = false);
    });
  }

  void _openFullScreen() {
    if (!_initialized) return;
    final position = _controller.value.position;
    _controller.pause();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullVideoScreen(
          assetPath: widget.assetPath,
          initialPosition: position,
        ),
      ),
    ).then((_) {
      if (widget.autoPlay) _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: BroLoadingIndicator(size: 30)),
      );
    }

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
          
          // Play/Pause Indicator Overlay
          if (_showPlayIndicator)
            Icon(
              _controller.value.isPlaying ? Icons.play_arrow : Icons.pause,
              color: Colors.white.withOpacity(0.7),
              size: 50,
            ),

          // Full Screen Button
          Positioned(
            right: 8,
            bottom: 8,
            child: GestureDetector(
              onTap: _openFullScreen,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
              ),
            ),
          ),

          // Mute status indicator if muted
          if (_controller.value.volume == 0)
            Positioned(
              left: 8,
              bottom: 8,
              child: const Icon(Icons.volume_off, color: Colors.white54, size: 16),
            ),
        ],
      ),
    );
  }
}
