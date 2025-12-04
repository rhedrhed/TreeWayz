import 'package:flutter/material.dart';
import '../servicesuwu/api.dart';
import '../themeuwu/app_text.dart';
import '../themeuwu/app_colors.dart';
import '../screensuwu/home_screen.dart';
import '../screensuwu/logout_screen.dart';

class RateRiderScreen extends StatefulWidget {
  const RateRiderScreen({super.key});

  @override
  State<RateRiderScreen> createState() => _RateRiderScreenState();
}

class _RateRiderScreenState extends State<RateRiderScreen> {
  Map<String, dynamic>? riderData;
  List<bool> starStates = [false, false, false, false, false];
  int rating = 0;

  @override
  void initState() {
    super.initState();
    _loadRiderInfo();
  }

  Future<void> _loadRiderInfo() async {
    final res = await Api.get("/rider/me");
    if (mounted) setState(() => riderData = res);
  }

  void _toggleStar(int index) {
    setState(() {
      starStates[index] = !starStates[index];
      rating = starStates.where((star) => star).length;
    });
  }

  Future<void> _submitRating() async {
    // Temporarily just navigate to HomeScreen
    // TODO: Implement API call to submit rating
    // await Api.post("/rider/rate", body: {"rating": rating});
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // Do nothing - user must submit rating to exit
        return;
      },
      child: Scaffold(
      backgroundColor: Colors.white,
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
                style: AppText.heading,
              ),
              Text(
                "Thrifty, Thoughtful, Together",
                style: AppText.small,
              ),
              const SizedBox(height: 20),

              // RIDER INFO CARD
              _buildRiderCard(),

              const SizedBox(height: 30),

              // RATING SECTION
              Text(
                "Rate the Rider:",
                style: AppText.subheading,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => _toggleStar(index),
                    child: Image.asset(
                      starStates[index] ? "elementsuwu/yes rate.png" : "elementsuwu/no rate.png",
                      width: 70,
                      height: 70,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Text("Current Rating: $rating / 5"),

              const SizedBox(height: 30),

              // SUBMIT BUTTON
              ElevatedButton(
                onPressed: rating > 0 ? _submitRating : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text(
                  "Submit Rating",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    )
    );
  }

  Widget _buildRiderCard() {
    final first = riderData?["firstName"] ?? "uwu";
    final last = riderData?["lastName"] ?? "uwu";
    final riderRating = riderData?["riderRating"];
    final phone = riderData?["phone"] ?? "uwu";

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
                    "MY NAME IS",
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
