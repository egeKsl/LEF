import 'package:flutter/material.dart';
import '../../../features/auth/presentation/screens/auth_screen.dart';
import '../../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../../features/settings/presentation/screens/settings_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String auth = '/auth';
  static const String chatList = '/chat-list';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
        auth: (context) => const AuthScreen(),
        chatList: (context) => const ChatListScreen(),
        settings: (context) => const SettingsScreen(),
      };
}