import 'package:flutter/material.dart';
import '../widgetsuwu/bottom_nav.dart';
import '../themeuwu/app_text.dart';
import '../themeuwu/app_colors.dart';
import '../screensuwu/home_screen.dart';

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

  // Define location sets for pickup and destination logic
  // Set A: Locations that can be picked up from and can go to both A and B as destination
  static const List<String> setA = ['AUBH', 'KU', 'Polytehcnic'];
  // Set B: Locations that can be picked up from but can only go to B as destination
  static const List<String> setB = ['Juffair', 'Busaiteen', 'Aali'];

  // Pickup options: if destination is setB, only setA; else both
  List<String> get pickupOptions => (destination != null && setB.contains(destination)) ? setA : setA + setB;

  // Destination options: if pickup is setB, only setA; else if pickup is setA, both; else empty
  List<String> get destinationOptions {
    if (pickupPoint == null) return [];
    if (setB.contains(pickupPoint)) {
      return setA; // Only setA
    } else {
      return setA + setB; // Both
    }
  }

  final List<String> seatsOptions = List.generate(8, (i) => (i + 1).toString());
  final List<String> paymentOptions = ['Cash', 'Benefit'];

  bool get isFormValid =>
      pickupPoint != null &&
      destination != null &&
      seats != null &&
      paymentMethod != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: const BottomNav(index: 1),
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
                    // Reset destination if it's no longer valid
                    if (destination != null && !destinationOptions.contains(destination)) {
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
                    // Reset pickup if it's no longer valid
                    if (pickupPoint != null && !pickupOptions.contains(pickupPoint)) {
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
                  labelText: 'Method of Payment',
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
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isFormValid ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                } : null,
                child: const Text("Request Ride", style: AppText.button),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
