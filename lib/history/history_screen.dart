// lib/views/history/history_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../conversation/conversation_view.dart';

class HistoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> archives;
  const HistoryScreen({super.key, this.archives = const []});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _service = AuthService();
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.archives.isNotEmpty) {
      _items = List.of(widget.archives);
      _applyFilter();
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final archived = await _service.getArchivedConversations();
    setState(() {
      _items = archived;
      _applyFilter();
      _loading = false;
    });
  }

  void _applyFilter() {
    if (_query.trim().isEmpty) {
      _filtered = List.of(_items);
    } else {
      final q = _query.toLowerCase();
      _filtered = _items.where((m) {
        final title = (m['title']?.toString() ?? '').toLowerCase();
        final snippet = ((m['messages'] as List<dynamic>?)?.isNotEmpty == true ? (m['messages'] as List).last['text'] ?? '' : '').toString().toLowerCase();
        return title.contains(q) || snippet.contains(q);
      }).toList();
    }
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text('This will remove all archived conversations.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) {
      await _service.clearArchivedConversations();
      await _load();
    }
  }

  Future<void> _deleteSingle(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: const Text('This will permanently delete the selected conversation.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      _items.removeWhere((m) => m['id'] == id);
      await _service.clearArchivedConversations();
      for (final it in _items.reversed) {
        await _service.archiveConversation(it);
      }
      await _load();
    }
  }

  Future<void> _rename(String id) async {
    final idx = _items.indexWhere((m) => m['id'] == id);
    if (idx < 0) return;
    final controller = TextEditingController(text: _items[idx]['title']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Rename conversation'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      _items[idx]['title'] = controller.text.trim().isEmpty ? 'Conversation' : controller.text.trim();
      await _service.clearArchivedConversations();
      for (final it in _items.reversed) {
        await _service.archiveConversation(it);
      }
      await _load();
    }
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return const Center(child: Text('No archived conversations match your search.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, i) {
        final item = _filtered[i];
        final created = item['createdAt'] ?? '';
        final messages = (item['messages'] as List<dynamic>?) ?? [];
        final snippet = messages.isNotEmpty ? (messages.last['text'] ?? '') : '';
        return ListTile(
          title: Text(item['title']?.toString() ?? 'Conversation'),
          subtitle: Text(snippet.toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(created.toString().split('T').first),
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _rename(item['id']?.toString() ?? ''), tooltip: 'Rename'),
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteSingle(item['id']?.toString() ?? ''), tooltip: 'Delete'),
          ]),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConversationView(conversation: item))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation History'),
        actions: [IconButton(onPressed: _clearAll, icon: const Icon(Icons.delete_forever))],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search history (title or text)…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { _query = ''; _applyFilter(); })) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (v) => setState(() { _query = v; _applyFilter(); }),
            ),
          ),
        ),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _buildList(),
    );
  }
}
