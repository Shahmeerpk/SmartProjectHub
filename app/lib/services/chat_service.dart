import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:signalr_netcore/signalr_client.dart';

class ChatService {
  static const String baseUrl = 'http://192.168.100.62:5264'; // Apna IP theek rakhna
  
  HubConnection? _hubConnection;

 // 1. Channels mangwana (Ab User ID aur Role bhi sath jayega)
  Future<List<dynamic>> getChannels(int userId, String role) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/chat/channels/$userId/$role'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('🚨 Channels fetch error: $e');
      return [];
    }
  }
  // 1.5 Chat History (Purane Messages) Mangwana
  // 1.5 Chat History (Purane Messages) Mangwana
  Future<List<Map<String, dynamic>>> getChatHistory(int channelId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/chat/$channelId/messages'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((m) => {
          'userId': m['userId'].toString(),
          'text': m['text'].toString(),
          'senderName': m['senderName']?.toString() ?? 'Unknown', // 🔥 NAYA
          'dpUrl': m['dpUrl']?.toString(), // 🔥 NAYA
        }).toList();
      }
      return [];
    } catch (e) {
      print('🚨 History fetch error: $e');
      return [];
    }
  }
  // NAYA: Project ke liye Chat Room mangwana
  Future<Map<String, dynamic>?> getOrCreateProjectChat(int projectId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/api/chat/project/$projectId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('🚨 Project Chat fetch error: $e');
      return null;
    }
  }

  // 2. SignalR Connect karna
  Future<void> connectToSignalR(Function(List<dynamic>) onMessageReceived) async {
    final hubUrl = '$baseUrl/chathub';
    
    _hubConnection = HubConnectionBuilder()
        .withUrl(hubUrl)
        .build();

    // C# se ReceiveMessage aane par (Ab C# sirf userId aur content bhej raha hai)
    _hubConnection?.on('ReceiveMessage', (arguments) {
      if (arguments != null) {
        onMessageReceived(arguments);
      }
    });

    try {
      await _hubConnection?.start();
      print('✅ SignalR Connected Successfully!');
    } catch (e) {
      print('🚨 SignalR Connection Error: $e');
    }
  }

  // 3. Channel Group Join karna (C# ke naye code ke mutabiq)
  Future<void> joinChannel(int channelId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke('JoinChannel', args: [channelId]); // int ja raha hai
    }
  }

  // 4. Message bhejna (Ab String ki jagah INT bhejenge!)
  Future<void> sendMessage(int channelId, int userId, String text) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      // Yahan types bilkul C# se match kar rahi hain [int, int, string]
      await _hubConnection?.invoke('SendMessage', args: [channelId, userId, text]);
    } else {
      print('🚨 SignalR is not connected!');
    }
  }
}