// lib/features/chat_room/presentation/bloc/chat_room_cubit.dart
//
// LAYER: features/chat_room/presentation
// RESPONSIBILITY: Load messages for a conversation and send new ones.

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/addressing/contact_address.dart';
import '../../../../core/messaging/message_envelope.dart';
import '../../../../core/messaging/messaging_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────

abstract class ChatRoomState {}

class ChatRoomLoading extends ChatRoomState {}

class ChatRoomLoaded extends ChatRoomState {
  final List<MessageEnvelope> messages;
  ChatRoomLoaded(this.messages);
}

class ChatRoomError extends ChatRoomState {
  final String message;
  ChatRoomError(this.message);
}

// ─── Cubit ───────────────────────────────────────────────────────────────────

class ChatRoomCubit extends Cubit<ChatRoomState> {
  final MessagingService _messaging;

  ChatRoomCubit(this._messaging) : super(ChatRoomLoading());

  Future<void> loadMessages(String conversationId) async {
    emit(ChatRoomLoading());
    try {
      final messages = await _messaging.loadMessages(conversationId);
      emit(ChatRoomLoaded(messages));
    } catch (e) {
      emit(ChatRoomError('Failed to load messages: $e'));
    }
  }

  /// Send a message and reload the thread.
  Future<bool> send({
    required ContactAddress contact,
    required String body,
  }) async {
    try {
      final envelope = await _messaging.send(recipient: contact, body: body);
      final current = state is ChatRoomLoaded
          ? (state as ChatRoomLoaded).messages
          : <MessageEnvelope>[];
      emit(ChatRoomLoaded([envelope, ...current]));
      return envelope.status != DeliveryStatus.failed;
    } catch (_) {
      return false;
    }
  }
}
