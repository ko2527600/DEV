import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../services/message_service.dart';
import '../../services/user_service.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final MessageService _messageService = MessageService();
  final UserService _userService = UserService();
  
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  Stream<List<Map<String, dynamic>>>? _conversationsStream;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      
      if (userId != null) {
        // Load initial conversations
        final conversations = await _messageService.getUserConversations(userId);
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
        
        // Set up real-time stream
        _conversationsStream = _messageService.getConversationsStream(userId);
        _conversationsStream?.listen((conversations) {
          setState(() {
            _conversations = conversations;
          });
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load conversations');
    }
  }

  void _navigateToChat(Map<String, dynamic> conversation) {
    final otherUser = conversation['otherUser'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUserId: otherUser['id'],
          otherUserName: otherUser['full_name'] ?? 'User',
        ),
      ),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return _buildConversationTile(conversation);
                    },
                  ),
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
            'No conversations yet',
            style: TextStyle(
              fontSize: AppConstants.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: Color(AppConstants.textColorLight),
            ),
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          Text(
            'Start browsing products and contact farmers to begin conversations',
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

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    final otherUser = conversation['otherUser'];
    final lastMessage = conversation['lastMessage'];
    final unreadCount = conversation['unreadCount'] ?? 0;
    
    final userName = otherUser['full_name'] ?? 'User';
    final userType = otherUser['user_type'] ?? 'user';
    final messageContent = lastMessage['content'] ?? '';
    final messageTime = lastMessage['created_at'] != null
        ? DateFormat('MMM dd, HH:mm').format(
            DateTime.parse(lastMessage['created_at']),
          )
        : '';
    final isUnread = unreadCount > 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getUserTypeColor(userType).withOpacity(0.1),
        child: Icon(
          _getUserTypeIcon(userType),
          color: _getUserTypeColor(userType),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              userName,
              style: TextStyle(
                fontSize: AppConstants.fontSizeNormal,
                fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                color: Color(AppConstants.textColor),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isUnread)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Color(AppConstants.primaryColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                _getUserTypeIcon(userType),
                size: 16,
                color: Color(AppConstants.textColorLight),
              ),
              const SizedBox(width: 4),
              Text(
                _getUserTypeLabel(userType),
                style: TextStyle(
                  fontSize: AppConstants.fontSizeSmall,
                  color: Color(AppConstants.textColorLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  messageContent,
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeSmall,
                    color: isUnread 
                        ? Color(AppConstants.textColor)
                        : Color(AppConstants.textColorLight),
                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSmall),
              Text(
                messageTime,
                style: TextStyle(
                  fontSize: AppConstants.fontSizeSmall,
                  color: Color(AppConstants.textColorLight),
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () => _navigateToChat(conversation),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingNormal,
        vertical: AppConstants.spacingSmall,
      ),
    );
  }

  Color _getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'farmer':
        return Color(AppConstants.primaryColor);
      case 'buyer':
        return Color(AppConstants.accentColor);
      default:
        return Color(AppConstants.textColorLight);
    }
  }

  IconData _getUserTypeIcon(String userType) {
    switch (userType.toLowerCase()) {
      case 'farmer':
        return Icons.agriculture;
      case 'buyer':
        return Icons.shopping_cart;
      default:
        return Icons.person;
    }
  }

  String _getUserTypeLabel(String userType) {
    switch (userType.toLowerCase()) {
      case 'farmer':
        return 'Farmer';
      case 'buyer':
        return 'Buyer';
      default:
        return 'User';
    }
  }
}
