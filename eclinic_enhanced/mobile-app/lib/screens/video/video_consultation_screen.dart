import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/video_consultation_service.dart';
import '../../utils/app_theme.dart';
import '../../models/video_consultation_model.dart';

class VideoConsultationScreen extends StatefulWidget {
  final String consultationId;
  final bool isDoctor;

  const VideoConsultationScreen({
    super.key,
    required this.consultationId,
    this.isDoctor = false,
  });

  @override
  State<VideoConsultationScreen> createState() => _VideoConsultationScreenState();
}

class _VideoConsultationScreenState extends State<VideoConsultationScreen> {
  VideoConsultation? _consultation;
  List<ConsultationParticipant> _participants = [];
  List<ConsultationMessage> _messages = [];
  bool _isLoading = true;
  bool _isAudioEnabled = true;
  bool _isVideoEnabled = true;
  bool _isScreenSharing = false;
  bool _isChatVisible = false;
  final ConnectionQuality _connectionQuality = ConnectionQuality.good;
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadConsultation();
    _listenToMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConsultation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final videoService = context.read<VideoConsultationService>();
      final consultation = await videoService.getVideoConsultation(widget.consultationId);
      
      if (consultation != null) {
        setState(() {
          _consultation = consultation;
        });
        
        await _loadParticipants();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading consultation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadParticipants() async {
    try {
      final videoService = context.read<VideoConsultationService>();
      final participants = await videoService.getActiveParticipants(widget.consultationId);
      
      setState(() {
        _participants = participants;
      });
    } catch (e) {
      debugPrint('Error loading participants: $e');
    }
  }

  void _listenToMessages() {
    final videoService = context.read<VideoConsultationService>();
    videoService.getConsultationMessages(widget.consultationId).listen((messages) {
      setState(() {
        _messages = messages;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _joinConsultation() async {
    try {
      final videoService = context.read<VideoConsultationService>();
      await videoService.joinConsultation(widget.consultationId, 'current_user_id');
      await _loadConsultation();
      await _loadParticipants();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining consultation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startConsultation() async {
    try {
      final videoService = context.read<VideoConsultationService>();
      await videoService.startConsultation(widget.consultationId, 'current_user_id');
      await _loadConsultation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting consultation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _endConsultation() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _EndConsultationDialog(),
    );

    if (result != null) {
      try {
        final videoService = context.read<VideoConsultationService>();
        await videoService.endConsultation(
          widget.consultationId,
          'current_user_id',
          notes: result['notes'],
          prescription: result['prescription'],
        );
        
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error ending consultation: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleAudio() async {
    setState(() {
      _isAudioEnabled = !_isAudioEnabled;
    });

    try {
      final videoService = context.read<VideoConsultationService>();
      await videoService.updateParticipantStatus(
        widget.consultationId,
        'current_user_id',
        audioEnabled: _isAudioEnabled,
      );
    } catch (e) {
      debugPrint('Error toggling audio: $e');
    }
  }

  Future<void> _toggleVideo() async {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });

    try {
      final videoService = context.read<VideoConsultationService>();
      await videoService.updateParticipantStatus(
        widget.consultationId,
        'current_user_id',
        videoEnabled: _isVideoEnabled,
      );
    } catch (e) {
      debugPrint('Error toggling video: $e');
    }
  }

  Future<void> _toggleScreenShare() async {
    setState(() {
      _isScreenSharing = !_isScreenSharing;
    });

    try {
      final videoService = context.read<VideoConsultationService>();
      await videoService.updateParticipantStatus(
        widget.consultationId,
        'current_user_id',
        screenSharing: _isScreenSharing,
      );
    } catch (e) {
      debugPrint('Error toggling screen share: $e');
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      final videoService = context.read<VideoConsultationService>();
      videoService.sendMessage(widget.consultationId, 'current_user_id', message);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Video Consultation'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_consultation == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Video Consultation'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Consultation not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main video area
            _buildVideoArea(),
            
            // Top bar
            _buildTopBar(),
            
            // Bottom controls
            _buildBottomControls(),
            
            // Chat overlay
            if (_isChatVisible) _buildChatOverlay(),
            
            // Connection quality indicator
            _buildConnectionIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoArea() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // Main video (doctor's view for patient, patient's view for doctor)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isDoctor ? _consultation!.patientName : _consultation!.doctorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isVideoEnabled ? 'Video On' : 'Video Off',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Self video (picture-in-picture)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isVideoEnabled ? Icons.person : Icons.person_off,
                      size: 32,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Participants list (if more than 2)
          if (_participants.length > 2)
            Positioned(
              left: 20,
              top: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Participants',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._participants.take(5).map((participant) => Text(
                      participant.name,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    )),
                    if (_participants.length > 5)
                      Text(
                        '+${_participants.length - 5} more',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isDoctor ? _consultation!.patientName : _consultation!.doctorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _consultation!.statusDisplayText,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (_consultation!.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Audio toggle
                _buildControlButton(
                  icon: _isAudioEnabled ? Icons.mic : Icons.mic_off,
                  isActive: _isAudioEnabled,
                  onPressed: _toggleAudio,
                ),
                
                // Video toggle
                _buildControlButton(
                  icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                  isActive: _isVideoEnabled,
                  onPressed: _toggleVideo,
                ),
                
                // Screen share
                _buildControlButton(
                  icon: _isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
                  isActive: _isScreenSharing,
                  onPressed: _toggleScreenShare,
                ),
                
                // Chat
                _buildControlButton(
                  icon: Icons.chat,
                  isActive: _isChatVisible,
                  onPressed: () {
                    setState(() {
                      _isChatVisible = !_isChatVisible;
                    });
                  },
                  badge: _messages.length,
                ),
                
                // End call
                _buildControlButton(
                  icon: Icons.call_end,
                  isActive: false,
                  onPressed: widget.isDoctor ? _endConsultation : () => Navigator.of(context).pop(),
                  backgroundColor: Colors.red,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            if (!_consultation!.isActive && _consultation!.canStart)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.isDoctor ? _startConsultation : _joinConsultation,
                      icon: const Icon(Icons.video_call),
                      label: Text(widget.isDoctor ? 'Start Consultation' : 'Join Consultation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    Color? backgroundColor,
    int? badge,
  }) {
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor ?? (isActive ? AppTheme.primaryColor : Colors.white24),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        if (badge != null && badge > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                badge.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChatOverlay() {
    return Positioned(
      right: 0,
      top: 80,
      bottom: 120,
      width: 300,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Chat header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isChatVisible = false;
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.all(8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isOwnMessage = message.senderId == 'current_user_id';
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: isOwnMessage 
                          ? MainAxisAlignment.end 
                          : MainAxisAlignment.start,
                      children: [
                        if (!isOwnMessage) ...[
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              message.senderName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isOwnMessage 
                                  ? AppTheme.primaryColor 
                                  : Colors.white12,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isOwnMessage)
                                  Text(
                                    message.senderName,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                Text(
                                  message.message,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Message input
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    Color indicatorColor;
    String indicatorText;
    
    switch (_connectionQuality) {
      case ConnectionQuality.excellent:
        indicatorColor = Colors.green;
        indicatorText = 'Excellent';
        break;
      case ConnectionQuality.good:
        indicatorColor = Colors.green;
        indicatorText = 'Good';
        break;
      case ConnectionQuality.fair:
        indicatorColor = Colors.orange;
        indicatorText = 'Fair';
        break;
      case ConnectionQuality.poor:
        indicatorColor = Colors.red;
        indicatorText = 'Poor';
        break;
      case ConnectionQuality.disconnected:
        indicatorColor = Colors.red;
        indicatorText = 'Disconnected';
        break;
    }
    
    return Positioned(
      top: 80,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              indicatorText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndConsultationDialog extends StatefulWidget {
  @override
  State<_EndConsultationDialog> createState() => _EndConsultationDialogState();
}

class _EndConsultationDialogState extends State<_EndConsultationDialog> {
  final _notesController = TextEditingController();
  final _prescriptionController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('End Consultation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Consultation Notes',
                hintText: 'Enter your notes about this consultation...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _prescriptionController,
              decoration: const InputDecoration(
                labelText: 'Prescription (Optional)',
                hintText: 'Enter prescription details...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'notes': _notesController.text.trim(),
              'prescription': _prescriptionController.text.trim(),
            });
          },
          child: const Text('End Consultation'),
        ),
      ],
    );
  }
}

