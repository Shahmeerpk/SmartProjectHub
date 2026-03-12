import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

class MessageScreen extends StatefulWidget {
  final int channelId;
  final String channelName;

  const MessageScreen({super.key, required this.channelId, required this.channelName});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<AuthService>().user?.id.toString() ?? '';
    _initChat();
  }

  Future<void> _initChat() async {
    // 1. Purani chat history DB se mangwao
    final history = await _chatService.getChatHistory(widget.channelId);
    if (mounted) {
      setState(() {
        _messages = history;
        _isLoading = false;
      });
      _scrollToBottom();
    }

    // 2. SignalR se Live messages suno
    await _chatService.connectToSignalR((args) {
      if (mounted) {
        final incomingUserId = args[0].toString();
        final incomingText = args[1].toString();
        
        // 🔥 JADOO: Agar yeh message maine khud hi bheja hai, tou dobara add mat karo (Duplicate se bachao)
        if (incomingUserId == _currentUserId) return;

        setState(() {
          _messages.add({
            'userId': incomingUserId,
            'text': incomingText,
            'senderName': args.length > 2 ? args[2]?.toString() ?? 'Unknown' : 'Unknown',
            'dpUrl': args.length > 3 ? args[3]?.toString() : null,
          });
        });
        _scrollToBottom();
      }
    });

    // 3. Channel Join karo
    await _chatService.joinChannel(widget.channelId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    
    final text = _controller.text.trim();
    _controller.clear();
    
    final authUser = context.read<AuthService>().user;
    final userId = int.tryParse(_currentUserId) ?? 0;
    
    // 🔥 SUPER JADOO: Send dabate hi FORAN screen par message dikha do (0 seconds delay)
    setState(() {
      _messages.add({
        'userId': _currentUserId,
        'text': text,
        'senderName': authUser?.fullName ?? 'Me',
        'dpUrl': authUser?.profilePictureUrl,
      });
    });
    _scrollToBottom();
    
    // Phir sakoon se server ko background mein bhejte raho
    await _chatService.sendMessage(widget.channelId, userId, text);
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    final serverBaseUrl = api.baseUrl.replaceAll('/api', '');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channelName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg['userId'] == _currentUserId;
                    final senderName = msg['senderName'] ?? 'Unknown';
                    
                    String? dpUrl = msg['dpUrl'];
                    if (dpUrl != null && !dpUrl.startsWith('http')) {
                      dpUrl = '$serverBaseUrl$dpUrl';
                    }

                    return _buildMessageBubble(msg['text'], isMe, senderName, dpUrl);
                  },
                ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String senderName, String? dpUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
              backgroundImage: dpUrl != null ? NetworkImage(dpUrl) : null,
              child: dpUrl == null ? const Icon(Icons.person, size: 16, color: AppTheme.primary) : null,
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      senderName,
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ),
                  
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                      bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
              backgroundImage: dpUrl != null ? NetworkImage(dpUrl) : null,
              child: dpUrl == null ? const Icon(Icons.person, size: 16, color: AppTheme.primary) : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), 
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}