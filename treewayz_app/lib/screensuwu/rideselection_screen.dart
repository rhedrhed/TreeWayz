import 'package:flutter/material.dart';
import '../servicesuwu/api.dart';
import '../themeuwu/app_text.dart';
import '../themeuwu/app_colors.dart';
import '../screensuwu/logout_screen.dart';
import '../screensuwu/home_screen.dart';

class RideSelectionScreen extends StatefulWidget {
  final String pickupPoint;
  final String destination;
  final String seats;
  final String? paymentMethod;

  const RideSelectionScreen({
    super.key,
    required this.pickupPoint,
    required this.destination,
    required this.seats,
    this.paymentMethod,
  });

  @override
  State<RideSelectionScreen> createState() => _RideSelectionScreenState();
}

class _RideSelectionScreenState extends State<RideSelectionScreen> {
  List<Map<String, dynamic>> availableRides = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailableRides();
  }

  Future<void> _loadAvailableRides() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Build query string
      String queryString =
          '?pickup_point=${widget.pickupPoint}&destination_point=${widget.destination}&seats_needed=${widget.seats}';
      if (widget.paymentMethod != null) {
        queryString += '&payment_method=${widget.paymentMethod!.toLowerCase()}';
      }

      final response = await Api.get('/rides/searchRides$queryString');

      print('Search response: $response');

      if (response != null && response["success"] == true) {
        final rides = response["rides"] as List<dynamic>?;
        if (mounted) {
          setState(() {
            availableRides =
                rides?.map((ride) => ride as Map<String, dynamic>).toList() ??
                [];
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = response?["message"] ?? 'Failed to load rides';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading rides: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Error: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _bookRide(Map<String, dynamic> ride) async {
    final rideId = ride["ride_id"];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await Api.post('/rides/requestRide', {
        "ride_id": rideId,
        "seats": int.parse(widget.seats),
      });

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (response != null && response["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride request sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to home
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response?["message"] ?? 'Failed to book ride'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
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
                    : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(errorMessage!, style: AppText.text),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadAvailableRides,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : availableRides.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No available rides at the moment",
                              style: AppText.text,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAvailableRides,
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
    final driverName =
        "${ride["first_name"] ?? "Driver"} ${ride["last_name"] ?? ""}";
    final pickupPoint = ride["origin"] ?? "Unknown";
    final destination = ride["destination"] ?? "Unknown";
    final departureTime = ride["departure_time"] ?? "TBD";
    final availableSeats = ride["available_seats"] ?? 0;
    final pricePerSeat = ride["price"] ?? "0";
    final paymentMethod = ride["payment_method"] ?? "cash";
    final phone = ride["phone"] ?? "";

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
          onTap: () => _showRideDetailsDialog(ride),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: AppColors.darkGreen,
                          size: 20,
                        ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$pricePerSeat BD/seat',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 20),

                // Route
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.primaryGreen,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pickupPoint,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.flag,
                                color: AppColors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  destination,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Driver Phone Number
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        color: AppColors.darkGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+$phone',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],

                const Divider(height: 20),

                // Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.event_seat,
                          color: AppColors.darkGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "$availableSeats seats",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.darkGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          departureTime.substring(
                            0,
                            departureTime.length > 16
                                ? 16
                                : departureTime.length,
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        paymentMethod,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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

  void _showRideDetailsDialog(Map<String, dynamic> ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ride Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Driver: ${ride['first_name']} ${ride['last_name']}"),
            Text("Phone: ${ride['phone']}"),
            const Divider(),
            Text("From: ${ride['origin']}"),
            Text("To: ${ride['destination']}"),
            Text("Time: ${ride['departure_time']}"),
            Text("Available Seats: ${ride['available_seats']}"),
            Text("Price: ${ride['price']} BD per seat"),
            Text("Payment: ${ride['payment_method']}"),
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
              _bookRide(ride);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: const Text(
              "Book Ride",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
