import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/message_bubble.dart';
import '../widgets/action_chip_bar.dart';
import '../widgets/subscription_expired_modal.dart';
import '../../../services/ai_service.dart';

class ActionChipItem {
  final String label;
  final String textPayload;
  final bool isReplacement;

  const ActionChipItem({
    required this.label,
    required this.textPayload,
    this.isReplacement = true,
  });
}

class ChatMessage {
  final String text;
  final MessageType type;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.type,
    required this.timestamp,
  });
}

class ChatScreen extends StatefulWidget {
  final String featureTitle;
  final String featureSubtitle;
  final String placeholderText;
  final List<String> ghostTexts;
  final List<ActionChipItem> actionChips;
  final Future<String> Function(String input) onSendMessage;
  final Stream<QuerySnapshot>? messageStream;

  const ChatScreen({
    super.key,
    required this.featureTitle,
    required this.featureSubtitle,
    required this.placeholderText,
    this.ghostTexts = const [],
    this.actionChips = const [],
    required this.onSendMessage,
    this.messageStream,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  
  // Ghost Text Logic
  int _currentGhostIndex = 0;
  Timer? _ghostTimer;
  String get _activePlaceholder => widget.ghostTexts.isNotEmpty 
      ? widget.ghostTexts[_currentGhostIndex] 
      : widget.placeholderText;

  @override
  void initState() {
    super.initState();
    if (widget.ghostTexts.isNotEmpty) {
      _startGhostTimer();
    }
  }

  void _startGhostTimer() {
    _ghostTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentGhostIndex = (_currentGhostIndex + 1) % widget.ghostTexts.length;
        });
      }
    });
  }

  void _handleSubmit(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    _textController.clear();

    try {
      final response = await widget.onSendMessage(text);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Check for Subscription Expiry
      if (response == 'SUBSCRIPTION_EXPIRED' && mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const SubscriptionExpiredModal(),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.featureTitle,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              widget.featureSubtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF002D72),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Messages List
          // Messages List
          Expanded(
            child: widget.messageStream == null
                ? const Center(child: Text('Persistence not enabled'))
                : StreamBuilder<QuerySnapshot>(
                    stream: widget.messageStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Start a conversation',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        reverse: true, // Newest at bottom
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final content = data['content'] as String? ?? '';
                          final sender = data['sender'] as String? ?? 'user';
                          final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                          
                          final type = sender == 'user' ? MessageType.user : MessageType.ai;

                          return Column(
                            children: [
                              MessageBubble(
                                message: content,
                                type: type,
                                timestamp: timestamp,
                              ),
                              if (type == MessageType.ai)
                                ActionChipBar(messageText: content),
                            ],
                          );
                        },
                      );
                    },
                  ),
          ),

          // Loading Indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Typing...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),

          // Action Chips (Thumb-Friendly: Above Input)
          if (widget.actionChips.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: widget.actionChips.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final chip = widget.actionChips[index];
                  return ActionChip(
                    label: Text(
                      chip.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF002D72),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: const Color(0xFF002D72).withOpacity(0.2)),
                    elevation: 1,
                    onPressed: () {
                      if (chip.isReplacement) {
                        _textController.text = chip.textPayload;
                      } else {
                        // Append logic: Add space if needed
                        final current = _textController.text;
                        if (current.isNotEmpty && !current.endsWith(' ')) {
                           _textController.text = '$current ${chip.textPayload}';
                        } else {
                           _textController.text = '$current${chip.textPayload}';
                        }
                      }
                      // Move cursor to end
                      _textController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _textController.text.length),
                      );
                    },
                  );
                },
              ),
            ),

          // Input Area (Thumb-Friendly: Bottom of screen)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -1),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: _activePlaceholder,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _handleSubmit,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send Button (44px minimum for thumb-friendly)
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Material(
                        color: const Color(0xFF002D72),
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => _handleSubmit(_textController.text),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ghostTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
