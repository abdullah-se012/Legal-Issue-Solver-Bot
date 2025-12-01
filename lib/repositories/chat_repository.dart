import '../models/message.dart';

abstract class ChatRepository {
  Future<Message> sendMessage(String text);
  Future<void> loadInitialMessages();

  factory ChatRepository.mock() => MockChatRepository();
}

class MockChatRepository implements ChatRepository {
  @override
  Future<Message> sendMessage(String text) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock responses based on input
    String response = _generateMockResponse(text);

    return Message.bot(response);
  }

  @override
  Future<void> loadInitialMessages() async {
    // Could load initial messages here if needed
    await Future.delayed(const Duration(milliseconds: 500));
  }

  String _generateMockResponse(String input) {
    final String lowerInput = input.toLowerCase();

    if (lowerInput.contains('hello') || lowerInput.contains('hi')) {
      return "Hello! I'm your Legal Assistant. I can help you with various legal questions about contracts, disputes, rights, and more. What legal matter would you like to discuss?";
    } else if (lowerInput.contains('contract')) {
      return "I can help with contract-related questions. Generally, a valid contract requires offer, acceptance, consideration, and mutual intent. However, I'm an AI assistant and cannot provide legal advice. For specific contract issues, please consult a qualified attorney.";
    } else if (lowerInput.contains('rent') || lowerInput.contains('lease')) {
      return "Rental and lease agreements involve specific rights and responsibilities for both tenants and landlords. These vary by jurisdiction. Could you provide more details about your rental situation?";
    } else if (lowerInput.contains('employment') || lowerInput.contains('work')) {
      return "Employment law covers areas like contracts, discrimination, wages, and termination. The specifics depend on your location and employment terms. What particular employment issue are you facing?";
    } else if (lowerInput.contains('rights')) {
      return "Your legal rights depend on the specific situation and jurisdiction. Common areas include consumer rights, tenant rights, employee rights, and civil rights. Could you specify which area you're concerned about?";
    } else if (lowerInput.contains('dispute')) {
      return "Legal disputes can often be resolved through negotiation, mediation, or litigation. The best approach depends on the nature of the dispute, the relationships involved, and the potential outcomes. What type of dispute are you dealing with?";
    } else {
      return "Thank you for your question. As an AI legal assistant, I can provide general legal information but cannot give specific legal advice or form attorney-client relationships. For personalized legal guidance, please consult with a qualified attorney in your jurisdiction. How else can I assist you with general legal information?";
    }
  }
}