import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'repositories/chat_repository.dart';
import 'services/auth_service.dart';
import 'views/auth/login_screen.dart';
import 'views/splash/splash_screen.dart';
import 'views/chat/chat_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create mock repository
    final ChatRepository chatRepository = ChatRepository.mock();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<ChatRepository>.value(value: chatRepository),
      ],
      child: const AppEntryPoint(),
    );
  }
}

class AppEntryPoint extends StatelessWidget {
  const AppEntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProv = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Legal Assistant',
      themeMode: themeProv.mode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const AppContent(),
    );
  }
}

class AppContent extends StatelessWidget {
  const AppContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatScreen();


     return FutureBuilder<bool>(
       future: _checkAuthStatus(),
       builder: (context, snapshot) {
         if (snapshot.connectionState == ConnectionState.waiting) {
           return const SplashScreen();
         } else if (snapshot.data == true) {
           return const ChatScreen();
         } else {
           return const LoginScreen();
         }
       },
     );
  }

 Future<bool> _checkAuthStatus() async {
   // Simulate auth check
   await Future.delayed(const Duration(seconds: 2));
   return true; // or false based on your auth logic
 }
}