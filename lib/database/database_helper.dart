import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io' show Platform;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:prm_project/models/user.dart';
import 'package:prm_project/models/product.dart';
import 'package:prm_project/models/cart_item.dart';
import 'package:prm_project/models/order.dart';
import 'package:prm_project/models/app_notification.dart';
import 'package:prm_project/models/chat_message.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static dynamic _database;

  DatabaseHelper._init();

  void clearDatabase() {
    _fallbackDb.forEach((key, value) {
      value.clear();
    });
  }

  // In-memory fallbacks for Desktop/Web
  final Map<String, List<Map<String, dynamic>>> _fallbackDb = {
    'users': [],
    'cart_items': [],
    'orders': [],
    'notifications': [],
    'messages': [],
  };

  bool get _useSQLite => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<dynamic> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('luxura.db');
    return _database!;
  }

  Future<dynamic> _initDB(String filePath) async {
    if (!_useSQLite) {
      await _loadFallbackData();
      return 'fallback';
    }
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, filePath);
      return await openDatabase(path, version: 1, onCreate: _createDB);
    } catch (e) {
      debugPrint('SQLite initialization failed: $e. Falling back to SharedPreferences.');
      await _loadFallbackData();
      return 'fallback';
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cart_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        quantity INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        userId INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        total REAL NOT NULL,
        shippingAddress TEXT NOT NULL,
        itemNames TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        userId INTEGER NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isRead INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        userId INTEGER NOT NULL,
        text TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isMe INTEGER NOT NULL
      )
    ''');
  }

  // --- FALLBACK STORAGE METHODS FOR WEB/DESKTOP ---
  Future<void> _loadFallbackData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (String table in _fallbackDb.keys) {
        final dataStr = prefs.getString('db_$table');
        if (dataStr != null) {
          final List<dynamic> decoded = json.decode(dataStr);
          _fallbackDb[table] = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (_) {}
  }

  Future<void> _saveFallbackData(String table) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('db_$table', json.encode(_fallbackDb[table]));
    } catch (_) {}
  }

  // --- USER API ---
  Future<int> insertUser(User user) async {
    final db = await database;
    if (db is Database) {
      return await db.insert('users', user.toMap());
    } else {
      final list = _fallbackDb['users']!;
      final exists = list.any((u) => u['email'] == user.email);
      if (exists) return -1;
      
      final id = list.length + 1;
      final uMap = user.toMap();
      uMap['id'] = id;
      list.add(uMap);
      await _saveFallbackData('users');
      return id;
    }
  }

  Future<User?> getUser(String email, String password) async {
    final db = await database;
    if (db is Database) {
      final maps = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password],
      );
      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } else {
      final list = _fallbackDb['users']!;
      final match = list.firstWhere(
        (u) => u['email'] == email && u['password'] == password,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        return User.fromMap(match);
      }
      return null;
    }
  }

  // --- CART API ---
  Future<List<Map<String, dynamic>>> getCartItems(int userId) async {
    final db = await database;
    if (db is Database) {
      return await db.query('cart_items', where: 'userId = ?', whereArgs: [userId]);
    } else {
      return _fallbackDb['cart_items']!.where((c) => c['userId'] == userId).toList();
    }
  }

  Future<void> updateCartItemQuantity(int userId, int productId, int quantity) async {
    final db = await database;
    if (db is Database) {
      await db.update(
        'cart_items',
        {'quantity': quantity},
        where: 'userId = ? AND productId = ?',
        whereArgs: [userId, productId],
      );
    } else {
      final list = _fallbackDb['cart_items']!;
      final index = list.indexWhere((c) => c['userId'] == userId && c['productId'] == productId);
      if (index != -1) {
        list[index]['quantity'] = quantity;
        await _saveFallbackData('cart_items');
      }
    }
  }

  Future<void> insertCartItem(int userId, int productId, int quantity) async {
    final db = await database;
    if (db is Database) {
      final existing = await db.query(
        'cart_items',
        where: 'userId = ? AND productId = ?',
        whereArgs: [userId, productId],
      );
      if (existing.isNotEmpty) {
        final currentQty = existing.first['quantity'] as int;
        await updateCartItemQuantity(userId, productId, currentQty + quantity);
      } else {
        await db.insert('cart_items', {
          'userId': userId,
          'productId': productId,
          'quantity': quantity,
        });
      }
    } else {
      final list = _fallbackDb['cart_items']!;
      final index = list.indexWhere((c) => c['userId'] == userId && c['productId'] == productId);
      if (index != -1) {
        list[index]['quantity'] = (list[index]['quantity'] as int) + quantity;
      } else {
        list.add({
          'id': list.length + 1,
          'userId': userId,
          'productId': productId,
          'quantity': quantity,
        });
      }
      await _saveFallbackData('cart_items');
    }
  }

  Future<void> removeCartItem(int userId, int productId) async {
    final db = await database;
    if (db is Database) {
      await db.delete(
        'cart_items',
        where: 'userId = ? AND productId = ?',
        whereArgs: [userId, productId],
      );
    } else {
      final list = _fallbackDb['cart_items']!;
      list.removeWhere((c) => c['userId'] == userId && c['productId'] == productId);
      await _saveFallbackData('cart_items');
    }
  }

  Future<void> clearCart(int userId) async {
    final db = await database;
    if (db is Database) {
      await db.delete('cart_items', where: 'userId = ?', whereArgs: [userId]);
    } else {
      final list = _fallbackDb['cart_items']!;
      list.removeWhere((c) => c['userId'] == userId);
      await _saveFallbackData('cart_items');
    }
  }

  // --- ORDERS API ---
  Future<void> insertOrder(int userId, OrderModel order) async {
    final db = await database;
    if (db is Database) {
      await db.insert('orders', order.toMap(userId));
    } else {
      _fallbackDb['orders']!.add(order.toMap(userId));
      await _saveFallbackData('orders');
    }
  }

  Future<List<OrderModel>> getOrders(int userId) async {
    final db = await database;
    if (db is Database) {
      final maps = await db.query('orders', where: 'userId = ?', whereArgs: [userId]);
      return maps.map((m) => OrderModel.fromMap(m)).toList();
    } else {
      final maps = _fallbackDb['orders']!.where((o) => o['userId'] == userId).toList();
      return maps.map((m) => OrderModel.fromMap(m)).toList();
    }
  }

  // --- NOTIFICATIONS API ---
  Future<void> insertNotification(int userId, AppNotification notification) async {
    final db = await database;
    if (db is Database) {
      await db.insert('notifications', notification.toMap(userId));
    } else {
      _fallbackDb['notifications']!.add(notification.toMap(userId));
      await _saveFallbackData('notifications');
    }
  }

  Future<List<AppNotification>> getNotifications(int userId) async {
    final db = await database;
    if (db is Database) {
      final maps = await db.query(
        'notifications',
        where: 'userId = ?',
        orderBy: 'timestamp DESC',
      );
      return maps.map((m) => AppNotification.fromMap(m)).toList();
    } else {
      final maps = _fallbackDb['notifications']!
          .where((n) => n['userId'] == userId)
          .toList();
      maps.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      return maps.map((m) => AppNotification.fromMap(m)).toList();
    }
  }

  Future<void> markNotificationAsRead(int userId, String notificationId) async {
    final db = await database;
    if (db is Database) {
      await db.update(
        'notifications',
        {'isRead': 1},
        where: 'userId = ? AND id = ?',
        whereArgs: [userId, notificationId],
      );
    } else {
      final list = _fallbackDb['notifications']!;
      final index = list.indexWhere((n) => n['userId'] == userId && n['id'] == notificationId);
      if (index != -1) {
        list[index]['isRead'] = 1;
        await _saveFallbackData('notifications');
      }
    }
  }

  Future<void> markAllNotificationsAsRead(int userId) async {
    final db = await database;
    if (db is Database) {
      await db.update(
        'notifications',
        {'isRead': 1},
        where: 'userId = ?',
        whereArgs: [userId],
      );
    } else {
      final list = _fallbackDb['notifications']!;
      for (var item in list) {
        if (item['userId'] == userId) {
          item['isRead'] = 1;
        }
      }
      await _saveFallbackData('notifications');
    }
  }

  Future<void> clearNotifications(int userId) async {
    final db = await database;
    if (db is Database) {
      await db.delete('notifications', where: 'userId = ?', whereArgs: [userId]);
    } else {
      final list = _fallbackDb['notifications']!;
      list.removeWhere((n) => n['userId'] == userId);
      await _saveFallbackData('notifications');
    }
  }

  // --- MESSAGES API ---
  Future<void> insertMessage(int userId, ChatMessage message) async {
    final db = await database;
    if (db is Database) {
      await db.insert('messages', message.toMap(userId));
    } else {
      _fallbackDb['messages']!.add(message.toMap(userId));
      await _saveFallbackData('messages');
    }
  }

  Future<List<ChatMessage>> getMessages(int userId) async {
    final db = await database;
    if (db is Database) {
      final maps = await db.query(
        'messages',
        where: 'userId = ?',
        orderBy: 'timestamp ASC',
      );
      return maps.map((m) => ChatMessage.fromMap(m)).toList();
    } else {
      final maps = _fallbackDb['messages']!
          .where((m) => m['userId'] == userId)
          .toList();
      maps.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
      return maps.map((m) => ChatMessage.fromMap(m)).toList();
    }
  }

  Future<void> clearMessages(int userId) async {
    final db = await database;
    if (db is Database) {
      await db.delete('messages', where: 'userId = ?', whereArgs: [userId]);
    } else {
      final list = _fallbackDb['messages']!;
      list.removeWhere((m) => m['userId'] == userId);
      await _saveFallbackData('messages');
    }
  }
}
