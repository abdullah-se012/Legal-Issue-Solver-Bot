// lib/views/conversation/conversation_view.dart
import 'package:flutter/material.dart';
import '../../models/message.dart';

class ConversationView extends StatelessWidget {
  final Map<String, dynamic> conversation;
  const ConversationView({super.key, required this.conversation});

  List<Message> _messagesFromJson(List<dynamic> raw) {
    return raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return Message.fromJson(m);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final raw = conversation['messages'] as List<dynamic>? ?? [];
    final msgs = _messagesFromJson(raw).reversed.toList();
    return Scaffold(
      appBar: AppBar(title: Text(conversation['title']?.toString() ?? 'Conversation')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: msgs.length,
        itemBuilder: (context, i) {
          final m = msgs[i];
          return Column(
            crossAxisAlignment: m.sender == Sender.user ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Material(
                elevation: 1,
                borderRadius: BorderRadius.circular(8),
                color: m.sender == Sender.user ? Colors.blue.shade50 : Colors.grey.shade100,
                child: Padding(padding: const EdgeInsets.all(12), child: Text(m.text)),
              ),
              const SizedBox(height: 6),
              Text('${m.createdAt.hour.toString().padLeft(2,'0')}:${m.createdAt.minute.toString().padLeft(2,'0')}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}
