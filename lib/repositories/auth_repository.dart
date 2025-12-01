import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthRepository extends ChangeNotifier {
  final AuthService _service;
  AuthUser? _user;
  bool _loading = true;

  AuthRepository({required AuthService service}) : _service = service {
    _init();
  }

  bool get isLoading => _loading;
  AuthUser? get user => _user;
  bool get loggedIn => _user != null;

  /// ✅ New token getter
  String? get token => _user?.id;

  Future<void> _init() async {
    _loading = true;
    notifyListeners();
    try {
      final u = await _service.currentUser();
      _user = u;
    } catch (_) {
      _user = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final token = await _service.signIn(email: email, password: password);
      _user = AuthUser(id: token, email: email.trim().toLowerCase(), name: email.split('@').first);
    } catch (e) {
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final token = await _service.register(name: name, email: email, password: password);
      _user = AuthUser(id: token, email: email.trim().toLowerCase(), name: name.trim());
    } catch (e) {
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _loading = true;
    notifyListeners();
    try {
      await _service.signOut();
      _user = null;
    } catch (e) {
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> changeName(String newName) async {
    if (_user == null) throw Exception('Not signed in');
    _loading = true;
    notifyListeners();
    try {
      await _service.changeName(_user!.email, newName);
      _user = AuthUser(id: _user!.id, email: _user!.email, name: newName);
    } catch (e) {
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (_user == null) throw Exception('Not signed in');
    _loading = true;
    notifyListeners();
    try {
      await _service.changePassword(_user!.email, currentPassword, newPassword);
    } catch (e) {
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> saveUserPrefs(Map<String, dynamic> prefs) async {
    if (_user == null) throw Exception('Not signed in');
    await _service.saveUserPrefs(_user!.email, prefs);
  }

  Future<Map<String, dynamic>> loadUserPrefs() async {
    if (_user == null) return {};
    return await _service.loadUserPrefs(_user!.email);
  }
}
