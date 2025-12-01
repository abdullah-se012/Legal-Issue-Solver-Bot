import '../models/message.dart';

class ChatService {
  Future<Message> sendMessage(String text) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    // Generate mock response based on input
    String response = _generateResponse(text);

    return Message.bot(response);
  }

  String _generateResponse(String input) {
    final String lowerInput = input.toLowerCase();

    if (lowerInput.contains('hello') || lowerInput.contains('hi')) {
      return "Hello! I'm here to help with your legal questions. I can provide general information about legal topics, but remember I'm an AI assistant and not a substitute for professional legal advice. What would you like to know?";
    } else if (lowerInput.contains('help') || lowerInput.contains('support')) {
      return "I can assist with general legal information on topics like contracts, rights, disputes, and more. Please describe your situation in more detail, and I'll do my best to provide helpful information.";
    } else if (lowerInput.contains('thank')) {
      return "You're welcome! Is there anything else you'd like to know about legal matters?";
    } else if (lowerInput.contains('bye') || lowerInput.contains('goodbye')) {
      return "Goodbye! Remember to consult with a qualified attorney for specific legal advice tailored to your situation.";
    } else {
      return "I understand you're asking about legal matters. While I can provide general legal information, it's important to consult with a qualified attorney for advice specific to your situation. Could you provide more details about what you'd like to know?";
    }
  }

  Future<List<Message>> getInitialMessages() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      Message.bot(
        "Welcome to Legal Assistant! I can help you with general legal information about various topics. Please remember that I'm an AI assistant and cannot provide legal advice or form attorney-client relationships. How can I assist you today?",
        id: 'welcome-message',
      ),
    ];
  }
}