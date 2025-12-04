import 'package:flutter/material.dart';
import '../widgetsuwu/bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screensuwu/signin_screen.dart';
import 'logout_screen.dart';
import '../themeuwu/app_text.dart';
import '../themeuwu/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const SigninScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LogoutScreen()),
        );
      },
      child: Scaffold(
      bottomNavigationBar: const BottomNav(index: 3),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Profile", style: TextStyle(fontSize: 26)),
            const SizedBox(height: 20),
           ElevatedButton(
             style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                fixedSize: const Size(350, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LogoutScreen()));
              },
              child: const 
              Text(
              "Logout :<",
              style: AppText.button
              ),
            ),
          ],
        ),
      ),
    )
    );
  }
}
