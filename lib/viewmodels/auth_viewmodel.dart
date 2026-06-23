import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:prm_project/database/database_helper.dart';
import 'package:prm_project/models/user.dart';

class AuthViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;

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
      final fbUser = _firebaseAuth.currentUser;
      if (fbUser != null) {
        await _syncWithLocalUser(fbUser);
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();

    // Listen for future auth state changes (login, logout)
    _firebaseAuth.authStateChanges().listen((fbUser) async {
      if (fbUser != null) {
        await _syncWithLocalUser(fbUser);
      } else {
        _currentUser = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', false);
        await prefs.remove('userEmail');
        await prefs.remove('userId');
        await prefs.remove('userName');
        notifyListeners();
      }
    });
  }

  Future<void> _syncWithLocalUser(firebase_auth.User fbUser) async {
    final email = fbUser.email;
    if (email == null) return;

    try {
      var localUser = await _dbHelper.getUserByEmail(email);
      if (localUser == null) {
        // First time logging in or registering on this device, create a local SQLite record
        final name = fbUser.displayName ?? email.split('@').first;
        final newUser = User(name: name, email: email, password: '');
        final id = await _dbHelper.insertUser(newUser);
        localUser = User(id: id, name: name, email: email, password: '');
      }

      _currentUser = localUser;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', email);
      await prefs.setInt('userId', localUser.id ?? 1);
      await prefs.setString('userName', localUser.name);
    } catch (e) {
      debugPrint('Sync user error: $e');
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        await _syncWithLocalUser(credential.user!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Firebase login exception: ${e.code} - ${e.message}');
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        _errorMessage = 'Email hoặc mật khẩu không chính xác';
      } else if (e.code == 'wrong-password') {
        _errorMessage = 'Mật khẩu không đúng';
      } else if (e.code == 'invalid-email') {
        _errorMessage = 'Địa chỉ email không hợp lệ';
      } else if (e.code == 'user-disabled') {
        _errorMessage = 'Tài khoản này đã bị vô hiệu hóa';
      } else {
        _errorMessage = e.message ?? 'Đăng nhập thất bại. Vui lòng thử lại.';
      }
    } catch (e) {
      debugPrint('Login exception: $e');
      _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
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
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        
        // Sync to SQLite database (check if user already exists locally first)
        var localUser = await _dbHelper.getUserByEmail(email);
        int id;
        if (localUser == null) {
          final newUser = User(name: name, email: email, password: '');
          id = await _dbHelper.insertUser(newUser);
        } else {
          id = localUser.id ?? 1;
        }
        
        _currentUser = User(id: id, name: name, email: email, password: '');
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userEmail', email);
        await prefs.setInt('userId', id);
        await prefs.setString('userName', name);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Firebase registration exception: ${e.code} - ${e.message}');
      if (e.code == 'email-already-in-use') {
        _errorMessage = 'Địa chỉ email này đã được sử dụng';
      } else if (e.code == 'weak-password') {
        _errorMessage = 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn';
      } else if (e.code == 'invalid-email') {
        _errorMessage = 'Địa chỉ email không hợp lệ';
      } else {
        _errorMessage = e.message ?? 'Đăng ký thất bại. Vui lòng thử lại.';
      }
    } catch (e) {
      debugPrint('Registration exception: $e');
      _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Firebase signOut error: $e');
    }
    
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userEmail');
    await prefs.remove('userId');
    await prefs.remove('userName');
    notifyListeners();
  }
}
