import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/messaging_repository.dart';

/// Stream provider for user's conversations
final conversationsStreamProvider = StreamProvider.autoDispose<List<Conversation>>((ref) {
  final authState = ref.watch(authControllerProvider);
  if (authState.user == null) {
    return Stream.value([]);
  }

  final messagingRepo = ref.watch(messagingRepositoryProvider);
  return messagingRepo.streamConversations(authState.user!.uid);
});

/// Stream provider for messages in a conversation
final messagesStreamProvider = StreamProvider.autoDispose.family<List<Message>, String>((ref, conversationId) {
  final messagingRepo = ref.watch(messagingRepositoryProvider);
  return messagingRepo.streamMessages(conversationId);
});

/// Provider for unread message count
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final authState = ref.watch(authControllerProvider);
  if (authState.user == null) return 0;

  final messagingRepo = ref.watch(messagingRepositoryProvider);
  return messagingRepo.getUnreadCount(authState.user!.uid);
});

/// Controller for messaging actions
class MessagingController extends StateNotifier<AsyncValue<void>> {
  final MessagingRepository _repository;
  final String _userId;
  final String _userName;

  MessagingController(this._repository, this._userId, this._userName)
      : super(const AsyncValue.data(null));

  /// Start a new conversation
  Future<String?> startConversation({
    required String otherUserId,
    required String otherUserName,
    String? relatedRequestId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final conversationId = await _repository.getOrCreateConversation(
        userId1: _userId,
        userName1: _userName,
        userId2: otherUserId,
        userName2: otherUserName,
        relatedRequestId: relatedRequestId,
      );
      state = const AsyncValue.data(null);
      return conversationId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Send a message
  Future<bool> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
  }) async {
    if (content.trim().isEmpty) return false;

    try {
      await _repository.sendMessage(
        conversationId: conversationId,
        senderId: _userId,
        senderName: _userName,
        content: content.trim(),
        type: type,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String conversationId) async {
    await _repository.markMessagesAsRead(conversationId, _userId);
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteConversation(conversationId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for messaging controller
final messagingControllerProvider = StateNotifierProvider.autoDispose<MessagingController, AsyncValue<void>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final repository = ref.watch(messagingRepositoryProvider);

  return MessagingController(
    repository,
    authState.user?.uid ?? '',
    authState.user?.name ?? '',
  );
});
