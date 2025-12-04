import 'package:flutter/material.dart';
import 'ridedetails_screen.dart';
import 'drivedetails_screen.dart';
import '../widgetsuwu/bottom_nav.dart';
import '../themeuwu/app_text.dart';
import '../themeuwu/app_colors.dart';
import '../screensuwu/logout_screen.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

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
      backgroundColor: Colors.white,
      bottomNavigationBar: const BottomNav(index: 1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Choose your service", style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                fixedSize: const Size(350, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RideDetailsScreen())); // change to riderscreen
              },
              child: const 
              Text(
              "Rider",
              style: AppText.button
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                fixedSize: const Size(350, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DriveDetailsScreen()));
              },
              child: const 
              Text(
              "Driver",
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
