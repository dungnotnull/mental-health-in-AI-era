import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class MoodResultScreen extends StatelessWidget {
  final String superPower;
  final String moneyTip;

  const MoodResultScreen({
    super.key,
    required this.superPower,
    required this.moneyTip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark mode cho ngầu
      body: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              'https://assets10.lottiefiles.com/packages/lf20_myejioos.json',
            ), // Animation siêu nhân
            const Text(
              "SIÊU NĂNG LỰC CỦA BRO:",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              superPower,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "BRO'S MONEY TIP:",
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              moneyTip,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text("Gét gô bro!"),
            ),
          ],
        ),
      ),
    );
  }
}
