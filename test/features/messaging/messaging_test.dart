import 'package:flutter_test/flutter_test.dart';
import 'package:elderl/features/messaging/data/messaging_repository.dart';

void main() {
  group('Message Entity Tests', () {
    test('should create Message with required fields', () {
      final message = Message(
        conversationId: 'conv-123',
        senderId: 'user-1',
        senderName: 'John Doe',
        content: 'Hello!',
      );

      expect(message.conversationId, 'conv-123');
      expect(message.senderId, 'user-1');
      expect(message.senderName, 'John Doe');
      expect(message.content, 'Hello!');
      expect(message.type, 'text'); // Default
      expect(message.isRead, false); // Default
      expect(message.id, isNull);
      expect(message.createdAt, isNull);
    });

    test('should create Message with all fields', () {
      final now = DateTime.now();
      final message = Message(
        id: 'msg-456',
        conversationId: 'conv-123',
        senderId: 'user-1',
        senderName: 'John Doe',
        content: 'Check this location',
        type: 'location',
        createdAt: now,
        isRead: true,
      );

      expect(message.id, 'msg-456');
      expect(message.type, 'location');
      expect(message.isRead, true);
      expect(message.createdAt, now);
    });

    test('toMap should produce correct structure', () {
      final message = Message(
        conversationId: 'conv-123',
        senderId: 'user-1',
        senderName: 'John Doe',
        content: 'Hello!',
      );

      final map = message.toMap();

      expect(map['conversationId'], 'conv-123');
      expect(map['senderId'], 'user-1');
      expect(map['senderName'], 'John Doe');
      expect(map['content'], 'Hello!');
      expect(map['type'], 'text');
      expect(map['isRead'], false);
    });

    test('fromMap should parse all fields', () {
      final map = {
        'conversationId': 'conv-456',
        'senderId': 'user-2',
        'senderName': 'Jane',
        'content': 'Hi there',
        'type': 'image',
        'isRead': true,
        'createdAt': '2025-06-15T10:30:00.000',
      };

      final message = Message.fromMap(map, id: 'msg-789');

      expect(message.id, 'msg-789');
      expect(message.conversationId, 'conv-456');
      expect(message.senderId, 'user-2');
      expect(message.senderName, 'Jane');
      expect(message.content, 'Hi there');
      expect(message.type, 'image');
      expect(message.isRead, true);
    });

    test('fromMap handles missing fields with defaults', () {
      final map = <String, dynamic>{};

      final message = Message.fromMap(map);

      expect(message.conversationId, '');
      expect(message.senderId, '');
      expect(message.senderName, '');
      expect(message.content, '');
      expect(message.type, 'text');
      expect(message.isRead, false);
    });

    test('toMap/fromMap round-trip preserves data', () {
      final original = Message(
        conversationId: 'conv-123',
        senderId: 'user-1',
        senderName: 'Test User',
        content: 'Test message',
        type: 'text',
      );

      final map = original.toMap();
      final restored = Message.fromMap(map, id: 'msg-1');

      expect(restored.conversationId, original.conversationId);
      expect(restored.senderId, original.senderId);
      expect(restored.senderName, original.senderName);
      expect(restored.content, original.content);
      expect(restored.type, original.type);
      expect(restored.isRead, original.isRead);
    });
  });

  group('Conversation Entity Tests', () {
    test('should create Conversation with required fields', () {
      final conversation = Conversation(
        participantIds: ['user-1', 'user-2'],
        participantNames: {'user-1': 'Alice', 'user-2': 'Bob'},
      );

      expect(conversation.participantIds, ['user-1', 'user-2']);
      expect(conversation.participantNames['user-1'], 'Alice');
      expect(conversation.participantNames['user-2'], 'Bob');
      expect(conversation.unreadCount, 0); // Default
      expect(conversation.id, isNull);
    });

    test('should create Conversation with all fields', () {
      final now = DateTime.now();
      final conversation = Conversation(
        id: 'conv-123',
        participantIds: ['user-1', 'user-2'],
        participantNames: {'user-1': 'Alice', 'user-2': 'Bob'},
        lastMessage: 'See you later!',
        lastSenderId: 'user-1',
        lastMessageAt: now,
        createdAt: now,
        unreadCount: 3,
        relatedRequestId: 'req-456',
      );

      expect(conversation.id, 'conv-123');
      expect(conversation.lastMessage, 'See you later!');
      expect(conversation.lastSenderId, 'user-1');
      expect(conversation.unreadCount, 3);
      expect(conversation.relatedRequestId, 'req-456');
    });

    test('getOtherParticipantName returns correct name', () {
      final conversation = Conversation(
        participantIds: ['user-1', 'user-2'],
        participantNames: {'user-1': 'Alice', 'user-2': 'Bob'},
      );

      expect(conversation.getOtherParticipantName('user-1'), 'Bob');
      expect(conversation.getOtherParticipantName('user-2'), 'Alice');
    });

    test('getOtherParticipantName returns Unknown for missing participant', () {
      final conversation = Conversation(
        participantIds: ['user-1'],
        participantNames: {'user-1': 'Alice'},
      );

      expect(conversation.getOtherParticipantName('user-1'), 'Unknown');
    });

    test('getOtherParticipantId returns correct id', () {
      final conversation = Conversation(
        participantIds: ['user-1', 'user-2'],
        participantNames: {'user-1': 'Alice', 'user-2': 'Bob'},
      );

      expect(conversation.getOtherParticipantId('user-1'), 'user-2');
      expect(conversation.getOtherParticipantId('user-2'), 'user-1');
    });

    test('getOtherParticipantId returns null for single participant', () {
      final conversation = Conversation(
        participantIds: ['user-1'],
        participantNames: {'user-1': 'Alice'},
      );

      expect(conversation.getOtherParticipantId('user-1'), isNull);
    });

    test('toMap should produce correct structure', () {
      final conversation = Conversation(
        participantIds: ['user-1', 'user-2'],
        participantNames: {'user-1': 'Alice', 'user-2': 'Bob'},
        lastMessage: 'Hello',
        lastSenderId: 'user-1',
        unreadCount: 2,
        relatedRequestId: 'req-1',
      );

      final map = conversation.toMap();

      expect(map['participantIds'], ['user-1', 'user-2']);
      expect(map['participantNames'], {'user-1': 'Alice', 'user-2': 'Bob'});
      expect(map['lastMessage'], 'Hello');
      expect(map['lastSenderId'], 'user-1');
      expect(map['unreadCount'], 2);
      expect(map['relatedRequestId'], 'req-1');
    });

    test('fromMap should parse all fields', () {
      final map = {
        'participantIds': ['user-1', 'user-2'],
        'participantNames': {'user-1': 'Alice', 'user-2': 'Bob'},
        'lastMessage': 'Bye',
        'lastSenderId': 'user-2',
        'unreadCount': 5,
        'relatedRequestId': 'req-789',
      };

      final conversation = Conversation.fromMap(map, id: 'conv-id');

      expect(conversation.id, 'conv-id');
      expect(conversation.participantIds, ['user-1', 'user-2']);
      expect(conversation.lastMessage, 'Bye');
      expect(conversation.unreadCount, 5);
      expect(conversation.relatedRequestId, 'req-789');
    });

    test('fromMap handles missing fields with defaults', () {
      final map = <String, dynamic>{};

      final conversation = Conversation.fromMap(map);

      expect(conversation.participantIds, isEmpty);
      expect(conversation.participantNames, isEmpty);
      expect(conversation.lastMessage, isNull);
      expect(conversation.unreadCount, 0);
    });

    test('toMap/fromMap round-trip preserves data', () {
      final original = Conversation(
        participantIds: ['user-1', 'user-2'],
        participantNames: {'user-1': 'Alice', 'user-2': 'Bob'},
        lastMessage: 'Test',
        lastSenderId: 'user-1',
        unreadCount: 1,
      );

      final map = original.toMap();
      final restored = Conversation.fromMap(map, id: 'conv-1');

      expect(restored.participantIds, original.participantIds);
      expect(restored.participantNames, original.participantNames);
      expect(restored.lastMessage, original.lastMessage);
      expect(restored.lastSenderId, original.lastSenderId);
      expect(restored.unreadCount, original.unreadCount);
    });
  });
}
