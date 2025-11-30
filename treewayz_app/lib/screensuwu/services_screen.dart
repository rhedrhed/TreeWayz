import 'package:flutter/material.dart';
import '../widgetsuwu/bottom_nav.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const BottomNav(index: 1),
      body: Center(
        child: Text(
          "Services",
          style: TextStyle(fontSize: 26, color: Colors.green[800]),
        ),
      ),
    );
  }
}
