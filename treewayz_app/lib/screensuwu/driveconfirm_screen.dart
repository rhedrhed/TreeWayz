import 'package:flutter/material.dart';
import '../servicesuwu/api.dart';
import '../themeuwu/app_text.dart';
import '../themeuwu/app_colors.dart';
import '../screensuwu/driver_ride_management_screen.dart';
import 'drivedetails_screen.dart';

class DriveConfirmScreen extends StatefulWidget {
  final String pickupPoint;
  final String destination;
  final String hour;
  final String minute;
  final String amPm;
  final String seats;
  final String paymentMethod;

  const DriveConfirmScreen({
    super.key,
    required this.pickupPoint,
    required this.destination,
    required this.hour,
    required this.minute,
    required this.amPm,
    required this.seats,
    required this.paymentMethod,
  });

  @override
  State<DriveConfirmScreen> createState() => _DriveConfirmScreenState();
}

class _DriveConfirmScreenState extends State<DriveConfirmScreen> {
  bool _isSubmitting = false;

  Future<void> _confirmRide() async {
    setState(() => _isSubmitting = true);

    try {
      final response = await Api.post('/rides/postRide', {
        "pickup_point": widget.pickupPoint,
        "destination_point": widget.destination,
        "hour": widget.hour,
        "minute": widget.minute,
        "ampm": widget.amPm,
        "available_seats": int.parse(widget.seats),
        "payment_method": widget.paymentMethod,
        // Fare is calculated automatically by backend based on distance
      });

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (response != null && response["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride posted successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to driver ride management screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const DriverRideManagementScreen(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response?["message"] ?? 'Failed to post ride'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
            MaterialPageRoute(builder: (context) => const DriveDetailsScreen()),
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
                Text("Confirm Ride Details", style: AppText.subheading),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pickup Point: ${widget.pickupPoint}",
                        style: AppText.text,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Destination: ${widget.destination}",
                        style: AppText.text,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Time: ${widget.hour}:${widget.minute} ${widget.amPm}",
                        style: AppText.text,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Available Seats: ${widget.seats}",
                        style: AppText.text,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        fixedSize: const Size(150, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DriveDetailsScreen(
                                    initialPickupPoint: widget.pickupPoint,
                                    initialDestination: widget.destination,
                                    initialHour: widget.hour,
                                    initialMinute: widget.minute,
                                    initialAmPm: widget.amPm,
                                    initialSeats: widget.seats,
                                  ),
                                ),
                              );
                            },
                      child: const Text(
                        "Edit Details",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        fixedSize: const Size(150, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _confirmRide,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Confirm Ride", style: AppText.button),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
