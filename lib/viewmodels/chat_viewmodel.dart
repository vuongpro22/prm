import 'package:flutter/material.dart';
import 'package:prm_project/database/database_helper.dart';
import 'package:prm_project/models/chat_message.dart';

class ChatViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  int? _userId;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;

  void setUserId(int? id) {
    if (_userId != id) {
      _userId = id;
      _messages = [];
      if (id != null) {
        loadMessages();
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> loadMessages() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final dbMsgs = await _dbHelper.getMessages(_userId!);
      _messages = dbMsgs;

      if (_messages.isEmpty) {
        // Welcome message from bot
        await _insertBotMessage('Hello! Welcome to Luxura support. How can I assist you today? You can ask about shipping, returns, store hours, warranties, or active promos.');
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (_userId == null || text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: 'MSG-${DateTime.now().microsecondsSinceEpoch}',
      text: text.trim(),
      timestamp: DateTime.now(),
      isMe: true,
    );

    _messages.add(userMsg);
    notifyListeners();

    await _dbHelper.insertMessage(_userId!, userMsg);

    // Simulate typing and send reply
    _isTyping = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1000));

    final botReply = _generateBotReply(text);
    await _insertBotMessage(botReply);

    _isTyping = false;
    notifyListeners();
  }

  Future<void> _insertBotMessage(String text) async {
    if (_userId == null) return;

    final botMsg = ChatMessage(
      id: 'MSG-${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      timestamp: DateTime.now(),
      isMe: false,
    );

    _messages.add(botMsg);
    notifyListeners();

    await _dbHelper.insertMessage(_userId!, botMsg);
  }

  String _generateBotReply(String input) {
    final query = input.toLowerCase();

    if (query.contains('shipping') || query.contains('delivery')) {
      return 'We offer FREE standard shipping on orders over \$500. For orders under \$500, shipping is \$15. Delivery typically takes 3 to 5 business days.';
    }
    if (query.contains('return') || query.contains('refund') || query.contains('exchange')) {
      return 'Our returns policy is simple! You can return any unused item in its original packaging within 30 days of purchase for a full refund or exchange. Contact support for a return shipping label.';
    }
    if (query.contains('hour') || query.contains('open') || query.contains('close') || query.contains('time')) {
      return 'Our primary showrooms are open from 9:00 AM to 9:00 PM, Monday through Sunday. Check our "Store Locator" tab to find directions to the nearest branch!';
    }
    if (query.contains('warranty') || query.contains('guarantee') || query.contains('repair')) {
      return 'All premium hardware items purchased at Luxura include a standard 12-month local manufacturer warranty covering hardware defects. Accessories include a 6-month warranty.';
    }
    if (query.contains('discount') || query.contains('coupon') || query.contains('promo') || query.contains('sale')) {
      return 'You can get 10% off your first purchase using the promo code: WELCOME10. Or try SUPERDEAL20 for a 20% discount on summer items!';
    }
    if (query.contains('hello') || query.contains('hi') || query.contains('hey')) {
      return 'Hello there! Let me know if you need help with shipping, returns, store hours, warranties, or checking active promo codes!';
    }

    return 'I appreciate your message. I am a virtual assistant, so for specific inquiries or account issues, feel free to contact us at support@luxurastore.com or call 1-800-LUXURA.';
  }

  Future<void> clearChat() async {
    if (_userId == null) return;
    _messages = [];
    notifyListeners();
    await _dbHelper.clearMessages(_userId!);
    await _insertBotMessage('Chat history cleared. How can I help you today?');
  }
}
