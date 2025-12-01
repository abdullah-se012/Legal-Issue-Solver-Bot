import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/theme_provider.dart';
import 'repositories/chat_repository.dart';
import 'views/chat/chat_screen.dart';
import 'views/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();

  // Mock repository for development
  final ChatRepository chatRepository = ChatRepository.mock();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<ChatRepository>.value(value: chatRepository),
      ],
      child: const MyAppWrapper(),
    ),
  );
}

class MyAppWrapper extends StatelessWidget {
  const MyAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (BuildContext context, ThemeProvider themeProv, Widget? _) {
        return MaterialApp(
          title: 'Legal Issue Solver Bot',
          debugShowCheckedModeBanner: false,
          themeMode: themeProv.mode,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.indigo,
            useMaterial3: true,
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 1),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.indigo,
            useMaterial3: true,
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 1),
          ),
          home: const ChatScreenWrapper(),
          routes: {
            '/settings': (BuildContext context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}

class ChatScreenWrapper extends StatelessWidget {
  const ChatScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatScreen();
  }
}