import '../models/message.dart';
import '../repositories/chat_repository.dart';
import '../views/chat/chat_view_contract.dart'; // Fixed import path

class ChatPresenter {
  final ChatViewContract view;
  final ChatRepository repository;

  ChatPresenter({
    required this.view,
    required this.repository,
  });

  Future<void> sendUserMessage(String text) async {
    // Create and show user message
    final Message userMsg = Message.user(text);
    view.appendMessage(userMsg);

    // Show loading
    view.showLoading(true);

    try {
      // Send to repository/API
      final Message botMsg = await repository.sendMessage(text);

      // Add bot response
      view.appendMessage(botMsg);

      // Show quick replies if appropriate
      _showQuickReplies(text);

    } catch (e) {
      // Show error message
      final Message errorMsg = Message.bot(
        "I apologize, but I'm having trouble processing your request right now. Please try again shortly.",
        isError: true,
      );
      view.appendMessage(errorMsg);
      view.showError('Failed to get response: $e');
    } finally {
      view.showLoading(false);
    }
  }

  Future<void> loadInitialMessages() async {
    view.showLoading(true);

    try {
      // You could load initial messages from repository if needed
      await repository.loadInitialMessages();

      // Add welcome message
      final Message welcomeMsg = Message.bot(
        "Hello! I'm your Legal Assistant. I can help you with general legal information about contracts, rights, disputes, and more. Please remember that I provide general information only and cannot replace professional legal advice. What would you like to know?",
      );
      view.appendMessage(welcomeMsg);

    } catch (e) {
      view.showError('Failed to load initial messages: $e');
    } finally {
      view.showLoading(false);
    }
  }

  void _showQuickReplies(String userInput) {
    final String lowerInput = userInput.toLowerCase();

    List<String> quickReplies = [];

    if (lowerInput.contains('contract') || lowerInput.contains('agreement')) {
      quickReplies = [
        'What makes a contract valid?',
        'Can I break a contract?',
        'Contract termination rights',
      ];
    } else if (lowerInput.contains('rent') || lowerInput.contains('tenant')) {
      quickReplies = [
        'Tenant rights and responsibilities',
        'Security deposit issues',
        'Lease agreement questions',
      ];
    } else if (lowerInput.contains('employment') || lowerInput.contains('work')) {
      quickReplies = [
        'Employment contract review',
        'Workplace rights',
        'Termination procedures',
      ];
    } else if (lowerInput.contains('rights')) {
      quickReplies = [
        'Consumer rights',
        'Tenant rights',
        'Employee rights',
      ];
    } else {
      // Default quick replies
      quickReplies = [
        'Contract law questions',
        'Rental/lease issues',
        'Employment matters',
        'Consumer rights',
      ];
    }

    view.showQuickReplies(quickReplies);
  }

  // Additional methods for message management
  void deleteMessage(String messageId) {
    // Implementation for deleting a message
    view.removeMessageById(messageId);
  }

  void retryMessage(String messageId, String text) {
    // Implementation for retrying a failed message
    deleteMessage(messageId);
    sendUserMessage(text);
  }
}