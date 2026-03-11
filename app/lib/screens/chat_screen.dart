import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'message_screen.dart'; // Message screen ka link
import '../widgets/glass_card.dart';
import '../widgets/neumorphic_card.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatService _chatService = ChatService(); 
  List<dynamic> _channels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChannels(); 
  }

  Future<void> _loadChannels() async {
    final data = await _chatService.getChannels();
    setState(() {
      _channels = data;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F4F8), Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  'Messages',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                tabs: const [
                  Tab(text: 'Private'),
                  Tab(text: 'University'),
                  Tab(text: 'Global'),
                ],
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator()) 
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildChannelList(context, 'Private'),
                          _buildChannelList(context, 'University'),
                          _buildChannelList(context, 'Global'),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelList(BuildContext context, String tabType) {
    final filteredChannels = _channels.where((c) => c['channelType'] == tabType).toList();

    if (filteredChannels.isEmpty) {
      return Center(
        child: Text(
          tabType == 'Private' ? "No active chats yet." : "No $tabType channels found.",
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: filteredChannels.length,
      itemBuilder: (context, index) {
        final channel = filteredChannels[index];
        bool isPrivate = tabType == 'Private';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NeumorphicCard(
            child: ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: isPrivate ? Colors.blue.withValues(alpha: 0.1) : AppTheme.primary.withValues(alpha: 0.2),
                child: Icon(
                  isPrivate ? Icons.person : Icons.tag, 
                  color: isPrivate ? Colors.blue : AppTheme.primary,
                ), 
              ),
              title: Text(
                channel['name'] ?? 'Unknown', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              ),
              subtitle: Text(
                isPrivate ? 'Tap to view messages...' : 'Active group chat',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              trailing: isPrivate ? const Icon(Icons.chevron_right, color: Colors.grey) : null,
              onTap: () {
                // Jab tap karein toh MessageScreen par bhejein
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessageScreen(
                      channelId: channel['id'],
                      channelName: channel['name'],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}