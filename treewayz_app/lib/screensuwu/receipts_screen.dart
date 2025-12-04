import 'package:flutter/material.dart';
import '../widgetsuwu/bottom_nav.dart';
import '../screensuwu/raterider_screen.dart';
import '../screensuwu/logout_screen.dart';

class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key});

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
      bottomNavigationBar: const BottomNav(index: 2),
body: Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text("Receipts",
          style: TextStyle(fontSize: 26, color: Colors.green[800])),
      const SizedBox(height: 20),
      /*ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RateRiderScreen()),
        ),
        child: const Text('Rate Driver'),
      ), */
    ],
  ),
),
      
    )
    );
  }
}
