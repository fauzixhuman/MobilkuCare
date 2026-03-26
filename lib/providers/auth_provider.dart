import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  String _displayName = '';
  bool _isLoading = true;
  String? _error;

  User? get user => _user;
  String get displayName => _displayName;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;
  String get userId => _user?.uid ?? '';

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        // Optimistically set the display name to avoid showing email momentarily
        _displayName = user.displayName ?? 'User';
        notifyListeners();
        
        // Fetch the definitive name from Firestore (handles user edits)
        _displayName = await _authService.getDisplayName();
      } else {
        _displayName = '';
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );
      _displayName = name;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      _displayName = await _authService.getDisplayName();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _displayName = await _authService.getDisplayName();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final errorStr = e.toString();
      if (!errorStr.contains('popup_closed_by_user')) {
        _error = errorStr;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDisplayName(String newName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updateDisplayName(newName);
      _displayName = newName;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _user = null;
    _displayName = '';
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
