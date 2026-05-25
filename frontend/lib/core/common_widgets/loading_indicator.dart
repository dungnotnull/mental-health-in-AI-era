import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class BroLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const BroLoadingIndicator({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.inkDrop(
        color: color ?? Colors.black87,
        size: size,
      ),
    );
  }
}

// Shorthand for full screen loading
class FullScreenLoading extends StatelessWidget {
  const FullScreenLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.5),
      child: const BroLoadingIndicator(size: 50),
    );
  }
}
