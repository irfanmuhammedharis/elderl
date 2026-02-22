import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/messaging/presentation/controllers/messaging_controller.dart';
import '../routing/app_router.dart';

/// Helper class for messaging-related operations
class MessagingHelper {
  /// Start a conversation with a user and navigate to chat screen
  /// 
  /// This method:
  /// 1. Creates or retrieves conversation between currentUser and otherUser
  /// 2. Navigates to chat screen with proper conversation ID
  /// 
  /// Returns true if successful, false otherwise
  static Future<bool> startConversation({
    required BuildContext context,
    required WidgetRef ref,
    required String otherUserId,
    required String otherUserName,
    String? relatedRequestId,
  }) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get or create conversation
      final conversationId = await ref
          .read(messagingControllerProvider.notifier)
          .startConversation(
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            relatedRequestId: relatedRequestId,
          );

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (conversationId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start conversation')),
          );
        }
        return false;
      }

      // Navigate to chat screen
      if (context.mounted) {
        context.push(
          '${AppRoutes.chat}?conversationId=$conversationId&otherUserName=$otherUserName&otherUserId=$otherUserId',
        );
      }

      return true;
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      return false;
    }
  }

  /// Navigate to conversations list
  static void navigateToConversations(BuildContext context) {
    context.push(AppRoutes.conversations);
  }
}
