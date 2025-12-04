import 'package:flutter/material.dart';
import '../screensuwu/signin_screen.dart';
import '../themeuwu/app_text.dart';
import '../themeuwu/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("elementsuwu/logo.png", height: 180),
            Text(
              "TreeWayz",
              style: AppText.heading
            ),
            Text(
              "Thrifty, Thoughtful, Together",
              style: AppText.small
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                fixedSize: const Size(350, 50),
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SigninScreen()));
              },
              child: const 
              Text(
              "Get Started",
              style: AppText.button
              ),
            )
          ],
        ),
      ),
    )
    );
  }
}
