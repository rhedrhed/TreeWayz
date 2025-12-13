import 'package:flutter/material.dart';
import '../themeuwu/app_text.dart';
import '../themeuwu/app_colors.dart';
import '../screensuwu/logout_screen.dart';
import '../screensuwu/driveconfirm_screen.dart';

class DriveDetailsScreen extends StatefulWidget {
  final String? initialPickupPoint;
  final String? initialDestination;
  final String? initialHour;
  final String? initialMinute;
  final String? initialAmPm;
  final String? initialSeats;

  const DriveDetailsScreen({
    super.key,
    this.initialPickupPoint,
    this.initialDestination,
    this.initialHour,
    this.initialMinute,
    this.initialAmPm,
    this.initialSeats,
  });

  @override
  State<DriveDetailsScreen> createState() => _DriveDetailsScreenState();
}

class _DriveDetailsScreenState extends State<DriveDetailsScreen> {
  String? pickupPoint;
  String? destination;
  String? hour;
  String? minute;
  String? amPm;
  String? seats;
  String? paymentMethod; // Cash or Benefit

  // Define location sets for pickup and destination logic
  // Set A: Locations that can be picked up from and can go to both A and B as destination
  static const List<String> setA = ['AUBH', 'KU', 'Polytechnic'];
  // Set B: Locations that can be picked up from but can only go to B as destination
  static const List<String> setB = ['Juffair', 'Busaiteen', 'Aali'];

  // Pickup options: if destination is setB, only setA; else both
  List<String> get pickupOptions =>
      (destination != null && setB.contains(destination)) ? setA : setA + setB;

  // Destination options: if pickup is setB, only setA; else if pickup is setA, both; else empty
  // Also exclude the pickup point from destination options
  List<String> get destinationOptions {
    if (pickupPoint == null) return [];
    List<String> options;
    if (setB.contains(pickupPoint)) {
      options = setA; // Only setA
    } else {
      options = setA + setB; // Both
    }
    // Remove the pickup point from destination options
    return options.where((location) => location != pickupPoint).toList();
  }

  final List<String> hourOptions = List.generate(12, (i) => (i + 1).toString());
  final List<String> minuteOptions = List.generate(
    60,
    (i) => i.toString().padLeft(2, '0'),
  );
  final List<String> amPmOptions = ['AM', 'PM'];
  final List<String> seatsOptions = List.generate(8, (i) => (i + 1).toString());

  bool get isFormValid =>
      pickupPoint != null &&
      destination != null &&
      hour != null &&
      minute != null &&
      amPm != null &&
      seats != null &&
      paymentMethod != null; // Payment method is now required

  @override
  void initState() {
    super.initState();
    // Initialize form fields with provided initial values
    pickupPoint = widget.initialPickupPoint;
    destination = widget.initialDestination;
    hour = widget.initialHour;
    minute = widget.initialMinute;
    amPm = widget.initialAmPm;
    seats = widget.initialSeats;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        // If there's a previous page in the stack, go back normally
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          // No previous page (or came from auth), go to logout
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
                Text("Enter Drive details", style: AppText.subheading),
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
                      // Reset destination if it's the same as pickup or no longer valid
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
                    });
                  },
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: hour,
                        decoration: const InputDecoration(
                          labelText: 'Hour',
                          border: OutlineInputBorder(),
                        ),
                        items: hourOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            hour = newValue;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: minute,
                        decoration: const InputDecoration(
                          labelText: 'Minute',
                          border: OutlineInputBorder(),
                        ),
                        items: minuteOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            minute = newValue;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: amPm,
                        decoration: const InputDecoration(
                          labelText: 'AM/PM',
                          border: OutlineInputBorder(),
                        ),
                        items: amPmOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            amPm = newValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: seats,
                  decoration: const InputDecoration(
                    labelText: 'Available No. of Seats',
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
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'benefit', child: Text('Benefit')),
                  ],
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
                  onPressed: isFormValid
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DriveConfirmScreen(
                                pickupPoint: pickupPoint!,
                                destination: destination!,
                                hour: hour!,
                                minute: minute!,
                                amPm: amPm!,
                                seats: seats!,
                                paymentMethod: paymentMethod!,
                              ),
                            ),
                          );
                        }
                      : null,
                  child: const Text("Post Ride", style: AppText.button),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
