import '../../models/message.dart';

abstract class ChatViewContract {
  void showLoading(bool loading);
  void showMessages(List<Message> messages);
  void appendMessage(Message message);
  void removeMessageById(String id);
  void showError(String message);
  void showQuickReplies(List<String> options);
}