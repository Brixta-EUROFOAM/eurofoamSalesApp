import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'employee_salesorder_screen.g.dart';

@HiveType(typeId: 0)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final String role;

  ChatMessage({required this.text, required this.role});
}

class SalesOrderScreen extends StatefulWidget {
  final Employee employee;
  const SalesOrderScreen({super.key, required this.employee});

  @override
  State<SalesOrderScreen> createState() => _SalesOrderScreenState();
}

class _SalesOrderScreenState extends State<SalesOrderScreen> {
  // --- (All your logic remains unchanged) ---
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  
  late IO.Socket _socket;
  bool _isConnected = false;
  bool _isLoading = false;

  late Box<ChatMessage> _chatBox;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    if (!Hive.isAdapterRegistered(0)) {
       Hive.registerAdapter(ChatMessageAdapter());
    }
    _chatBox = await Hive.openBox<ChatMessage>('sales_order_chat');
    if (mounted) {
      setState(() {
        _messages.addAll(_chatBox.values.toList().reversed);
      });
    }
    _connectToSocket();
  }

  void _connectToSocket() {
    const socketUrl = 'https://python-ai-agent.onrender.com';
    _socket = IO.io(socketUrl, <String, dynamic>{
      'path': '/socket.io',
      'transports': ['websocket', 'polling'], 
      'autoConnect': false,
    });
    _socket.connect();
    _socket.onConnect((_) {
      debugPrint('Socket connected');
      if(mounted) setState(() => _isConnected = true);
    });
    _socket.onDisconnect((_) {
      debugPrint('Socket disconnected');
      if(mounted) setState(() => _isConnected = false);
    });
    _socket.on('connect_error', (data) => debugPrint('Connect Error: $data'));
    _socket.on('error', (data) => debugPrint('Socket Error: $data'));
    _socket.on('ready', (_) {
       if (_messages.isEmpty) {
         _addMessage(
           text: "Hello! I'm CemTemBot, ready to assist. What can I get for you?",
           role: 'assistant'
         );
       }
    });
    _socket.on('status', (data) {
      if (data is Map && data['typing'] is bool) {
        if(mounted) setState(() => _isLoading = data['typing']);
      }
    });
    _socket.on('bot_message', (data) {
      if (data is Map && data['text'] is String) {
        _addMessage(text: data['text'], role: 'assistant');
      }
       if(mounted) setState(() => _isLoading = false);
    });
  }

  void _addMessage({required String text, required String role}) {
    final message = ChatMessage(text: text, role: role);
    _chatBox.add(message);
    if (mounted) {
      setState(() {
        _messages.insert(0, message);
      });
    }
    _scrollToBottom();
  }
  
  void _handleSubmitted(String text) {
    if (text.trim().isEmpty || !_isConnected) return;
    _textController.clear();
    _addMessage(text: text, role: 'user');
    if(mounted) {
      setState(() {
        _isLoading = true;
      });
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: _messages.length,
              itemBuilder: (_, int index) => _ChatMessageBubble(message: _messages[index]),
            ),
          ),
          if (_isLoading) const _TypingIndicator(),
          _buildTextComposer(),
          
          // This padding adds space for your floating nav bar
          const SizedBox(height: 80), 
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final theme = Theme.of(context);
    
    // --- ✅ CRITIQUE #1: Using primary color (2-shade) ---
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      color: theme.colorScheme.primary, 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.support_agent, color: theme.colorScheme.onPrimary, size: 16),
          const SizedBox(width: 8),
          Text(
            "CemTemBot Status:",
            style: TextStyle(color: theme.colorScheme.onPrimary.withOpacity(0.8), fontSize: 12),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // --- ✅ CRITIQUE #8: Softer Colors ---
              color: _isConnected ? const Color(0xFF4CAF50) : const Color(0xFFE57373),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _isConnected ? "Connected" : "Disconnected",
            style: TextStyle(
                color: _isConnected ? const Color(0xFF4CAF50) : const Color(0xFFE57373),
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: theme.scaffoldBackgroundColor, 
      child: Card(
        // --- ✅ CRITIQUE #5: Create a single capsule ---
        // We use a Card as the capsule container
        elevation: 0,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
          side: theme.brightness == Brightness.light
              ? BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.1))
              : BorderSide.none
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration(
                  hintText: _isConnected ? 'Type your order...' : 'Connecting...',
                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  // Remove all internal borders
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false, // The card handles the fill
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                style: TextStyle(color: theme.colorScheme.onSurface),
                enabled: _isConnected,
              ),
            ),
            IconButton(
              // --- ✅ CRITIQUE #6: Use filled icon ---
              icon: Icon(Icons.send, 
                color: _isConnected ? theme.colorScheme.secondary : theme.disabledColor
              ),
              onPressed: _isConnected ? () => _handleSubmitted(_textController.text) : null,
            ),
          ],
        ),
      ),
    ).animate().slide(begin: const Offset(0, 0.5), duration: 200.ms, curve: Curves.easeOut);
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
      // --- ✅ CRITIQUE #10: Consistent spacing ---
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      // --- END FIX ---
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundColor: theme.colorScheme.surface, 
              child: Icon(Icons.support_agent, color: theme.colorScheme.onSurface),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              child: Container(
                // --- ✅ CRITIQUE #4: Add +4px padding ---
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: isUser
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  // --- ✅ CRITIQUE #9: Consistent 16px corners ---
                  borderRadius: isUser
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(16.0),
                          bottomLeft: Radius.circular(16.0),
                          topRight: Radius.circular(16.0),
                        )
                      : const BorderRadius.only(
                          topRight: Radius.circular(16.0),
                          bottomRight: Radius.circular(16.0),
                          topLeft: Radius.circular(16.0),
                        ),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                    fontSize: 16,
                    // --- ✅ CRITIQUE #3: Increased line height ---
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondary,
              child: Icon(Icons.person, color: theme.colorScheme.onSecondary),
            ),
          ]
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.5, end: 0);
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.surface,
            child: Icon(Icons.support_agent, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              // --- ✅ CRITIQUE #9: Consistent 16px corners ---
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16.0),
                bottomRight: Radius.circular(16.0),
                topLeft: Radius.circular(16.0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0, theme),
                const SizedBox(width: 5),
                _buildDot(1, theme),
                const SizedBox(width: 5),
                _buildDot(2, theme),
              ],
            ),
          ),
        ],
      ),
    ).animate(onComplete: (c) => c.repeat()).shimmer(duration: 1200.ms);
  }

  Widget _buildDot(int index, ThemeData theme) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.7),
        shape: BoxShape.circle,
      ),
    ).animate().scaleY(
      delay: (index * 200).ms,
      duration: 400.ms,
      curve: Curves.easeInOut,
    ).then(delay: 800.ms).scaleY(
      duration: 400.ms,
      curve: Curves.easeInOut,
    );
  }
}
