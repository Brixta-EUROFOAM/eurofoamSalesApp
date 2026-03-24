import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:salesmanapp/salesSide/models/employee_model.dart';

class ChatMessage {
  final String text;
  final String role;

  ChatMessage({required this.text, required this.role});

  Map<String, dynamic> toJson() => {
        'text': text,
        'role': role,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      role: json['role'] as String,
    );
  }
}

class SalesOrderScreen extends StatefulWidget {
  final Employee employee;
  const SalesOrderScreen({super.key, required this.employee});

  @override
  State<SalesOrderScreen> createState() => _SalesOrderScreenState();
}

class _SalesOrderScreenState extends State<SalesOrderScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  late IO.Socket _socket;
  late SharedPreferences _prefs;

  bool _isConnected = false;
  bool _isLoading = false;

  static const String _chatStorageKey = 'sales_order_chat';

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    _prefs = await SharedPreferences.getInstance();

    final stored = _prefs.getString(_chatStorageKey);
    if (stored != null) {
      final List decoded = jsonDecode(stored);
      _messages.addAll(
        decoded
            .map((e) => ChatMessage.fromJson(e))
            .toList()
            .reversed,
      );
    }

    if (mounted) setState(() {});
    _connectToSocket();
  }

  void _connectToSocket() {
    const socketUrl = 'https://python-ai-agent.onrender.com';

    _socket = IO.io(
      socketUrl,
      <String, dynamic>{
        'path': '/socket.io',
        'transports': ['websocket', 'polling'],
        'autoConnect': false,
      },
    );

    _socket.connect();

    _socket.onConnect((_) {
      if (mounted) setState(() => _isConnected = true);
    });

    _socket.onDisconnect((_) {
      if (mounted) setState(() => _isConnected = false);
    });

    _socket.on('ready', (_) {
      if (_messages.isEmpty) {
        _addMessage(
          text: "Hello! I'm CemTemBot, ready to assist. What can I get for you?",
          role: 'assistant',
        );
      }
    });

    _socket.on('status', (data) {
      if (data is Map && data['typing'] is bool) {
        if (mounted) setState(() => _isLoading = data['typing']);
      }
    });

    _socket.on('bot_message', (data) {
      if (data is Map && data['text'] is String) {
        _addMessage(text: data['text'], role: 'assistant');
      }
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _addMessage({required String text, required String role}) {
    final message = ChatMessage(text: text, role: role);

    if (mounted) {
      setState(() {
        _messages.insert(0, message);
      });
    }

    _persistMessages();
    _scrollToBottom();
  }

  void _persistMessages() {
    final jsonList = _messages
        .reversed
        .map((m) => m.toJson())
        .toList();

    _prefs.setString(_chatStorageKey, jsonEncode(jsonList));
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty || !_isConnected) return;

    _textController.clear();
    _addMessage(text: text, role: 'user');

    if (mounted) setState(() => _isLoading = true);
    _socket.emit('send_message', {'text': text});
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildStatusBanner(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (_, i) =>
                  _ChatMessageBubble(message: _messages[i]),
            ),
          ),
          if (_isLoading) const _TypingIndicator(),
          _buildTextComposer(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: theme.colorScheme.primary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.support_agent,
              color: theme.colorScheme.onPrimary, size: 16),
          const SizedBox(width: 8),
          Text(
            "CemTemBot Status:",
            style: TextStyle(
              color: theme.colorScheme.onPrimary.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isConnected
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFE57373),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _isConnected ? "Connected" : "Disconnected",
            style: TextStyle(
              color: _isConnected
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFE57373),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.scaffoldBackgroundColor,
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: theme.brightness == Brightness.light
              ? BorderSide(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                )
              : BorderSide.none,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                enabled: _isConnected,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration(
                  hintText:
                      _isConnected ? 'Type your order...' : 'Connecting...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.send,
                color: _isConnected
                    ? theme.colorScheme.secondary
                    : theme.disabledColor,
              ),
              onPressed: _isConnected
                  ? () => _handleSubmitted(_textController.text)
                  : null,
            ),
          ],
        ),
      ),
    ).animate().slide(begin: const Offset(0, 0.5), duration: 200.ms);
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundColor: theme.colorScheme.surface,
              child: Icon(Icons.support_agent,
                  color: theme.colorScheme.onSurface),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3);
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.surface,
            child: Icon(Icons.support_agent,
                color: theme.colorScheme.onSurface),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate()
                      .scaleY(
                        delay: (i * 200).ms,
                        duration: 400.ms,
                      )
                      .then(delay: 800.ms)
                      .scaleY(duration: 400.ms),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate(onComplete: (c) => c.repeat()).shimmer(duration: 1200.ms);
  }
}
