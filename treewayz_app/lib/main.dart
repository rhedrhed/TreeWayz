import 'package:flutter/material.dart';
import 'screensuwu/welcome_screen.dart';

void main() {
  runApp(const TreeWayz());
}

class TreeWayz extends StatelessWidget {
  const TreeWayz({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "TreeWayz",
      theme: ThemeData(primarySwatch: Colors.green),
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}
