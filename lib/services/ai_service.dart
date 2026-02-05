import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum FeatureType {
  bureaucracyBreaker,
  diskarteToolkit,
  aralMasa,
  diskarteCoach,
}

class AiService {
  // Use the HTTP endpoint directly to avoid dart2js Cloud Functions SDK issues (Int64)
  static const String _functionUrl = 'https://asia-southeast1-diskarte-ai.cloudfunctions.net/callGemini';

  static const String subscriptionExpiredMessage = 'SUBSCRIPTION_EXPIRED';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save message to Firestore
  Future<void> _saveMessage(String userId, String message, String sender, FeatureType feature) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_logs')
          .doc(feature.name)
          .collection('messages')
          .add({
        'content': message,
        'sender': sender,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving message to Firestore: $e');
      // Don't block the UI/flow if save fails, just log it.
    }
  }

  /// Send message to Gemini via Cloud Function (HTTP Trigger)
  Future<String> sendMessage(String userMessage, FeatureType feature) async {
    try {
      var user = _auth.currentUser;
      
      // Retry mechanism for anonymous login if user is missing
      if (user == null) {
        int retries = 3;
        while (retries > 0) {
          try {
            print("User is null. Attempting auto-anonymous login... (Attempts left: $retries)");
            final userCredential = await _auth.signInAnonymously();
            user = userCredential.user;
            if (user != null) break;
          } catch (e) {
            print("Auto-Auth attempt failed: $e");
            retries--;
            if (retries == 0) {
              return 'Unable to start chat. Auth Error: ${e.toString().replaceAll('firebase_auth/', '')}. Please refresh.';
            }
            await Future.delayed(const Duration(milliseconds: 1000));
          }
        }
      }

      if (user == null) {
        return 'Unable to start chat (Auth Failed - Unknown). Please refresh.';
      }

      // 1. Save User Message (Fire and Forget - don't await)
      _saveMessage(user.uid, userMessage, 'user', feature);

      String token;
      try {
        token = await user.getIdToken().timeout(const Duration(seconds: 10)) ?? '';
      } catch (e) {
        print('Auth Token Timeout: $e');
        return 'Connection error (Auth). Please refresh and try again.';
      }
      
      if (token.isEmpty) {
         return 'Authentication failed (No Token). Please login again.';
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: headers,
        body: jsonEncode({
          'message': userMessage,
          'featureType': feature.name,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final aiResponse = decoded['text'] as String;
        
        // 2. Save AI Response (Fire and Forget)
        _saveMessage(user.uid, aiResponse, 'ai', feature);
        
        return aiResponse;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('AI Service Auth Error (HTTP ${response.statusCode}): ${response.body}');
        return subscriptionExpiredMessage;
      } else {
        print('AI Service Error (HTTP ${response.statusCode}): ${response.body}');
        return 'Sorry, I encountered a server error (${response.statusCode}). Please try again later.';
      }
    } catch (e) {
      print('AI Service Error: $e');
      return 'Sorry, I encountered an error. Please try again later. ($e)';
    }
  }
}
