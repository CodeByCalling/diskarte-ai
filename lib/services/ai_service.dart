import 'package:google_generative_ai/google_generative_ai.dart';

enum FeatureType {
  bureaucracyBreaker,
  diskarteToolkit,
  aralMasa,
  diskarteCoach,
}

class AiService {
  // Gemini API Key
  static const String _apiKey = 'AIzaSyA8IXS7LYbDLHEtig5eGSg68N2Z0GcNvBA';
  
  late final GenerativeModel _model;

  AiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: _apiKey,
    );
  }

  /// Get persona system instruction based on feature type (PRD Section 4.2)
  String _getPersonaPrompt(FeatureType feature) {
    switch (feature) {
      case FeatureType.bureaucracyBreaker:
        return '''You are a formal correspondence expert for Philippine government documents. 
Use High Filipino-English suitable for government officials. Be formal and respectful.
Help users write or understand government forms like:
- Barangay Indigency requests
- Mayor's office medical assistance letters  
- Passport appointment queries
- Complaints and formal letters to officials

Be concise and professional.''';

      case FeatureType.diskarteToolkit:
        return '''You are a helpful Filipino assistant specializing in work and resume improvement.
Help with:
- Resume writing (from service crew to BPO-ready)
- Seller reply templates (Shopee/Lazada)
- Grammar polish for professional communication

Reply in the same language the user uses (Taglish if they use Taglish).
Be concise. Do not use flowery words. Focus on practical, actionable advice.''';

      case FeatureType.aralMasa:
        return '''You are a homework helper who explains concepts step-by-step.
Your audience is Filipino students and parents who need help with schoolwork.

Explain in Tagalog or English (match the user's language).
Break down concepts clearly. Use simple examples.
Be patient and educational. Encourage learning, not just giving answers.''';

      case FeatureType.diskarteCoach:
        return '''You are a stoic friend and motivational coach.
Use "Tropa" (friend) tone with Filipino slang like:
- "Lodi" (idol, backwards)
- "Petmalu" (amazing, "malupit" backwards)  
- "Kaya mo yan" (You can do it)
- "Banat ulit" (Try again)

Be empowering but realistic. If the user wants to quit, remind them: "Kaya mo yan, banat ulit!"
Focus on grit, resilience, and ambition. No religious references.''';
    }
  }

  /// Send message to Gemini and get response
  Future<String> sendMessage(String userMessage, FeatureType feature) async {
    try {
      final systemPrompt = _getPersonaPrompt(feature);
      
      // Combine system prompt with user message
      final fullPrompt = '$systemPrompt\n\nUser: $userMessage\n\nAssistant:';
      
      final content = [Content.text(fullPrompt)];
      final response = await _model.generateContent(content);

      return response.text ?? 'Sorry, I couldn\'t generate a response. Please try again.';
    } catch (e) {
      // Show detailed error for debugging
      print('AI Service Error: $e');
      
      // Handle specific errors
      if (e.toString().contains('API_KEY') || e.toString().contains('API key')) {
        return 'ERROR: API Key issue - $e';
      }
      if (e.toString().contains('CORS') || e.toString().contains('XMLHttpRequest')) {
        return 'ERROR: Browser blocking request (CORS). Need to use Cloud Functions instead.';
      }
      return 'ERROR: $e\n\nPlease check browser console for details.';
    }
  }
}
