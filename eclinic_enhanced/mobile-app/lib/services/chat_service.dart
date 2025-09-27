import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final List<MessageModel> _messages = [];
  final bool _isLoading = false;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;

  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<String?> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    try {
      final message = MessageModel(
        id: '',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        type: type,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());

      // Update chat's last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': content,
        'lastMessageTime': message.timestamp.toIso8601String(),
        'lastSenderId': senderId,
      });

      return null; // Success
    } catch (e) {
      debugPrint('Error sending message: $e');
      return 'Failed to send message. Please try again.';
    }
  }

  Future<String?> createOrGetChat({
    required String patientId,
    required String doctorId,
    required String patientName,
    required String doctorName,
  }) async {
    try {
      // Check if chat already exists
      final existingChat = await _firestore
          .collection('chats')
          .where('participants.$patientId', isEqualTo: true)
          .where('participants.$doctorId', isEqualTo: true)
          .get();

      if (existingChat.docs.isNotEmpty) {
        return existingChat.docs.first.id;
      }

      // Create new chat
      final chatData = {
        'participants': {
          patientId: true,
          doctorId: true,
        },
        'participantNames': {
          patientId: patientName,
          doctorId: doctorName,
        },
        'createdAt': DateTime.now().toIso8601String(),
        'lastMessage': '',
        'lastMessageTime': DateTime.now().toIso8601String(),
        'lastSenderId': '',
      };

      final chatDoc = await _firestore.collection('chats').add(chatData);
      return chatDoc.id;
    } catch (e) {
      debugPrint('Error creating/getting chat: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUserChats(String userId) async {
    try {
      final query = await _firestore
          .collection('chats')
          .where('participants.$userId', isEqualTo: true)
          .orderBy('lastMessageTime', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'lastMessage': data['lastMessage'] ?? '',
          'lastMessageTime': data['lastMessageTime'] ?? '',
          'participantNames': data['participantNames'] ?? {},
          'participants': data['participants'] ?? {},
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading user chats: $e');
      return [];
    }
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }
}

