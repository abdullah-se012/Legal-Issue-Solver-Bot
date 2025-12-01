import 'package:uuid/uuid.dart';

enum Sender { user, bot }

class Message {
  final String id;
  final String text;
  final Sender sender;
  final DateTime createdAt;
  final bool isError;

  Message({
    String? id,
    required this.text,
    required this.sender,
    DateTime? createdAt,
    this.isError = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // Factory constructor for user messages
  factory Message.user(String text, {String? id, DateTime? createdAt}) {
    return Message(
      id: id,
      text: text,
      sender: Sender.user,
      createdAt: createdAt,
    );
  }

  // Factory constructor for bot messages
  factory Message.bot(String text, {String? id, DateTime? createdAt, bool isError = false}) {
    return Message(
      id: id,
      text: text,
      sender: Sender.bot,
      createdAt: createdAt,
      isError: isError,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String?,
      text: json['text'] as String,
      sender: _stringToSender(json['sender'] as String),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      isError: json['isError'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender': _senderToString(sender),
      'createdAt': createdAt.toIso8601String(),
      'isError': isError,
    };
  }

  static Sender _stringToSender(String s) {
    switch (s) {
      case 'user':
        return Sender.user;
      case 'bot':
      default:
        return Sender.bot;
    }
  }

  static String _senderToString(Sender s) {
    switch (s) {
      case Sender.user:
        return 'user';
      case Sender.bot:
        return 'bot';
    }
  }

  Message copyWith({
    String? id,
    String? text,
    Sender? sender,
    DateTime? createdAt,
    bool? isError,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      createdAt: createdAt ?? this.createdAt,
      isError: isError ?? this.isError,
    );
  }
}