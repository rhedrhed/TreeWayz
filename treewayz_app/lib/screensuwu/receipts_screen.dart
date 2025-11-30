import 'package:flutter/material.dart';
import '../widgetsuwu/bottom_nav.dart';

class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNav(index: 2),
      body: Center(
        child: Text("Receipts",
            style: TextStyle(fontSize: 26, color: Colors.green[800])),
      ),
    );
  }
}
