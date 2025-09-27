import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';
import 'dart:developer' as developer;

class MessageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Send a message
  Future<MessageModel?> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      final messageData = {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
      };

      final response = await _supabase
          .from('messages')
          .insert(messageData)
          .select()
          .single();

      return MessageModel.fromJson(response);
    } catch (e) {
      developer.log('Error sending message: $e', name: 'MessageService');
      return null;
    }
  }

  // Get conversation between two users
  Future<List<MessageModel>> getConversation({
    required String userId1,
    required String userId2,
    int page = 0,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .or('and(sender_id.eq.$userId1,receiver_id.eq.$userId2),and(sender_id.eq.$userId2,receiver_id.eq.$userId1)')
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return response.map((message) => MessageModel.fromJson(message)).toList();
    } catch (e) {
      developer.log('Error getting conversation: $e', name: 'MessageService');
      return [];
    }
  }

  // Get all conversations for a user
  Future<List<Map<String, dynamic>>> getUserConversations(String userId) async {
    try {
      // Get the latest message from each conversation
      final response = await _supabase
          .from('messages')
          .select('*, users!messages_sender_id_fkey(*), users!messages_receiver_id_fkey(*)')
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at', ascending: false);

      // Group by conversation partner
      final Map<String, Map<String, dynamic>> conversations = {};
      
      for (final message in response) {
        final otherUserId = message['sender_id'] == userId 
            ? message['receiver_id'] 
            : message['sender_id'];
        
        if (!conversations.containsKey(otherUserId)) {
          final otherUser = message['sender_id'] == userId 
              ? message['users!messages_receiver_id_fkey']
              : message['users!messages_sender_id_fkey'];
          
          conversations[otherUserId] = {
            'otherUser': otherUser,
            'lastMessage': message,
            'unreadCount': 0,
          };
        }
      }

      // Count unread messages
      for (final message in response) {
        if (message['receiver_id'] == userId && !message['is_read']) {
          final otherUserId = message['sender_id'];
          if (conversations.containsKey(otherUserId)) {
            conversations[otherUserId]!['unreadCount'] = 
                (conversations[otherUserId]!['unreadCount'] ?? 0) + 1;
          }
        }
      }

      return conversations.values.toList();
    } catch (e) {
      developer.log('Error getting user conversations: $e', name: 'MessageService');
      return [];
    }
  }

  // Mark message as read
  Future<bool> markMessageAsRead(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('id', messageId);

      return true;
    } catch (e) {
      developer.log('Error marking message as read: $e', name: 'MessageService');
      return false;
    }
  }

  // Mark all messages in a conversation as read
  Future<bool> markConversationAsRead({
    required String userId1,
    required String userId2,
  }) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .or('sender_id.eq.$userId1,receiver_id.eq.$userId1')
          .or('sender_id.eq.$userId2,receiver_id.eq.$userId2');

      return true;
    } catch (e) {
      developer.log('Error marking conversation as read: $e', name: 'MessageService');
      return false;
    }
  }

  // Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('id')
          .eq('receiver_id', userId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      developer.log('Error getting unread count: $e', name: 'MessageService');
      return 0;
    }
  }

  // Delete a message
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .delete()
          .eq('id', messageId);

      return true;
    } catch (e) {
      developer.log('Error deleting message: $e', name: 'MessageService');
      return false;
    }
  }

  // Get real-time messages stream
  Stream<List<MessageModel>> getMessagesStream({
    required String userId1,
    required String userId2,
  }) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((response) => response
            .where((message) => 
                (message['sender_id'] == userId1 && message['receiver_id'] == userId2) ||
                (message['sender_id'] == userId2 && message['receiver_id'] == userId1))
            .map((message) => MessageModel.fromJson(message))
            .toList());
  }

  // Get real-time conversations stream
  Stream<List<Map<String, dynamic>>> getConversationsStream(String userId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((response) {
          // Filter messages for this user
          final userMessages = response.where((message) => 
              message['sender_id'] == userId || message['receiver_id'] == userId).toList();
          
          // Process conversations similar to getUserConversations
          final Map<String, Map<String, dynamic>> conversations = {};
          
          for (final message in userMessages) {
            final otherUserId = message['sender_id'] == userId 
                ? message['receiver_id'] 
                : message['sender_id'];
            
            if (!conversations.containsKey(otherUserId)) {
              final otherUser = message['sender_id'] == userId 
                  ? message['users!messages_receiver_id_fkey']
                  : message['users!messages_sender_id_fkey'];
              
              conversations[otherUserId] = {
                'otherUser': otherUser,
                'lastMessage': message,
                'unreadCount': 0,
              };
            }
          }

          return conversations.values.toList();
        });
  }
}
