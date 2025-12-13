import 'package:flutter/material.dart';
import '../screensuwu/home_screen.dart';
import '../screensuwu/services_screen.dart';
import '../screensuwu/receipts_screen.dart';
import '../screensuwu/profile_screen.dart';
import '../themeuwu/app_colors.dart';
import '../servicesuwu/api.dart';

class BottomNav extends StatelessWidget {
  final int index;
  const BottomNav({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeScreen(),
      const ServicesScreen(),
      const ReceiptsScreen(),
      const ProfileScreen(),
    ];

    Future<void> _navigateTo(int i) async {
      if (i == index) return;
      if (i < 0 || i >= pages.length) return;

      // Check if trying to access Services tab (index 1)
      if (i == 1) {
        final res = await Api.get("/home");

        // Check if passenger has an accepted booking (needs to complete ride first)
        if (res != null && res["ongoing_ride"] != null) {
          final ride = res["ongoing_ride"];
          final status = ride["status"];

          // If passenger has accepted booking, block services access
          if (status == "accepted") {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Ride in Progress"),
                  content: const Text(
                    "You have an active ride! Please complete your ride and rate your driver before accessing services.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            }
            return; // Block navigation
          }
        }

        // Check if passenger needs to rate a completed ride
        if (res != null && res["needs_rating"] != null) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Rate Your Driver"),
                content: const Text(
                  "Please rate your previous driver before accessing services. Go to Home to rate.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
          return; // Block navigation
        }
      }

      final target = pages[i];
      final beginOffset = i > index
          ? const Offset(1.0, 0.0)
          : const Offset(-1.0, 0.0);

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => target,
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final tween = Tween<Offset>(
                    begin: beginOffset,
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeInOut));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
          ),
        );
      }
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: index,
      backgroundColor: AppColors.lightGrey,
      selectedItemColor: AppColors.darkGreen,
      unselectedItemColor: AppColors.darkGrey,
      onTap: _navigateTo,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(
          icon: Icon(Icons.miscellaneous_services),
          label: "Services",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Receipts"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}
