import 'package:flutter/material.dart';
import '../widgets/feature_card.dart';
import '../../shared/screens/chat_screen.dart';
import '../../../services/ai_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diskarte AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF002D72),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              // TODO: Profile / Settings
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a Tool',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF002D72)),
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
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          featureTitle: 'Bureaucracy Breaker',
                          featureSubtitle: 'Gov Forms & Letters',
                          placeholderText: 'Describe what you need...',
                          onSendMessage: (input) async {
                            final aiService = AiService();
                            return await aiService.sendMessage(
                              input,
                              FeatureType.bureaucracyBreaker,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  FeatureCard(
                    title: 'Diskarte\nToolkit',
                    description: 'Resume & Work',
                    icon: Icons.work,
                    color: const Color(0xFF002D72),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          featureTitle: 'Diskarte Toolkit',
                          featureSubtitle: 'Resume & Work',
                          placeholderText: 'What do you need help with?',
                          onSendMessage: (input) async {
                            final aiService = AiService();
                            return await aiService.sendMessage(
                              input,
                              FeatureType.diskarteToolkit,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  FeatureCard(
                    title: 'Aral-Masa',
                    description: 'Homework Helper',
                    icon: Icons.school,
                    color: const Color(0xFF002D72),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          featureTitle: 'Aral-Masa',
                          featureSubtitle: 'Homework Helper',
                          placeholderText: 'Ask your homework question...',
                          onSendMessage: (input) async {
                            final aiService = AiService();
                            return await aiService.sendMessage(
                              input,
                              FeatureType.aralMasa,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  FeatureCard(
                    title: 'Diskarte\nCoach',
                    description: 'Motivation & Grit',
                    icon: Icons.sports_kabaddi,
                    color: const Color(0xFF002D72),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          featureTitle: 'Diskarte Coach',
                          featureSubtitle: 'Motivation & Grit',
                          placeholderText: 'Share what\'s on your mind...',
                          onSendMessage: (input) async {
                            final aiService = AiService();
                            return await aiService.sendMessage(
                              input,
                              FeatureType.diskarteCoach,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
