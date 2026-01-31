import 'package:flutter/material.dart';
import '../widgets/feature_card.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/screens/chat_screen.dart';
import '../../shared/widgets/subscription_expired_modal.dart';
import '../../../services/ai_service.dart';

import '../../admin/screens/admin_dashboard_screen.dart';
import '../../../config/owner_config.dart';
import '../../resume/screens/resume_wizard_screen.dart';
import '../../bureaucracy/screens/bureaucracy_wizard_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Stream<QuerySnapshot> _getChatStream(FeatureType feature) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('chat_logs')
        .doc(feature.name)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user?.uid == OWNER_UID;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diskarte AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF002D72),
        elevation: 0,
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.amber), // Amber for visibility
              tooltip: 'Admin Dashboard',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              // TODO: Profile / Settings
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final bool isActive = userData?['is_active'] ?? false;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select a Tool',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF002D72)),
                    ),
                    if (isActive)
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ACTIVE PASS',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[800]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                    children: [
                      FeatureCard(
                        title: 'Bureaucracy\nBreaker',
                        description: 'Gov forms & Letters',
                        icon: Icons.account_balance,
                        color: const Color(0xFF002D72),
                        isLocked: !isActive,
                        onTap: () {
                          if (!isActive) {
                            showSubscriptionExpiredModal(context);
                            return;
                          }
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 8),
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFE3F2FD),
                                    child: Icon(Icons.chat, color: Color(0xFF002D72)),
                                  ),
                                  title: const Text('Quick Chat'),
                                  subtitle: const Text('Ask general questions about forms.'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          featureTitle: 'Bureaucracy Breaker',
                                          featureSubtitle: 'Gov Forms & Letters',
                                          placeholderText: 'Describe what you need...',
                                          ghostTexts: const [
                                            'Paano kumuha ng Indigency?',
                                            'Liham sa Mayor para sa gamot...',
                                            'Complaint letter sa Barangay...',
                                          ],
                                          actionChips: const [
                                            ActionChipItem(label: 'Gawing Formal', textPayload: 'Make this formal: ', isReplacement: false),
                                            ActionChipItem(label: 'Tagalog', textPayload: 'Translate to Tagalog', isReplacement: false),
                                            ActionChipItem(label: 'English', textPayload: 'Translate to English', isReplacement: false),
                                          ],
                                          messageStream: _getChatStream(FeatureType.bureaucracyBreaker),
                                          onSendMessage: (input) async {
                                            final aiService = AiService();
                                            return await aiService.sendMessage(
                                              input,
                                              FeatureType.bureaucracyBreaker,
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const Divider(),
                                ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFE3F2FD),
                                    child: Icon(Icons.assignment, color: Color(0xFF002D72)),
                                  ),
                                  title: const Text('Letter Wizard'),
                                  subtitle: const Text('Step-by-step wizard to create a formal letter.'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const BureaucracyWizardScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          );
                        },
                      ),
                      FeatureCard(
                        title: 'Diskarte\nToolkit',
                        description: 'Resume & Work',
                        icon: Icons.work,
                        color: const Color(0xFF002D72),
                        isLocked: !isActive,
                        onTap: () {
                          if (!isActive) {
                            showSubscriptionExpiredModal(context);
                            return;
                          }
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 8),
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFE3F2FD),
                                    child: Icon(Icons.chat, color: Color(0xFF002D72)),
                                  ),
                                  title: const Text('Quick Chat'),
                                  subtitle: const Text('Ask general questions about work.'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          featureTitle: 'Diskarte Toolkit',
                                          featureSubtitle: 'Resume & Work',
                                          placeholderText: 'What do you need help with?',
                                          ghostTexts: const [
                                            'Gumawa ng Resume for Call Center...',
                                            'Reply sa angry customer...',
                                            'Ayusin ang grammar ko...',
                                          ],
                                          actionChips: const [
                                            ActionChipItem(label: 'Check Grammar', textPayload: 'Check grammar: ', isReplacement: false),
                                            ActionChipItem(label: 'Polite Reply', textPayload: 'Write a polite reply: ', isReplacement: false),
                                            ActionChipItem(label: 'To English', textPayload: 'Translate to English', isReplacement: false),
                                          ],
                                          messageStream: _getChatStream(FeatureType.diskarteToolkit),
                                          onSendMessage: (input) async {
                                            final aiService = AiService();
                                            return await aiService.sendMessage(
                                              input,
                                              FeatureType.diskarteToolkit,
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const Divider(),
                                ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFE3F2FD),
                                    child: Icon(Icons.description, color: Color(0xFF002D72)),
                                  ),
                                  title: const Text('Resume Builder'),
                                  subtitle: const Text('Step-by-step wizard to create a resume.'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ResumeWizardScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          );
                        },
                      ),
                      FeatureCard(
                        title: 'Aral-Masa',
                        description: 'Homework Helper',
                        icon: Icons.school,
                        color: const Color(0xFF002D72),
                        isLocked: !isActive,
                        onTap: () {
                          if (!isActive) {
                            showSubscriptionExpiredModal(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                featureTitle: 'Aral-Masa',
                                featureSubtitle: 'Homework Helper',
                                placeholderText: 'Ask your homework question...',
                                ghostTexts: const [
                                  'Solve 2x + 5 = 10...',
                                  'History of Jose Rizal...',
                                  'Explain Photosynthesis...',
                                ],
                                actionChips: const [
                                  ActionChipItem(label: 'Explain Simply', textPayload: 'Explain simply: ', isReplacement: false),
                                  ActionChipItem(label: 'Step-by-Step', textPayload: 'Show step-by-step solution', isReplacement: false),
                                  ActionChipItem(label: 'Tagalog', textPayload: 'Explain in Tagalog', isReplacement: false),
                                ],
                                messageStream: _getChatStream(FeatureType.aralMasa),
                                onSendMessage: (input) async {
                                  final aiService = AiService();
                                  return await aiService.sendMessage(
                                    input,
                                    FeatureType.aralMasa,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      FeatureCard(
                        title: 'Diskarte\nCoach',
                        description: 'Motivation & Grit',
                        icon: Icons.sports_kabaddi,
                        color: const Color(0xFF002D72),
                        isLocked: !isActive,
                        onTap: () {
                          if (!isActive) {
                            showSubscriptionExpiredModal(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                featureTitle: 'Diskarte Coach',
                                featureSubtitle: 'Motivation & Grit',
                                placeholderText: 'Share what\'s on your mind...',
                                ghostTexts: const [
                                  'Pagod na ako sa trabaho...',
                                  'Paano dumiskarte sa buhay?',
                                  'Bigyan mo ako ng motivation...',
                                ],
                                actionChips: const [
                                  ActionChipItem(label: 'Motivation', textPayload: 'Give me motivation', isReplacement: true),
                                  ActionChipItem(label: 'Advice', textPayload: 'I need advice on: ', isReplacement: false),
                                  ActionChipItem(label: 'Tropa Talk', textPayload: 'Talk to me like a close friend', isReplacement: false),
                                ],
                                messageStream: _getChatStream(FeatureType.diskarteCoach),
                                onSendMessage: (input) async {
                                  final aiService = AiService();
                                  return await aiService.sendMessage(
                                    input,
                                    FeatureType.diskarteCoach,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Share.share(
                        'Pare, try mo to. ₱50 lang may AI helper ka na sa Resume at School. Ang secret weapon ng Pinoy: https://diskarte.ai',
                      );
                    },
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: const Text(
                      'I-share sa Tropa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7d32), // Darker Green for credibility but distinct
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
