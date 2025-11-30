import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../servicesuwu/api.dart';
import '../screensuwu/home_screen.dart';
import '../screensuwu/signin_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {

  @override
  void initState() {
    super.initState();
    _validateUser();
  }

  Future<void> _validateUser() async {
    await Future.delayed(const Duration(milliseconds: 800)); // for UI smoothness

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _goToSignin();
      return;
    }

    final res = await Api.get("/auth/validate"); 

    if (res != null && res["valid"] == true) {
      _goToHome();
    } else {
      _goToSignin();
    }
  }

  void _goToSignin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SigninScreen()),
    );
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image(
              image: AssetImage("assets/logo.png"),
              height: 180,
            ),
            SizedBox(height: 20),
            Text(
              "TreeWayz",
              style: TextStyle(
                fontSize: 26,
                color: Color(0xFF1D6B3C),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Reaping what you sowed ...",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            )
          ],
        ),
      ),
    );
  }
}
