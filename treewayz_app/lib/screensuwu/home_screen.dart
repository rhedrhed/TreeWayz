import 'package:flutter/material.dart';
import '../widgetsuwu/bottom_nav.dart';
import '../servicesuwu/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screensuwu/signin_screen.dart';
import '../themeuwu/app_text.dart';
import '../themeuwu/app_colors.dart';
import '../screensuwu/logout_screen.dart'; // added import
import '../screensuwu/driver_ride_management_screen.dart';
import '../screensuwu/ratedriver_screen.dart';
import '../screensuwu/welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? userData;
  String ongoingStatus = "Loading...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserInfo();
    _loadActiveRide();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload data when app comes back to foreground
      _loadUserInfo();
      _loadActiveRide();
    }
  }

  Future<void> _loadUserInfo() async {
    final res = await Api.get("/home");

    // Check for token expiration and redirect to login screen
    if (res != null && res["tokenExpired"] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res["message"] ?? "Session expired. Please log in again.",
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
      return;
    }

    if (res != null && res["success"] == true) {
      if (mounted) {
        setState(() {
          userData = res["user"];
        });
      }
    }
  }

  Future<void> _loadActiveRide() async {
    final res = await Api.get("/home");

    if (res == null) {
      if (mounted) {
        setState(() => ongoingStatus = "No active rides.");
      }
      return;
    }

    // Check for token expiration
    if (res["tokenExpired"] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res["message"] ?? "Session expired. Please log in again.",
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
      return;
    }

    // Check if rider needs to rate a completed ride
    if (res["needs_rating"] != null) {
      final rideData = res["needs_rating"];
      final rideId = rideData["ride_id"].toString(); // Convert to String
      final driverId = rideData["driver_id"].toString(); // Convert to String
      final driverFirstName = rideData["first_name"] ?? "";
      final driverLastName = rideData["last_name"] ?? "";
      final driverPhone = rideData["phone"] ?? "";

      // Navigate to rating screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RateDriverScreen(
              rideId: rideId,
              driverId: driverId,
              driverFirstName: driverFirstName,
              driverLastName: driverLastName,
              driverPhone: driverPhone,
            ),
          ),
        );
      }
      return;
    }

    if (res["ongoing_ride"] == null) {
      if (mounted) {
        setState(() => ongoingStatus = "No active rides.");
      }
      return;
    }

    final ride = res["ongoing_ride"];
    final status = ride["status"] ?? "unknown";
    final origin = ride["origin"] ?? "";
    final destination = ride["destination"] ?? "";
    final driverPhone = ride["driver_phone"] ?? "";
    final driverFirstName = ride["driver_first_name"] ?? "";
    final driverLastName = ride["driver_last_name"] ?? "";

    if (mounted) {
      setState(() {
        String statusText = "Status: $status\nFrom: $origin\nTo: $destination";

        // Add driver info for passengers (not for drivers viewing their own ride)
        if (driverPhone.isNotEmpty && driverFirstName.isNotEmpty) {
          statusText +=
              "\n\nDriver: $driverFirstName $driverLastName\nPhone: +$driverPhone";
        }

        ongoingStatus = statusText;
      });
    }
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

        // replace the internal _buildBottomNav() with your interactive widget
        bottomNavigationBar: const BottomNav(index: 0),

        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadUserInfo();
              await _loadActiveRide();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LOGO + APP NAME
                  Image.asset("elementsuwu/logo.png", height: 180),
                  Text("TreeWayz", style: AppText.heading),
                  Text("Thrifty, Thoughtful, Together", style: AppText.small),

                  const SizedBox(height: 20),

                  // NAME CARD
                  _buildNameCard(),

                  const SizedBox(height: 30),

                  // ONGOING SECTION
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Ongoing:", style: AppText.subheading),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(ongoingStatus, style: AppText.text),
                  ),

                  // Manage Ride Button (if there's an active ride)
                  if (ongoingStatus != "No active rides.") ...[
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const DriverRideManagementScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings, color: Colors.white),
                        label: const Text(
                          'MANAGE MY RIDE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameCard() {
    final first = userData?["first_name"] ?? "uwu"; // Changed from firstName
    final last = userData?["last_name"] ?? "uwu"; // Changed from lastName
    final riderRating = userData?["rider_rating"]; // Changed from riderRating
    final driverRating =
        userData?["driver_rating"]; // Changed from driverRating
    final phone =
        userData?["contact"] ?? "uwu"; // Changed from phone to contact

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
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
                    style: TextStyle(color: Colors.white, fontSize: 14),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      first,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      last,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Rider Rating: ${_formatRating(riderRating)}",
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  "Driver Rating: ${_formatRating(driverRating)}",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10),
                Text("Contact No: +$phone"),
              ],
            ),
          ),

          // FOOTER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
            decoration: const BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRating(dynamic rating) {
    if (rating == null) return "No ratings yet";

    // Convert to double
    double ratingValue = 0.0;
    if (rating is int) {
      ratingValue = rating.toDouble();
    } else if (rating is double) {
      ratingValue = rating;
    } else if (rating is String) {
      ratingValue = double.tryParse(rating) ?? 0.0;
    }

    // Clamp between 0 and 5
    ratingValue = ratingValue.clamp(0.0, 5.0);

    // Get star count (rounded)
    int starCount = ratingValue.round();
    String stars = "★" * starCount + "☆" * (5 - starCount);

    // Format: "4.5 ★★★★☆"
    return "${ratingValue.toStringAsFixed(1)} $stars";
  }
}
