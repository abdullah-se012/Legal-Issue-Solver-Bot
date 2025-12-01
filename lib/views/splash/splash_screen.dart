import 'package:flutter/material.dart';
import '../../repositories/chat_repository.dart';
import '../chat/chat_screen.dart';

class SplashScreen extends StatefulWidget {
  final ChatRepository chatRepository;
  const SplashScreen({super.key, required this.chatRepository});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), _goToChat);
  }

  void _goToChat() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(chatRepository: widget.chatRepository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Legal Issue Solver Bot',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
