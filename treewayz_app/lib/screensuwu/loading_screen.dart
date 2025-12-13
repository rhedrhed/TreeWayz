import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../servicesuwu/api.dart';
import '../screensuwu/home_screen.dart';
import '../screensuwu/signin_screen.dart';
import '../screensuwu/logout_screen.dart';

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
    await Future.delayed(const Duration(milliseconds: 800));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print('Token found: ${token != null}');

    if (token == null) {
      _goToSignin();
      return;
    }

    // Try to load home data - if it works, token is valid
    final res = await Api.get("/home");

    print('Validation response: $res');

    if (res != null && res["success"] == true) {
      _goToHome();
    } else {
      // Token invalid or expired
      await prefs.remove('token');
      _goToSignin();
    }
  }

  void _goToSignin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SigninScreen()),
      );
    }
  }

  void _goToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LogoutScreen()),
          );
        }
      },
      child: const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(image: AssetImage("elementsuwu/logo.png"), height: 180),
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
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Color(0xFF1D6B3C)),
            ],
          ),
        ),
      ),
    );
  }
}
