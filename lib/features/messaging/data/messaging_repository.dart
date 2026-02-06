import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Message model for chat messages
class Message {
  final String? id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final String type; // text, image, location
  final DateTime? createdAt;
  final bool isRead;

  Message({
    this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.type = 'text',
    this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type,
      'isRead': isRead,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map, {String? id}) {
    return Message(
      id: id,
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      type: map['type'] ?? 'text',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      isRead: map['isRead'] ?? false,
    );
  }
}

/// Conversation model for chat threads
class Conversation {
  final String? id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String? lastMessage;
  final String? lastSenderId;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final int unreadCount;
  final String? relatedRequestId; // Optional link to a help request

  Conversation({
    this.id,
    required this.participantIds,
    required this.participantNames,
    this.lastMessage,
    this.lastSenderId,
    this.lastMessageAt,
    this.createdAt,
    this.unreadCount = 0,
    this.relatedRequestId,
  });

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'lastMessageAt': lastMessageAt != null 
          ? Timestamp.fromDate(lastMessageAt!) 
          : FieldValue.serverTimestamp(),
      'unreadCount': unreadCount,
      'relatedRequestId': relatedRequestId,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map, {String? id}) {
    return Conversation(
      id: id,
      participantIds: (map['participantIds'] as List<dynamic>?)?.cast<String>() ?? [],
      participantNames: (map['participantNames'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v.toString())) ?? {},
      lastMessage: map['lastMessage'] as String?,
      lastSenderId: map['lastSenderId'] as String?,
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      unreadCount: map['unreadCount'] ?? 0,
      relatedRequestId: map['relatedRequestId'] as String?,
    );
  }

  /// Get the other participant's name (for 1-on-1 chats)
  String getOtherParticipantName(String currentUserId) {
    for (final entry in participantNames.entries) {
      if (entry.key != currentUserId) {
        return entry.value;
      }
    }
    return 'Unknown';
  }

  /// Get the other participant's ID (for 1-on-1 chats)
  String? getOtherParticipantId(String currentUserId) {
    for (final id in participantIds) {
      if (id != currentUserId) {
        return id;
      }
    }
    return null;
  }
}

/// Messaging repository for chat operations
class MessagingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _conversationsCollection = 'conversations';
  static const String _messagesCollection = 'messages';

  /// Create or get existing conversation between two users
  Future<String> getOrCreateConversation({
    required String userId1,
    required String userName1,
    required String userId2,
    required String userName2,
    String? relatedRequestId,
  }) async {
    // Check if conversation already exists
    final existingConversation = await _findExistingConversation(userId1, userId2);
    if (existingConversation != null) {
      return existingConversation;
    }

    // Create new conversation
    final conversation = Conversation(
      participantIds: [userId1, userId2],
      participantNames: {userId1: userName1, userId2: userName2},
      relatedRequestId: relatedRequestId,
    );

    final docRef = await _firestore
        .collection(_conversationsCollection)
        .add({
          ...conversation.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });

    return docRef.id;
  }

  /// Find existing conversation between two users
  Future<String?> _findExistingConversation(String userId1, String userId2) async {
    final snapshot = await _firestore
        .collection(_conversationsCollection)
        .where('participantIds', arrayContains: userId1)
        .get();

    for (final doc in snapshot.docs) {
      final participants = (doc.data()['participantIds'] as List<dynamic>).cast<String>();
      if (participants.contains(userId2)) {
        return doc.id;
      }
    }

    return null;
  }

  /// Get conversations for a user
  Future<List<Conversation>> getConversations(String userId) async {
    final snapshot = await _firestore
        .collection(_conversationsCollection)
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Conversation.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  /// Stream conversations for a user
  Stream<List<Conversation>> streamConversations(String userId) {
    return _firestore
        .collection(_conversationsCollection)
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  /// Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
    String type = 'text',
  }) async {
    final batch = _firestore.batch();

    // Add message
    final messageRef = _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesCollection)
        .doc();

    batch.set(messageRef, {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update conversation's last message
    final conversationRef = _firestore
        .collection(_conversationsCollection)
        .doc(conversationId);

    batch.update(conversationRef, {
      'lastMessage': content,
      'lastSenderId': senderId,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Get messages for a conversation
  Future<List<Message>> getMessages(String conversationId, {int limit = 50}) async {
    final snapshot = await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => Message.fromMap(doc.data(), id: doc.id))
        .toList()
        .reversed
        .toList();
  }

  /// Stream messages for a conversation
  Stream<List<Message>> streamMessages(String conversationId) {
    return _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesCollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String readerId) async {
    final snapshot = await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesCollection)
        .where('senderId', isNotEqualTo: readerId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Get unread message count for a user
  Future<int> getUnreadCount(String userId) async {
    final conversations = await getConversations(userId);
    int total = 0;

    for (final conversation in conversations) {
      final snapshot = await _firestore
          .collection(_conversationsCollection)
          .doc(conversation.id)
          .collection(_messagesCollection)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();
      total += snapshot.count ?? 0;
    }

    return total;
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    // Delete all messages first
    final messages = await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesCollection)
        .get();

    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }

    // Delete conversation
    batch.delete(_firestore.collection(_conversationsCollection).doc(conversationId));

    await batch.commit();
  }
}

/// Messaging repository provider
final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository();
});
