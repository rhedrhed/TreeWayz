import 'package:flutter/material.dart';
import '../servicesuwu/api.dart';
import '../themeuwu/app_colors.dart';
import '../screensuwu/home_screen.dart';

class RateRidersScreen extends StatefulWidget {
  final int rideId;
  final List<Map<String, dynamic>> riders;

  const RateRidersScreen({
    super.key,
    required this.rideId,
    required this.riders,
  });

  @override
  State<RateRidersScreen> createState() => _RateRidersScreenState();
}

class _RateRidersScreenState extends State<RateRidersScreen> {
  Map<int, int> ratings = {}; // riderId -> rating
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize all ratings to 0 (not rated)
    for (var rider in widget.riders) {
      ratings[rider['rider_id']] = 0;
    }
  }

  Future<void> _submitRatings() async {
    // Check if all riders are rated
    for (var entry in ratings.entries) {
      if (entry.value == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please rate all riders before submitting'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => isSubmitting = true);

    // Submit each rating
    bool allSuccess = true;
    for (var rider in widget.riders) {
      final riderId = rider['rider_id'];
      final score = ratings[riderId]!;

      final res = await Api.post('/rides/rateRider/${widget.rideId}', {
        'rider_id': riderId,
        'score': score,
      });

      if (res == null || res['success'] != true) {
        allSuccess = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to rate ${rider['first_name']}: ${res?['message'] ?? 'Unknown error'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => isSubmitting = false);

    if (allSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All ratings submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primaryGreen,
          title: const Text(
            'Rate Your Riders',
            style: TextStyle(color: Colors.white),
          ),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: widget.riders.length,
                  itemBuilder: (context, index) {
                    return _buildRiderCard(widget.riders[index]);
                  },
                ),
              ),
              // Submit Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: isSubmitting ? null : _submitRatings,
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'SUBMIT ALL RATINGS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiderCard(Map<String, dynamic> rider) {
    final riderId = rider['rider_id'];
    final firstName = rider['first_name'] ?? '';
    final lastName = rider['last_name'] ?? '';
    final phone = rider['phone'] ?? '';
    final passengerRating = rider['rider_rating']; // Passenger's current rating
    final currentRating = ratings[riderId] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rider Info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryGreen,
                  radius: 30,
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (phone.isNotEmpty)
                        Text(
                          '+$phone',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      // Show passenger's current rating
                      if (passengerRating != null)
                        Text(
                          'Passenger Rating: ${_formatRating(passengerRating)}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Rating Section
            const Text(
              'How was your experience with this rider?',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            // Star Rating with PNG images
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                final screenWidth = MediaQuery.of(context).size.width;
                final starSize = (screenWidth * 0.10).clamp(40.0, 60.0);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      ratings[riderId] = starValue;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Image.asset(
                      starValue <= currentRating
                          ? "elementsuwu/yes rate.png"
                          : "elementsuwu/no rate.png",
                      width: starSize,
                      height: starSize,
                    ),
                  ),
                );
              }),
            ),
            if (currentRating > 0)
              Center(
                child: Text(
                  '$currentRating ${currentRating == 1 ? 'star' : 'stars'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatRating(dynamic rating) {
    if (rating == null) return "No ratings yet";

    double ratingValue = 0.0;
    if (rating is int) {
      ratingValue = rating.toDouble();
    } else if (rating is double) {
      ratingValue = rating;
    } else if (rating is String) {
      ratingValue = double.tryParse(rating) ?? 0.0;
    }

    ratingValue = ratingValue.clamp(0.0, 5.0);
    int starCount = ratingValue.round();
    String stars = "★" * starCount + "☆" * (5 - starCount);

    return "${ratingValue.toStringAsFixed(1)} $stars";
  }
}
