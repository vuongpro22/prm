import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prm_project/database/database_helper.dart';
import 'package:prm_project/models/user.dart';

class AuthViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthViewModel() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (isLoggedIn) {
        final email = prefs.getString('userEmail');
        final password = prefs.getString('userPassword');
        if (email != null && password != null) {
          final user = await _dbHelper.getUser(email, password);
          if (user != null) {
            _currentUser = user;
          }
        }
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _dbHelper.getUser(email, password);
      if (user != null) {
        _currentUser = user;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userEmail', email);
        await prefs.setString('userPassword', password);
        await prefs.setInt('userId', user.id ?? 1);
        await prefs.setString('userName', user.name);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid email or password';
      }
    } catch (e) {
      debugPrint('Login exception: $e');
      _errorMessage = 'An error occurred. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newUser = User(name: name, email: email, password: password);
      final id = await _dbHelper.insertUser(newUser);
      if (id != -1) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Email address already exists';
      }
    } catch (e) {
      debugPrint('Registration exception: $e');
      _errorMessage = 'Registration failed. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userEmail');
    await prefs.remove('userPassword');
    await prefs.remove('userId');
    await prefs.remove('userName');
    notifyListeners();
  }
}
