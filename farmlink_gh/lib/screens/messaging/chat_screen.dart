import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../models/message_model.dart';
import '../../services/message_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService _messageService = MessageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  Stream<List<MessageModel>>? _messagesStream;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.id;
      
      if (currentUserId != null) {
        // Load initial messages
        final messages = await _messageService.getConversation(
          userId1: currentUserId,
          userId2: widget.otherUserId,
        );
        
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        
        // Mark conversation as read
        await _messageService.markConversationAsRead(
          userId1: currentUserId,
          userId2: widget.otherUserId,
        );
        
        // Set up real-time stream
        _messagesStream = _messageService.getMessagesStream(
          userId1: currentUserId,
          userId2: widget.otherUserId,
        );
        
        _messagesStream?.listen((messages) {
          setState(() {
            _messages = messages;
          });
          _scrollToBottom();
        });
        
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load messages');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.id;
      
      if (currentUserId != null) {
        final sentMessage = await _messageService.sendMessage(
          senderId: currentUserId,
          receiverId: widget.otherUserId,
          content: message,
        );
        
        if (sentMessage != null) {
          _scrollToBottom();
        } else {
          _showErrorSnackBar('Failed to send message');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error sending message');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(AppConstants.errorColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUserName,
              style: const TextStyle(
                fontSize: AppConstants.fontSizeNormal,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Tap to view profile',
              style: TextStyle(
                fontSize: AppConstants.fontSizeSmall,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show chat options (block, report, etc.)
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppConstants.spacingNormal),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.senderId == currentUserId;
                          return _buildMessageBubble(message, isMe);
                        },
                      ),
          ),
          
          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppConstants.spacingNormal),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: AppConstants.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: Color(AppConstants.textColorLight),
            ),
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          Text(
            'Start the conversation by sending a message',
            style: TextStyle(
              fontSize: AppConstants.fontSizeNormal,
              color: Color(AppConstants.textColorLight),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingNormal),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(AppConstants.primaryColor).withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 16,
                color: Color(AppConstants.primaryColor),
              ),
            ),
            const SizedBox(width: AppConstants.spacingSmall),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingNormal,
                vertical: AppConstants.spacingSmall,
              ),
              decoration: BoxDecoration(
                color: isMe 
                    ? Color(AppConstants.primaryColor)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeNormal,
                      color: isMe ? Colors.white : Color(AppConstants.textColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.createdAt),
                        style: TextStyle(
                          fontSize: AppConstants.fontSizeSmall,
                          color: isMe 
                              ? Colors.white70 
                              : Color(AppConstants.textColorLight),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isMe) ...[
            const SizedBox(width: AppConstants.spacingSmall),
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(AppConstants.accentColor).withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 16,
                color: Color(AppConstants.accentColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingNormal),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
                  borderSide: BorderSide(color: Color(AppConstants.primaryColor)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingNormal,
                  vertical: AppConstants.spacingSmall,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: AppConstants.spacingSmall),
          Container(
            decoration: BoxDecoration(
              color: Color(AppConstants.primaryColor),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
