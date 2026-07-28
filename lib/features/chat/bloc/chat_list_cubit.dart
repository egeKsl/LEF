// lib/features/chat/bloc/chat_list_cubit.dart
//
// LAYER: features/chat/bloc
// RESPONSIBILITY: Load and expose the conversation list from storage.
//
// Never touches transport or storage directly — goes through MessagingService.

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/messaging/messaging_service.dart';
import '../../../core/messaging/conversation.dart';

// ─── State ────────────────────────────────────────────────────────────────────

abstract class ChatListState {}

class ChatListLoading extends ChatListState {}

class ChatListLoaded extends ChatListState {
  final List<Conversation> conversations;
  ChatListLoaded(this.conversations);
}

class ChatListError extends ChatListState {
  final String message;
  ChatListError(this.message);
}

// ─── Cubit ───────────────────────────────────────────────────────────────────

class ChatListCubit extends Cubit<ChatListState> {
  final MessagingService _messaging;

  ChatListCubit(this._messaging) : super(ChatListLoading());

  /// Load all conversations from local storage.
  Future<void> load() async {
    emit(ChatListLoading());
    try {
      final conversations = await _messaging.loadConversations();
      emit(ChatListLoaded(conversations));
    } catch (e) {
      emit(ChatListError('Failed to load conversations: $e'));
    }
  }
}
