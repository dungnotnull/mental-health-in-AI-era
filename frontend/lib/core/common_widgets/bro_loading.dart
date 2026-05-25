import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class BroLoading extends StatelessWidget {
  const BroLoading({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network(
            'https://assets9.lottiefiles.com/packages/lf20_p8bfn5to.json',
            width: 150,
          ),
          const Text(
            "Đợi xíu bro nhé...",
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
