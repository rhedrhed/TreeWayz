import 'package:flutter/material.dart';
import '../servicesuwu/api.dart';
import '../themeuwu/app_text.dart';
import '../themeuwu/app_colors.dart';
import '../screensuwu/home_screen.dart';
import '../screensuwu/rate_riders_screen.dart';

class DriverRideManagementScreen extends StatefulWidget {
  const DriverRideManagementScreen({super.key});

  @override
  State<DriverRideManagementScreen> createState() =>
      _DriverRideManagementScreenState();
}

class _DriverRideManagementScreenState
    extends State<DriverRideManagementScreen> {
  bool loading = true;
  Map<String, dynamic>? rideData;
  List<dynamic> pendingRequests = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRideData();
  }

  Future<void> _loadRideData() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    final res = await Api.get('/rides/myRide');

    if (res != null && res["success"] == true) {
      setState(() {
        rideData = res["ride"];
        pendingRequests = res["requests"] ?? [];
        loading = false;
      });
    } else {
      setState(() {
        errorMessage = res?["message"] ?? "No active rides found.";
        loading = false;
      });
    }
  }

  Future<void> _acceptRequest(int bookingId) async {
    print('Accepting booking ID: $bookingId'); // Debug

    final res = await Api.patch('/rides/acceptRequest/$bookingId', {});

    print('Accept response: $res'); // Debug

    if (res != null && res["success"] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rider accepted!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRideData(); // Refresh data
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res?["message"] ?? 'Failed to accept request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(int bookingId) async {
    print('Rejecting booking ID: $bookingId'); // Debug

    final res = await Api.patch('/rides/rejectRequest/$bookingId', {});

    print('Reject response: $res'); // Debug

    if (res != null && res["success"] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rider rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadRideData(); // Refresh data
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res?["message"] ?? 'Failed to reject request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _beginDrive() async {
    final rideId = rideData?["ride_id"];
    if (rideId == null) return;

    final res = await Api.patch('/rides/beginDrive/$rideId', {});

    if (res != null && res["success"] == true) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Drive started! 🚗')));
        _loadRideData(); // Refresh to show new status
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res?["message"] ?? 'Failed to start drive')),
        );
      }
    }
  }

  Future<void> _endDrive() async {
    final rideId = rideData?["ride_id"];
    if (rideId == null) return;

    final res = await Api.patch('/rides/endDrive/$rideId', {});

    if (res != null && res["success"] == true) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Drive completed! ✅')));

        // Fetch accepted riders and navigate to rating screen
        await _navigateToRateRiders(rideId);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res?["message"] ?? 'Failed to end drive')),
        );
      }
    }
  }

  Future<void> _navigateToRateRiders(int rideId) async {
    // Fetch accepted riders for this ride
    final res = await Api.get('/rides/acceptedRiders/$rideId');

    if (res != null && res["success"] == true) {
      final riders = res["riders"] as List<dynamic>?;

      if (riders != null && riders.isNotEmpty) {
        // Navigate to rating screen
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => RateRidersScreen(
                rideId: rideId,
                riders: riders.map((r) => r as Map<String, dynamic>).toList(),
              ),
            ),
            (route) => false,
          );
        }
      } else {
        // No riders to rate, go to home
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride completed! No riders to rate.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // Error fetching riders, go to home
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _cancelRide() async {
    final rideId = rideData?["ride_id"];
    if (rideId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Ride ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Ride?'),
        content: const Text(
          'Are you sure you want to cancel this ride? All pending requests will be rejected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    print('Attempting to cancel ride ID: $rideId'); // Debug

    final res = await Api.patch('/rides/cancel/$rideId', {});

    print('Cancel response: $res'); // Debug

    if (res != null && res["success"] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      if (mounted) {
        // Show specific error message from backend if available
        final errorMsg =
            res?["message"] ?? 'Failed to cancel ride. Please try again.';
        print('Cancel error message: $errorMsg'); // Debug

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text(
          'Manage My Ride',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildNoRideView()
          : _buildRideView(),
    );
  }

  Widget _buildNoRideView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_car_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              errorMessage ?? 'No active rides',
              style: AppText.subheading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Go Back',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideView() {
    final status = rideData?["status"] ?? "unknown";
    final origin = rideData?["origin"] ?? "";
    final destination = rideData?["destination"] ?? "";
    final departureTime = rideData?["departure_time"] ?? "";
    final availableSeats = rideData?["available_seats"] ?? 0;
    final price = rideData?["price"] ?? "0";
    final paymentMethod = rideData?["payment_method"] ?? "";

    return RefreshIndicator(
      onRefresh: _loadRideData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ride Status Badge
            _buildStatusBadge(status),
            const SizedBox(height: 20),

            // Ride Details Card
            _buildRideDetailsCard(
              origin,
              destination,
              departureTime,
              availableSeats,
              price,
              paymentMethod,
            ),
            const SizedBox(height: 20),

            // Pending Requests Section
            if (pendingRequests.isNotEmpty) ...[
              Text(
                'Pending Requests (${pendingRequests.length})',
                style: AppText.subheading,
              ),
              const SizedBox(height: 10),
              ...pendingRequests.map((request) => _buildRequestCard(request)),
              const SizedBox(height: 20),
            ] else if (status.toLowerCase() == 'pending') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No ride requests yet. You can cancel this ride anytime using the button below.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Buttons
            _buildActionButtons(status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String displayText;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.blue;
        displayText = 'WAITING FOR REQUESTS';
        icon = Icons.schedule;
        break;
      case 'booked':
        color = Colors.orange;
        displayText = 'READY TO START';
        icon = Icons.people;
        break;
      case 'accepted':
        color = Colors.green;
        displayText = 'DRIVE IN PROGRESS';
        icon = Icons.directions_car;
        break;
      default:
        color = Colors.grey;
        displayText = status.toUpperCase();
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            displayText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideDetailsCard(
    String origin,
    String destination,
    String departureTime,
    int availableSeats,
    String price,
    String paymentMethod,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    origin,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(Icons.arrow_downward, color: Colors.grey, size: 20),
            ),
            Row(
              children: [
                const Icon(Icons.flag, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    destination,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow(Icons.access_time, 'Departure', departureTime),
            _buildDetailRow(
              Icons.event_seat,
              'Available Seats',
              availableSeats.toString(),
            ),
            _buildDetailRow(Icons.attach_money, 'Price per Seat', 'BHD $price'),
            _buildDetailRow(
              Icons.payment,
              'Payment',
              paymentMethod.toUpperCase(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final bookingId = request["booking_id"];
    final firstName = request["first_name"] ?? "";
    final lastName = request["last_name"] ?? "";
    final seats = request["seats"] ?? 1;
    final phone = request["phone"] ?? "";
    final rating = request["rider_rating"];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryGreen,
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$seats seat(s) requested',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (rating != null)
                        Text(
                          'Rating: ${_formatRating(rating)} ⭐',
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('📞 +$phone', style: const TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => _acceptRequest(bookingId),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      'Accept',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => _rejectRequest(bookingId),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text(
                      'Decline',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatRating(dynamic rating) {
    if (rating == null) return 'N/A';
    if (rating is int) return rating.toString();
    if (rating is double) return rating.toStringAsFixed(1);
    return rating.toString();
  }

  Widget _buildActionButtons(String status) {
    return Column(
      children: [
        // Begin Drive Button (only show if status is 'booked')
        if (status.toLowerCase() == 'booked')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _beginDrive,
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text(
                'BEGIN DRIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // End Drive Button (only show if status is 'accepted')
        if (status.toLowerCase() == 'accepted')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _endDrive,
              icon: const Icon(Icons.stop, color: Colors.white),
              label: const Text(
                'END DRIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Cancel Ride Button (only show if not accepted/in progress)
        if (status.toLowerCase() != 'accepted')
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _cancelRide,
              icon: const Icon(Icons.cancel),
              label: const Text(
                'CANCEL RIDE',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Refresh Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _loadRideData,
            icon: const Icon(Icons.refresh),
            label: const Text(
              'REFRESH',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
