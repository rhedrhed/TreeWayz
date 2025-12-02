import 'package:flutter/material.dart';
import '../widgetsuwu/bottom_nav.dart';
import '../servicesuwu/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screensuwu/signin_screen.dart';
import '../themeuwu/app_text.dart';
import '../themeuwu/app_colors.dart';
import '../screensuwu/profile_screen.dart'; // added import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Map<String, dynamic>? userData;
  String ongoingStatus = "uwu";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadActiveRide();
  }

  Future<void> _loadUserInfo() async {
    final res = await Api.get("/user/me");
    if (mounted) setState(() => userData = res);
  }

  Future<void> _loadActiveRide() async {
    final res = await Api.get("/rides/active");

    if (res == null || res["active"] == false) {
      if (mounted) setState(() => ongoingStatus = "No active rides.");
      return;
    }

    if (mounted) setState(() => ongoingStatus = res["status"]);
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SigninScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // When the user presses the Android back button, navigate to ProfileScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        return false; // prevent default pop
      },
      child: Scaffold(
        backgroundColor: Colors.white,

        // replace the internal _buildBottomNav() with your interactive widget
        bottomNavigationBar: const BottomNav(index: 0),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // LOGO + APP NAME
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

                // NAME CARD
                _buildNameCard(),

                const SizedBox(height: 30),

                // ONGOING SECTION
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Ongoing:",
                    style: AppText.subheading
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ongoingStatus,
                     style: AppText.text
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameCard() {
    final first = userData?["firstName"] ?? "uwu";
    final last = userData?["lastName"] ?? "uwu";
    final riderRating = userData?["riderRating"];
    final driverRating = userData?["driverRating"];
    final phone = userData?["phone"] ?? "uwu";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // GREEN HEADER
          Container(
            width: double.infinity,
             padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
            decoration: const BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Center(
              child: Column(
                children: [
                  Text(
                    "H E L L O",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "my name is",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // BODY CONTENT
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.lightGrey, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full name
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(first,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(last,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),

                const SizedBox(height: 10),

                // Rider Rating
                Text("Rider Rating: ${_stars(riderRating is int ? riderRating : null)}"),

                // Driver Rating
                Text("Driver Rating: ${_stars(driverRating is int ? driverRating : null)}"),

                const SizedBox(height: 10),

                // Contact number
                Text("Contact No: +$phone"),
              ],
            ),
          ),

          // PLAIN GREEN FOOTER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  String _stars(int? count) {
    if (count == null) return "☆☆☆☆☆";
    return "★" * count + "☆" * (5 - count);
  }
}
