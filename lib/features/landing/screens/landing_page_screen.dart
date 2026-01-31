import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/ai_service.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../auth/screens/login_screen.dart'; // Reusing LoginScreen logic or components

class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _signInAnonymously();
  }

  Future<void> _signInAnonymously() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        await _auth.signInAnonymously();
      }
      if (mounted) {
        setState(() {
          _isAnonymous = true;
        });
      }
    } catch (e) {
      print("Anonymous Auth Error: $e");
    }
  }

  void _showLoginSheet() {
    // We can reuse the existing LoginScreen logic by navigating to it 
    // or showing it as a modal. For better UX, let's show it as a modal.
    // However, since LoginScreen is a Scaffold, it's better to push it 
    // or refactor LoginScreen to be a Widget. 
    // For now, let's push to LoginScreen but modify LoginScreen to clear stack on success.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  
                  // Clean Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Row(
                           children: [
                             const Icon(Icons.rocket_launch, color: Color(0xFF002D72), size: 28),
                             const SizedBox(width: 8),
                             Text(
                              'Diskarte AI',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF002D72),
                              ),
                            ),
                           ],
                         ),
                         TextButton(
                           onPressed: _showLoginSheet, 
                           child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF002D72)))
                         )
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Hero Text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Text(
                          'Ang Secret Weapon\nng Pinoy',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '₱1 lang (Beta). AI na tutulong sa Resume, School, at Diskarte.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // TRIAL CHAT WIDGET
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TrialChatWidget(onUnlock: _showLoginSheet),
                  ),

                  const SizedBox(height: 48),

                  // Social Proof Carousel
                  SizedBox(
                    height: 160,
                    child: PageView(
                      controller: PageController(viewportFraction: 0.85),
                      children: const [
                         TestimonialCard(
                          quote: "Got hired at BPO! Sobrang laking tulong sa English ko.",
                          author: "Juan D., Call Center Agent",
                          color: Color(0xFFE3F2FD),
                        ),
                        TestimonialCard(
                          quote: "Passed my Math exam. Salamat Lord! Ang galing mag-explain.",
                          author: "Maria S., Student",
                          color: Color(0xFFFFF3E0),
                        ),
                        TestimonialCard(
                          quote: "Instant Indigency Letter. Bilib si Kapitan sa formal writing.",
                          author: "Ricardo T., Job Seeker",
                          color: Color(0xFFE8F5E9),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),

                  // Inline CTA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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

                  const SizedBox(height: 60),
                  
                  // Business Footer
                  Center(
                    child: Text(
                      'Owned and Operated by\nTekton Information Technology Solutions',
                       textAlign: TextAlign.center,
                       style: GoogleFonts.inter(
                         fontSize: 10,
                         color: Colors.grey[400],
                       ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),


          ],
        ),
      ),
    );
  }
}

// Reuse Testimonial Card
class TestimonialCard extends StatelessWidget {
  final String quote;
  final String author;
  final Color color;

  const TestimonialCard({
    super.key,
    required this.quote,
    required this.author,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '"$quote"',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Text(
            "- $author",
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TRIAL CHAT WIDGET LOGIC
// ---------------------------------------------------------------------------

class TrialChatWidget extends StatefulWidget {
  final VoidCallback onUnlock;
  const TrialChatWidget({super.key, required this.onUnlock});

  @override
  State<TrialChatWidget> createState() => _TrialChatWidgetState();
}

class _TrialChatWidgetState extends State<TrialChatWidget> {
  final List<Map<String, String>> _messages = [
    {'sender': 'ai', 'text': 'Kamusta! Ako si Diskarte Coach. Ano ang maitutulong ko sa resume, school, o lovelife mo? (Free Trial)'}
  ];
  final TextEditingController _controller = TextEditingController();
  final AiService _aiService = AiService();
  bool _isLoading = false;
  bool _limitReached = false;
  int _msgCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTrialStatus();
  }

  Future<void> _loadTrialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _msgCount = prefs.getInt('trial_msg_count') ?? 0;
      if (_msgCount >= 3) {
        _limitReached = true;
      }
    });
  }

  Future<void> _incrementTrial() async {
    final prefs = await SharedPreferences.getInstance();
    _msgCount++;
    await prefs.setInt('trial_msg_count', _msgCount);
    if (_msgCount >= 3) {
      setState(() {
        _limitReached = true;
      });
    }
  }

  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    // Check Limit
    if (_limitReached) {
      widget.onUnlock();
      return;
    }

    // Optimistic UI
    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();

    // Increment Counter (Fire and forget)
    _incrementTrial();

    try {
      // Call AI (Works if Anonymous Auth is success)
      final response = await _aiService.sendMessage(text, FeatureType.diskarteCoach);
      
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'ai', 'text': response});
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'ai', 'text': 'Pasensya na, may error. Subukan ulit.'});
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Chat Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F4FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF002D72),
                  radius: 14,
                  child: Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Text("Try Diskarte Coach", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF002D72))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _limitReached ? "Limit Reached" : "${3 - _msgCount} free messages left",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _limitReached ? Colors.red : Colors.green),
                  ),
                )
              ],
            ),
          ),

          // Messages
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg['sender'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 260),
                        decoration: BoxDecoration(
                          color: isUser ? const Color(0xFF002D72) : Colors.grey[100],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isUser ? 16 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 16),
                          ),
                        ),
                        child: Text(
                          msg['text']!,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                // Loading Bubble
                if (_isLoading)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                      child: const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),

                // Blur Overlay if Limit Reached
                if (_limitReached)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(24), // Match parent
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline, size: 48, color: Color(0xFF002D72)),
                            const SizedBox(height: 16),
                            const Text(
                              "Bitin ba?",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF002D72)),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Unlock Unlimited Access\nfor just ₱1 (Beta)",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: widget.onUnlock,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF002D72),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Unlock Now"),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_limitReached,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                IconButton(
                  onPressed: _limitReached ? widget.onUnlock : _handleSend,
                  icon: Icon(
                    _limitReached ? Icons.lock : Icons.send_rounded,
                    color: const Color(0xFF002D72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
