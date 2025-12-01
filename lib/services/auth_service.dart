// lib/services/auth_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final String id;
  final String email;
  final String name;

  AuthUser({required this.id, required this.email, required this.name});
}

class AuthService {
  static const _kTokenKey = 'auth_token';
  static const _kUserEmail = 'auth_email';
  static const _kUserName = 'auth_name';
  static const _kUsersKey = 'registered_users';
  static const _kConversationsArchive = 'conversations_archive';

  AuthService();

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>> _loadUsersMap() async {
    final sp = await SharedPreferences.getInstance();
    final jsonStr = sp.getString(_kUsersKey);
    if (jsonStr == null || jsonStr.isEmpty) return <String, dynamic>{};
    try {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return map;
    } catch (_) {
      await sp.remove(_kUsersKey);
      return <String, dynamic>{};
    }
  }

  Future<void> _saveUsersMap(Map<String, dynamic> m) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUsersKey, json.encode(m));
  }

  Future<bool> isEmailRegistered(String email) async {
    final users = await _loadUsersMap();
    return users.containsKey(email.toLowerCase());
  }

  Future<String> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (name.trim().isEmpty) throw Exception('Name is required');
    if (!normalizedEmail.contains('@')) throw Exception('Invalid email');
    if (password.length < 4) throw Exception('Password too short');

    final users = await _loadUsersMap();
    if (users.containsKey(normalizedEmail)) {
      throw Exception('An account for this email already exists.');
    }

    final passHash = _hashPassword(password);
    final createdAt = DateTime.now().toIso8601String();
    users[normalizedEmail] = {
      'name': name.trim(),
      'passwordHash': passHash,
      'createdAt': createdAt,
    };

    await _saveUsersMap(users);

    final token = 'token_${normalizedEmail.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kTokenKey, token);
    await sp.setString(_kUserEmail, normalizedEmail);
    await sp.setString(_kUserName, name.trim());

    return token;
  }

  /// Modified signIn:
  /// - If registered: check password as before
  /// - If not registered AND email endsWith('@gmail.com'): auto-create account using the provided password and sign in
  /// - Otherwise: throw "No account found" as before
  Future<String> signIn({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();
    final users = await _loadUsersMap();

    if (users.containsKey(normalizedEmail)) {
      // existing behavior
      final record = users[normalizedEmail] as Map<String, dynamic>;
      final storedHash = (record['passwordHash'] ?? '') as String;
      final givenHash = _hashPassword(password);

      if (storedHash != givenHash) {
        throw Exception('Incorrect email or password.');
      }

      final token = 'token_${normalizedEmail.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kTokenKey, token);
      await sp.setString(_kUserEmail, normalizedEmail);
      await sp.setString(_kUserName, (record['name'] as String?) ?? normalizedEmail.split('@').first);

      return token;
    } else {
      // auto-register and sign in for any @gmail.com email
      if (normalizedEmail.endsWith('@gmail.com')) {
        final suggestedName = normalizedEmail.split('@').first;
        final passHash = _hashPassword(password);
        final createdAt = DateTime.now().toIso8601String();
        users[normalizedEmail] = {
          'name': suggestedName,
          'passwordHash': passHash,
          'createdAt': createdAt,
        };
        await _saveUsersMap(users);

        final token = 'token_${normalizedEmail.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
        final sp = await SharedPreferences.getInstance();
        await sp.setString(_kTokenKey, token);
        await sp.setString(_kUserEmail, normalizedEmail);
        await sp.setString(_kUserName, suggestedName);

        return token;
      }

      throw Exception('No account found for that email. Please sign up first.');
    }
  }

  Future<void> signOut() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kTokenKey);
    await sp.remove(_kUserEmail);
    await sp.remove(_kUserName);
  }

  Future<AuthUser?> currentUser() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString(_kTokenKey);
    if (token == null) return null;
    final email = sp.getString(_kUserEmail) ?? '';
    final name = sp.getString(_kUserName) ?? email.split('@').first;
    if (email.isEmpty) return null;
    return AuthUser(id: token, email: email, name: name);
  }

  Future<List<String>> registeredEmails() async {
    final users = await _loadUsersMap();
    return users.keys.toList();
  }

  Future<void> changeName(String email, String newName) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (newName.trim().isEmpty) throw Exception('Name is required');
    final users = await _loadUsersMap();
    if (!users.containsKey(normalizedEmail)) throw Exception('Account not found');
    final rec = users[normalizedEmail] as Map<String, dynamic>;
    rec['name'] = newName.trim();
    users[normalizedEmail] = rec;
    await _saveUsersMap(users);

    final sp = await SharedPreferences.getInstance();
    final current = sp.getString(_kUserEmail);
    if (current == normalizedEmail) {
      await sp.setString(_kUserName, newName.trim());
    }
  }

  Future<void> changePassword(String email, String oldPassword, String newPassword) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (newPassword.length < 4) throw Exception('New password too short');
    final users = await _loadUsersMap();
    if (!users.containsKey(normalizedEmail)) throw Exception('Account not found');
    final rec = users[normalizedEmail] as Map<String, dynamic>;
    final storedHash = (rec['passwordHash'] ?? '') as String;
    final oldHash = _hashPassword(oldPassword);
    if (storedHash != oldHash) throw Exception('Current password is incorrect');
    rec['passwordHash'] = _hashPassword(newPassword);
    users[normalizedEmail] = rec;
    await _saveUsersMap(users);
  }

  Future<void> archiveConversation(Map<String, dynamic> conversationMeta) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kConversationsArchive);
    List<dynamic> list = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        list = json.decode(raw) as List<dynamic>;
      } catch (_) {
        list = [];
      }
    }
    list.insert(0, conversationMeta);
    await sp.setString(_kConversationsArchive, json.encode(list));
  }

  Future<List<Map<String, dynamic>>> getArchivedConversations() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kConversationsArchive);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearArchivedConversations() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kConversationsArchive);
  }

  Future<Map<String, dynamic>> loadUserPrefs(String email) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('prefs_${email.toLowerCase()}');
    if (raw == null) return {};
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveUserPrefs(String email, Map<String, dynamic> prefs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('prefs_${email.toLowerCase()}', json.encode(prefs));
  }
}
