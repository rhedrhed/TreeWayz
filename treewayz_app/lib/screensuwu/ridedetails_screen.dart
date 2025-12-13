import 'package:flutter/material.dart';
import '../themeuwu/app_text.dart';
import '../themeuwu/app_colors.dart';
import '../screensuwu/logout_screen.dart';
import '../screensuwu/rideselection_screen.dart';

class RideDetailsScreen extends StatefulWidget {
  const RideDetailsScreen({super.key});

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  String? pickupPoint;
  String? destination;
  String? seats;
  String? paymentMethod;

  static const List<String> setA = ['AUBH', 'KU', 'Polytechnic'];
  static const List<String> setB = ['Juffair', 'Busaiteen', 'Aali'];

  List<String> get pickupOptions =>
      (destination != null && setB.contains(destination)) ? setA : setA + setB;

  List<String> get destinationOptions {
    if (pickupPoint == null) return [];
    List<String> options;
    if (setB.contains(pickupPoint)) {
      options = setA;
    } else {
      options = setA + setB;
    }
    return options.where((location) => location != pickupPoint).toList();
  }

  final List<String> seatsOptions = List.generate(8, (i) => (i + 1).toString());
  final List<String> paymentOptions = ['Cash', 'Benefit'];

  bool get isFormValid =>
      pickupPoint != null && destination != null && seats != null;

  void _searchRides() {
    if (!isFormValid) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideSelectionScreen(
          pickupPoint: pickupPoint!,
          destination: destination!,
          seats: seats!,
          paymentMethod: paymentMethod,
        ),
      ),
    );
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
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Image.asset("elementsuwu/logo.png", height: 180),
                Text("TreeWayz", style: AppText.heading),
                Text("Thrifty, Thoughtful, Together", style: AppText.small),
                const SizedBox(height: 20),
                Text("Enter ride details", style: AppText.subheading),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: pickupPoint,
                  decoration: const InputDecoration(
                    labelText: 'Pickup Point',
                    border: OutlineInputBorder(),
                  ),
                  items: pickupOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      pickupPoint = newValue;
                      if (destination != null &&
                          (destination == pickupPoint ||
                              !destinationOptions.contains(destination))) {
                        destination = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: destination,
                  decoration: const InputDecoration(
                    labelText: 'Select Destination',
                    border: OutlineInputBorder(),
                  ),
                  items: destinationOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      destination = newValue;
                      if (pickupPoint != null &&
                          !pickupOptions.contains(pickupPoint)) {
                        pickupPoint = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: seats,
                  decoration: const InputDecoration(
                    labelText: 'Needed No. of Seats',
                    border: OutlineInputBorder(),
                  ),
                  items: seatsOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      seats = newValue;
                    });
                  },
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Method of Payment (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: paymentOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      paymentMethod = newValue;
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    fixedSize: const Size(350, 50),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isFormValid ? _searchRides : null,
                  child: const Text("Search Rides", style: AppText.button),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
