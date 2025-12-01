// lib/views/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = AuthService();
  int _convos = 0;
  String _lastActive = '--';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final list = await _service.getArchivedConversations();
    setState(() {
      _convos = list.length;
      _lastActive = list.isEmpty ? '--' : (list.first['createdAt'] ?? '--').toString().split('T').first;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text('Conversations archived'),
                trailing: Text('$_convos'),
              ),
            ),
            const SizedBox(height: 8),
            Card(child: ListTile(title: const Text('Last active'), trailing: Text(_lastActive))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadStats, child: const Text('Refresh')),
          ],
        ),
      ),
    );
  }
}
