import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

class MessageScreen extends StatefulWidget {
  final int channelId;
  final String channelName;

  const MessageScreen({
    super.key, 
    required this.channelId, 
    required this.channelName
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryAndConnect();
  }

  Future<void> _loadHistoryAndConnect() async {
    // 1. Purani history mangwa kar list mein daalo
    final history = await _chatService.getChatHistory(widget.channelId);
    if (mounted) {
      setState(() {
        _messages.addAll(history); 
      });
    }

    // 2. Naye (Live) messages ke liye SignalR connect karo
    _chatService.connectToSignalR((arguments) {
      if (arguments.isNotEmpty) {
        setState(() {
          _messages.add({
            'userId': arguments[0].toString(),
            'text': arguments[1].toString(),
          });
        });
      }
    }).then((_) {
      _chatService.joinChannel(widget.channelId);
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return; 

    final auth = context.read<AuthService>().user;
    final int userId = auth?.id ?? 1;

    _chatService.sendMessage(widget.channelId, userId, text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>().user;
    final currentUserId = auth?.id.toString() ?? "1";

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channelName),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['userId'] == currentUserId;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? AppTheme.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}