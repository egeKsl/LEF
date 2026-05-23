import 'package:flutter/material.dart';
import '../../../features/auth/presentation/screens/auth_screen.dart';
import '../../../features/chat/presentation/screens/chat_list_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String auth = '/auth';
  static const String chatList = '/chat-list';

  static Map<String, WidgetBuilder> get routes => {
        auth: (context) => const AuthScreen(),
        chatList: (context) => const ChatListScreen(),
      };
}