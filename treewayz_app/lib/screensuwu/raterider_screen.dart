import 'package:flutter/material.dart';
import '../servicesuwu/api.dart';
import '../themeuwu/app_text.dart';
import '../themeuwu/app_colors.dart';
import '../screensuwu/home_screen.dart';

class RateRiderScreen extends StatefulWidget {
  final String rideId;
  final String riderId;
  final String riderFirstName;
  final String riderLastName;
  final String? riderPhone;
  final dynamic riderRating;

  const RateRiderScreen({
    super.key,
    required this.rideId,
    required this.riderId,
    required this.riderFirstName,
    required this.riderLastName,
    this.riderPhone,
    this.riderRating,
  });

  @override
  State<RateRiderScreen> createState() => _RateRiderScreenState();
}

class _RateRiderScreenState extends State<RateRiderScreen> {
  int rating = 0;
  bool isSubmitting = false;

  void _selectRating(int selectedRating) {
    setState(() {
      rating = selectedRating;
    });
  }

  Future<void> _submitRating() async {
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // POST /rides/rateRider/:rideId with body: {"rider_id": riderId, "score": rating}
      final response = await Api.post('/rides/rateRider/${widget.rideId}', {
        "rider_id": widget.riderId,
        "score": rating,
      });

      if (mounted) {
        setState(() => isSubmitting = false);

        if (response != null && response["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rider rated successfully!'),
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
              content: Text(response?["message"] ?? 'Failed to submit rating'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSubmitting = false);
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
        // User must submit rating to exit
        if (!didPop && !isSubmitting) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Rating Required'),
              content: const Text('Please rate your rider before continuing.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // LOGO + APP NAME
                Image.asset("elementsuwu/logo.png", height: 180),
                Text("TreeWayz", style: AppText.heading),
                Text("Thrifty, Thoughtful, Together", style: AppText.small),
                const SizedBox(height: 20),

                // RIDER INFO CARD
                _buildRiderCard(),

                const SizedBox(height: 30),

                // RATING SECTION
                Text("Rate the Rider:", style: AppText.subheading),
                const SizedBox(height: 10),

                // Star Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starNumber = index + 1;
                    return GestureDetector(
                      onTap: () => _selectRating(starNumber),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Image.asset(
                          rating >= starNumber
                              ? "elementsuwu/yes rate.png"
                              : "elementsuwu/no rate.png",
                          width: 60,
                          height: 60,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),
                Text(
                  rating == 0 ? "Tap to rate" : "Rating: $rating / 5",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                // SUBMIT BUTTON
                ElevatedButton(
                  onPressed: (rating > 0 && !isSubmitting)
                      ? _submitRating
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    fixedSize: const Size(350, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Submit Rating", style: AppText.button),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiderCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // GREEN HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
            decoration: const BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Center(
              child: Column(
                children: [
                  Text(
                    "H E L L O",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "MY NAME IS",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // BODY CONTENT
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.lightGrey, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full name
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.riderFirstName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.riderLastName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Rider Rating
                Text("Rider Rating: ${_stars(widget.riderRating)}"),

                const SizedBox(height: 10),

                // Contact number
                if (widget.riderPhone != null)
                  Text("Contact No: ${widget.riderPhone}"),
              ],
            ),
          ),

          // PLAIN GREEN FOOTER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
            decoration: const BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  String _stars(dynamic rating) {
    if (rating == null) return "☆☆☆☆☆";

    int count = 0;
    if (rating is int) {
      count = rating;
    } else if (rating is double) {
      count = rating.round();
    } else if (rating is String) {
      count = int.tryParse(rating) ?? 0;
    }

    count = count.clamp(0, 5);
    return "★" * count + "☆" * (5 - count);
  }
}
