import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController(text: '9524567890');
  final _otpController = TextEditingController(text: '123456');
  bool _isLoading = false;
  ConfirmationResult? _confirmationResult; // For Web Phone Auth
  int _currentCarouselIndex = 0;

  // Step 1: Send SMS
  Future<void> _verifyPhone(StateSetter updateSheetState) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    updateSheetState(() => _isLoading = true);

    try {
      // NOTE: On Web, this triggers the reCAPTCHA automatically
      // Ensure you have added the domain to Firebase Console > Auth > Settings > Authorized Domains
      _confirmationResult = await FirebaseAuth.instance.signInWithPhoneNumber(
        '+63${phone.startsWith("0") ? phone.substring(1) : phone}', // Normalize 0917 -> +63917
      );

      if (mounted) {
        Navigator.pop(context); // Close the login sheet
        _showOtpDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) updateSheetState(() => _isLoading = false);
    }
  }

  // Step 2: Verify OTP
  Future<void> _verifyOtp(StateSetter updateDialogState) async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || _confirmationResult == null) return;

    updateDialogState(() => _isLoading = true);

    try {
      await _confirmationResult!.confirm(otp);
      
      if (mounted) {
        Navigator.pop(context); // Close OTP Dialog
        // Success! Navigate to Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        String message = 'Invalid OTP. Please try again.';
        if (e.toString().contains('invalid-verification-code')) {
           message = 'Invalid OTP. If testing, ensure number is added to Firebase Console "Phone numbers for testing".';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) updateDialogState(() => _isLoading = false);
    }
  }

  void _showOtpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Enter OTP'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Sent to your phone'),
                const SizedBox(height: 16),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '6-digit Code',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _verifyOtp(setState),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Text('Verify'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showLoginSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Mag-login para makaiwas sa pila.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF002D72)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'I-enter ang iyong mobile number.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    hintText: '9171234567',
                    prefixText: '+63 ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _verifyPhone(setState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002D72),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('CONTINUE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100), // Space for floating button
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  // Hero Section
                  // const Icon(Icons.rocket_launch, size: 64, color: Color(0xFF002D72)),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: Image.asset(
                        'assets/images/hero_image.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Diskarte AI',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF002D72),
                    ),
                  ),
                  Text(
                    'Ang Secret Weapon ng Pinoy',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: Colors.grey[700],
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Value Prop
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(fontSize: 28, height: 1.2, color: Colors.black87),
                        children: [
                          TextSpan(text: '₱50 lang.\n', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF002D72))),
                          TextSpan(text: 'AI na tutulong sa '),
                          TextSpan(text: 'Resume', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: ', '),
                          TextSpan(text: 'School', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: ', at '),
                          TextSpan(text: 'Diskarte', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Teaser Card
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: TeaserCard(),
                  ),

                  const SizedBox(height: 48),

                  // Social Proof / Success Stories
                  SizedBox(
                    height: 200, // Slightly increased height
                    child: PageView(
                      controller: PageController(viewportFraction: 0.85),
                      onPageChanged: (index) {
                        setState(() {
                          _currentCarouselIndex = index;
                        });
                      },
                      children: const [
                        TestimonialCard(
                          quote: "Got hired at BPO! Sobrang laking tulong sa English ko.",
                          author: "Juan D., Call Center Agent",
                          color: Color(0xFFE3F2FD),
                          iconData: Icons.headset_mic,
                        ),
                        TestimonialCard(
                          quote: "Passed my Math exam. Salamat Lord! Ang galing mag-explain.",
                          author: "Maria S., Student",
                          color: Color(0xFFFFF3E0),
                          iconData: Icons.school,
                        ),
                        TestimonialCard(
                          quote: "Instant Indigency Letter. Bilib si Kapitan sa formal writing.",
                          author: "Ricardo T., Job Seeker",
                          color: Color(0xFFE8F5E9),
                          iconData: Icons.description,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Carousel Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentCarouselIndex == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentCarouselIndex == index
                              ? const Color(0xFF002D72)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 100), // Bottom padding for FAB
                ],
              ),
            ),
            
            // Floating Call to Action
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: ElevatedButton(
                onPressed: _showLoginSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002D72),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 8,
                  shadowColor: Colors.black45,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('GUSTO KO NITO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TestimonialCard extends StatelessWidget {
  final String quote;
  final String author;
  final Color color;
  final IconData iconData;

  const TestimonialCard({
    super.key,
    required this.quote,
    required this.author,
    required this.color,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Added vertical for shadow
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 32, color: Colors.black12), // Added watermark icon
           const SizedBox(height: 12),
          Text(
            '"$quote"',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Text(
            "- $author",
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class TeaserCard extends StatelessWidget {
  const TeaserCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.description, size: 20, color: Color(0xFF002D72)),
                const SizedBox(width: 8),
                const Text(
                  "Liham sa Barangay.docx",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF002D72), fontSize: 13),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 12, color: Colors.green),
                      const SizedBox(width: 4),
                      Text("Generated", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                    ],
                  ),
                )
              ],
            ),
          ),
          // Content
          Padding(
             padding: const EdgeInsets.all(16),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 _buildSkeletonLine(width: 100),
                 const SizedBox(height: 16),
                 const Text(
                   "Mahal na Kapitan,",
                   style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, fontSize: 14),
                 ),
                 const SizedBox(height: 8),
                 Text(
                   "Ako po ay sumusulat upang humiling ng Indigency Certificate para sa aking medical assistance requirements. Ako po ay residente ng...",
                   style: TextStyle(fontFamily: 'Serif', fontSize: 13, height: 1.5, color: Colors.grey[800]),
                 ),
                 const SizedBox(height: 12),
                 _buildSkeletonLine(width: 200),
                 const SizedBox(height: 6),
                 _buildSkeletonLine(width: 150),
               ],
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLine({required double width}) {
    return Container(
      height: 8,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
