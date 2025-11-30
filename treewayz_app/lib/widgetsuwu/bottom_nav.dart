import 'package:flutter/material.dart';
import '../screensuwu/home_screen.dart';
import '../screensuwu/services_screen.dart';
import '../screensuwu/receipts_screen.dart';
import '../screensuwu/profile_screen.dart';
import '../themeuwu/app_colors.dart';

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

    void _navigateTo(int i) {
      if (i == index) return;
      if (i < 0 || i >= pages.length) return;

      final target = pages[i];
      final beginOffset = i > index ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => target,
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween<Offset>(begin: beginOffset, end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      );
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: index,
      backgroundColor: AppColors.lightGrey, 
      selectedItemColor: AppColors.darkGreen,
      unselectedItemColor: AppColors.darkGrey,
      onTap: _navigateTo,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.miscellaneous_services),
          label: "Services",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt),
          label: "Receipts",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Profile",
        ),
      ],
    );
  }
}
