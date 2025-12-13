import 'package:flutter/material.dart';
import '../servicesuwu/api.dart';
import '../widgetsuwu/bottom_nav.dart';
import '../screensuwu/logout_screen.dart';
import '../themeuwu/app_text.dart';
import '../themeuwu/app_colors.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  List<Map<String, dynamic>> receipts = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await Api.get('/api/receipts');

      print('Receipts response: $response');

      if (response != null && response["success"] == true) {
        final receiptsList = response["receipts"] as List<dynamic>?;
        if (mounted) {
          setState(() {
            receipts =
                receiptsList?.map((r) => r as Map<String, dynamic>).toList() ??
                [];
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = response?["message"] ?? 'Failed to load receipts';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading receipts: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Error: $e';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LogoutScreen()),
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        bottomNavigationBar: const BottomNav(index: 2),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Image.asset("elementsuwu/logo.png", height: 120),
                    Text("Past Rides", style: AppText.heading),
                  ],
                ),
              ),
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
                              onPressed: _loadReceipts,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : receipts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.receipt_long,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text("No past rides yet", style: AppText.text),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadReceipts,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: receipts.length,
                          itemBuilder: (context, index) {
                            return _buildReceiptCard(receipts[index]);
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

  Widget _buildReceiptCard(Map<String, dynamic> receipt) {
    final bookingId = receipt["booking_id"];
    final driverName = receipt["driver_name"] ?? "Unknown";
    final origin = receipt["origin"] ?? "Unknown";
    final destination = receipt["destination"] ?? "Unknown";
    final departureTime = receipt["departure_time"] ?? "Unknown";
    final amount = receipt["amount"] ?? "0";
    final method = receipt["method"] ?? "cash";
    final paymentDate = receipt["payment_date"] ?? "Unknown";

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Booking #$bookingId",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
                    '$amount BD',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.darkGreen),
                const SizedBox(width: 8),
                Text("Driver: $driverName"),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text("From: $origin")),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.flag, size: 16, color: AppColors.red),
                const SizedBox(width: 8),
                Expanded(child: Text("To: $destination")),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Paid: ${paymentDate.substring(0, paymentDate.length > 10 ? 10 : paymentDate.length)}",
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
                    method,
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
    );
  }
}
