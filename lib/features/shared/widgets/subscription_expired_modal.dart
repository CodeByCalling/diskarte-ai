import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_functions/cloud_functions.dart';

class SubscriptionExpiredModal extends StatelessWidget {
  const SubscriptionExpiredModal({super.key});

  // No static link anymore. We generate one per user.
  // final String _paymentUrl = 'https://pm.link/...'; 

  Future<void> _launchPayment(BuildContext context) async {
    try {
      // Show loading indicator (simple connection state check would be better but keeping it simple)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating secure payment link...')),
      );

      final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
      final result = await functions
          .httpsCallable('createCheckoutSession')
          .call();

      final String checkoutUrl = result.data['checkoutUrl'];
      
      final Uri url = Uri.parse(checkoutUrl);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $checkoutUrl');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_clock_outlined,
              size: 40,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          const Text(
            'Subscription Expired',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002D72),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Description
          Text(
            'Keep the momentum going! Renew your pass to continue using all Diskarte AI features.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Pricing Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF002D72), width: 1.5),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF0F4FF),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Day Pass',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002D72),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unli-access for 24 hours (Beta)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₱1.00',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _launchPayment(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002D72),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Get Day Pass',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

void showSubscriptionExpiredModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const SafeArea(child: SubscriptionExpiredModal()),
  );
}
