import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/message.dart';
import '../../repositories/chat_repository.dart';
import '../../presenters/chat_presenter.dart';
import 'chat_view_contract.dart'; // This line should already be correct
import '../../widgets/message_bubble.dart';
import '../../widgets/message_input.dart';
import '../../widgets/legal_resources_panel.dart';
import '../../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> implements ChatViewContract {
  late final ChatPresenter _presenter;
  final List<Message> _messages = [];
  bool _loading = false;
  bool _showTypingIndicator = false;
  List<String> _quickReplies = [];
  bool _initialized = false;
  bool _showResourcesPanel = true;

  final ScrollController _scrollController = ScrollController();
  static const String _storageKey = 'conversation_json';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    final ChatRepository repo = Provider.of<ChatRepository>(context, listen: false);
    _presenter = ChatPresenter(view: this, repository: repo);

    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final bool loaded = await _loadSavedConversation();
    if (!loaded && mounted) {
      try {
        _presenter.loadInitialMessages();
      } catch (e) {
        _showError('Failed to load initial messages: $e');
      }
    }
  }

  Future<bool> _loadSavedConversation() async {
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      final String? jsonStr = sp.getString(_storageKey);

      if (jsonStr == null) return false;

      final List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
      final List<Message> items = list
          .map((dynamic e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return true;

      setState(() {
        _messages.clear();
        _messages.addAll(items.reversed);
        _showResourcesPanel = _messages.isEmpty;
      });

      _scrollToBottom();
      return true;
    } catch (e) {
      debugPrint('Error loading conversation: $e');
      return false;
    }
  }

  Future<void> _saveConversation() async {
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList =
      _messages.reversed.map((Message m) => m.toJson()).toList();
      await sp.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving conversation: $e');
    }
  }

  Future<void> _archiveConversation() async {
    if (_messages.isEmpty) {
      _showSnackBar('No messages to save.');
      return;
    }

    final Map<String, dynamic> conv = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': _getConversationTitle(),
      'createdAt': DateTime.now().toIso8601String(),
      'messages': _messages.reversed.map((Message m) => m.toJson()).toList(),
    };

    try {
      await AuthService().archiveConversation(conv);
      _showSnackBar('Conversation saved to history.');
    } catch (e) {
      _showSnackBar('Failed to save conversation.');
      debugPrint('Archive error: $e');
    }
  }

  String _getConversationTitle() {
    if (_messages.isEmpty) return 'Conversation';

    final String firstMessage = _messages.first.text;
    return firstMessage.length > 60
        ? '${firstMessage.substring(0, 60)}...'
        : firstMessage;
  }

  Future<void> _shareConversation() async {
    if (_messages.isEmpty) {
      _showSnackBar('No messages to share.');
      return;
    }

    final String jsonStr = json.encode(
        _messages.reversed.map((Message m) => m.toJson()).toList()
    );

    await Clipboard.setData(ClipboardData(text: jsonStr));
    _showSnackBar('Conversation JSON copied to clipboard.');
  }

  // ChatViewContract implementation
  @override
  void showLoading(bool loading) {
    if (!mounted) return;
    setState(() {
      _loading = loading;
      _showTypingIndicator = loading;
    });
  }

  @override
  void showMessages(List<Message> messages) {
    if (!mounted) return;
    setState(() {
      _messages.clear();
      _messages.addAll(messages.reversed);
      _showResourcesPanel = false;
    });
    _scrollToBottom();
    _saveConversation();
  }

  @override
  void appendMessage(Message message) {
    if (!mounted) return;
    setState(() {
      _messages.insert(0, message);
      _showResourcesPanel = false;
      _showTypingIndicator = false;
    });
    _scrollToBottom();
    _saveConversation();
  }

  @override
  void removeMessageById(String id) {
    if (!mounted) return;
    setState(() => _messages.removeWhere((Message m) => m.id == id));
    _saveConversation();
  }

  @override
  void showError(String message) {
    _showError(message);
  }

  @override
  void showQuickReplies(List<String> options) {
    if (!mounted) return;
    setState(() => _quickReplies = options);
  }

  void _onSend(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _quickReplies = [];
      _showResourcesPanel = false;
    });
    _presenter.sendUserMessage(text.trim());
  }

  void _onQuickReply(String option) {
    setState(() => _quickReplies = []);
    _presenter.sendUserMessage(option);
  }

  void _onResourceSelected(String resource) {
    _onSend("I need help with $resource");
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildQuickReplies() {
    if (_quickReplies.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Replies',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickReplies.map((String q) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(q),
                    onSelected: (_) => _onQuickReply(q),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    if (!_showTypingIndicator) return const SizedBox.shrink();

    return MessageBubble(
      message: Message(
        text: '...',
        sender: Sender.bot, // Changed from assistant to bot
        createdAt: DateTime.now(),
      ),
      isTyping: true,
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty && !_showTypingIndicator) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Welcome to Legal Assistant',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'How can I help with your legal matters today?',
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: _messages.length + (_showTypingIndicator ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index == 0 && _showTypingIndicator) {
          return _buildTypingIndicator();
        }

        final int messageIndex = _showTypingIndicator ? index - 1 : index;
        final Message message = _messages[messageIndex];
        final bool isUser = message.sender == Sender.user;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              MessageBubble(
                message: message,
                showStatus: isUser,
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _formatTime(message.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dt);

    if (difference.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
  }

  Future<void> _clearConversation() async {
    final bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Clear Conversation?'),
        content: const Text('This will remove all messages from this conversation. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldClear == true && mounted) {
      setState(() {
        _messages.clear();
        _showResourcesPanel = true;
      });
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.remove(_storageKey);
      _showSnackBar('Conversation cleared.');
    }
  }

  @override
  void dispose() {
    _saveConversation();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal Assistant'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'dashboard',
                child: ListTile(
                  leading: Icon(Icons.dashboard),
                  title: Text('Dashboard'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'history',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('History'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'save',
                child: ListTile(
                  leading: Icon(Icons.save_alt),
                  title: Text('Save Conversation'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share'),
                ),
              ),
              if (_showResourcesPanel)
                const PopupMenuItem<String>(
                  value: 'hide_resources',
                  child: ListTile(
                    leading: Icon(Icons.visibility_off),
                    title: Text('Hide Resources'),
                  ),
                )
              else
                const PopupMenuItem<String>(
                  value: 'show_resources',
                  child: ListTile(
                    leading: Icon(Icons.visibility),
                    title: Text('Show Resources'),
                  ),
                ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'clear',
                child: ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Clear Conversation',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
            onSelected: (String value) {
              switch (value) {
                case 'dashboard':
                  _showDashboard();
                  break;
                case 'history':
                  _showHistory();
                  break;
                case 'save':
                  _archiveConversation();
                  break;
                case 'share':
                  _shareConversation();
                  break;
                case 'hide_resources':
                  setState(() => _showResourcesPanel = false);
                  break;
                case 'show_resources':
                  setState(() => _showResourcesPanel = true);
                  break;
                case 'clear':
                  _clearConversation();
                  break;
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            if (_loading)
              const LinearProgressIndicator(minHeight: 2),
            _buildQuickReplies(),
            if (_showResourcesPanel && _messages.isEmpty)
              LegalResourcesPanel(onResourceSelected: _onResourceSelected),
            MessageInput(onSend: _onSend),
          ],
        ),
      ),
    );
  }

  Future<void> _showDashboard() async {
    try {
      final List<dynamic> archived = await AuthService().getArchivedConversations();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext c) => AlertDialog(
          title: const Text('Dashboard'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Conversations archived'),
                trailing: Text('${archived.length}'),
              ),
              ListTile(
                title: const Text('Last active'),
                trailing: Text(
                  archived.isEmpty
                      ? '--'
                      : _formatDisplayDate(archived.first['createdAt']?.toString()),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Failed to load dashboard: $e');
    }
  }

  Future<void> _showHistory() async {
    try {
      final List<dynamic> list = await AuthService().getArchivedConversations();
      if (!mounted) return;

      if (list.isEmpty) {
        _showSnackBar('No archived conversations');
        return;
      }

      showDialog(
        context: context,
        builder: (BuildContext c) {
          return AlertDialog(
            title: const Text('Archived Conversations'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (BuildContext context, int i) {
                  final dynamic item = list[i];
                  final String title = item['title']?.toString() ?? 'Conversation';
                  final String created = _formatDisplayDate(item['createdAt']?.toString());

                  return ListTile(
                    title: Text(title),
                    subtitle: Text(created),
                    onTap: () => _showConversationDetails(item, title),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      _showError('Failed to load history: $e');
    }
  }

  void _showConversationDetails(dynamic item, String title) {
    Navigator.pop(context); // Close history dialog first

    showDialog(
      context: context,
      builder: (BuildContext c2) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: (item['messages'] as List<dynamic>? ?? []).length,
            itemBuilder: (BuildContext ctx, int idx) {
              final dynamic m = (item['messages'] as List<dynamic>)[idx];
              final Map<String, dynamic> messageMap = Map<String, dynamic>.from(m as Map);
              final String text = messageMap['text']?.toString() ?? '';
              final String sender = messageMap['sender']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sender == 'user'
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(text),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c2),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDisplayDate(String? dateString) {
    if (dateString == null) return '--';
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return '--';
    }
  }
}