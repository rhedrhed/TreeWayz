import 'package:flutter/material.dart';
import '../servicesuwu/api.dart';
import '../themeuwu/app_text.dart';
import '../themeuwu/app_colors.dart';
import '../screensuwu/logout_screen.dart';

class RideSelectionScreen extends StatefulWidget {
  const RideSelectionScreen({super.key});

  @override
  State<RideSelectionScreen> createState() => _RideSelectionScreenState();
}

class _RideSelectionScreenState extends State<RideSelectionScreen> {
  List<Map<String, dynamic>> availableRides = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableRides();
  }

  Future<void> _loadAvailableRides() async {
    setState(() => isLoading = true);
    
    // TODO: Replace with actual API call when backend is integrated
    // final res = await Api.get("/rides/available");
    
    // Demo data with "uwu" for null fields
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
    
    final demoRides = [
      {
        "rideId": "1",
        "driverName": "uwu",
        "pickupPoint": "AUBH",
        "destination": "Juffair",
        "departureTime": "uwu",
        "availableSeats": 3,
        "paymentMethod": "Cash",
        "driverRating": 4,
      },
      {
        "rideId": "2",
        "driverName": "uwu",
        "pickupPoint": "KU",
        "destination": "Busaiteen",
        "departureTime": "uwu",
        "availableSeats": 2,
        "paymentMethod": "Benefit",
        "driverRating": 5,
      },
      {
        "rideId": "3",
        "driverName": "uwu",
        "pickupPoint": "Polytehcnic",
        "destination": "Aali",
        "departureTime": "uwu",
        "availableSeats": 1,
        "paymentMethod": "Cash",
        "driverRating": 3,
      },
    ];
    
    if (mounted) {
      setState(() {
        availableRides = demoRides;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        // If there's a previous page (ride details), go back to it
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          // No previous page, go to logout
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LogoutScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Image.asset("elementsuwu/logo.png", height: 120),
                    Text("TreeWayz", style: AppText.heading),
                    Text("Thrifty, Thoughtful, Together", style: AppText.small),
                    const SizedBox(height: 20),
                    Text("Available Rides", style: AppText.subheading),
                  ],
                ),
              ),
              
              // Rides List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : availableRides.isEmpty
                        ? Center(
                            child: Text(
                              "No available rides at the moment",
                              style: AppText.text,
                            ),
                          )
                        : Scrollbar(
                            thumbVisibility: true,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: availableRides.length,
                              itemBuilder: (context, index) {
                                return _buildRideCard(availableRides[index]);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    final driverName = ride["driverName"] ?? "uwu";
    final pickupPoint = ride["pickupPoint"] ?? "uwu";
    final destination = ride["destination"] ?? "uwu";
    final departureTime = ride["departureTime"] ?? "uwu";
    final availableSeats = ride["availableSeats"] ?? 0;
    final paymentMethod = ride["paymentMethod"] ?? "uwu";
    final driverRating = ride["driverRating"];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // TODO: Navigate to ride confirmation or details
            _showRideDetailsDialog(ride);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver info and rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: AppColors.darkGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          driverName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(_stars(driverRating is int ? driverRating : null)),
                        const SizedBox(width: 4),
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                      ],
                    ),
                  ],
                ),
                
                const Divider(height: 20),
                
                // Route information
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.primaryGreen, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pickupPoint,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.flag, color: AppColors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  destination,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: AppColors.darkGreen),
                            const SizedBox(width: 4),
                            Text(
                              departureTime,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                
                const Divider(height: 20),
                
                // Additional details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_seat, color: AppColors.darkGreen, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "$availableSeats seats available",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        paymentMethod,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
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

  String _stars(int? count) {
    if (count == null) return "☆☆☆☆☆";
    return "★" * count + "☆" * (5 - count);
  }

  void _showRideDetailsDialog(Map<String, dynamic> ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ride Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Driver: ${ride['driverName']}"),
            Text("From: ${ride['pickupPoint']}"),
            Text("To: ${ride['destination']}"),
            Text("Time: ${ride['departureTime']}"),
            Text("Seats: ${ride['availableSeats']}"),
            Text("Payment: ${ride['paymentMethod']}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement ride booking logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Booking feature coming soon!")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: const Text("Book Ride", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
