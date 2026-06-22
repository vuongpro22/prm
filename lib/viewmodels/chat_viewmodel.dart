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
        await _insertBotMessage('Xin chào! Chào mừng bạn đến với bộ phận hỗ trợ của Luxura. Tôi có thể giúp gì cho bạn hôm nay? Bạn có thể hỏi về vận chuyển, đổi trả hàng, giờ mở cửa, chính sách bảo hành hoặc các khuyến mãi hiện có.');
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

    if (query.contains('vận chuyển') || query.contains('giao hàng') || query.contains('ship') || query.contains('shipping') || query.contains('delivery')) {
      return 'Chúng tôi miễn phí vận chuyển cho đơn hàng trên 10.000.000 đ. Với đơn hàng dưới 10.000.000 đ, phí vận chuyển là 50.000 đ. Thời gian giao hàng dự kiến từ 3 đến 5 ngày làm việc.';
    }
    if (query.contains('trả hàng') || query.contains('hoàn tiền') || query.contains('đổi trả') || query.contains('return') || query.contains('refund') || query.contains('exchange')) {
      return 'Chính sách đổi trả rất đơn giản! Bạn có thể đổi trả bất kỳ sản phẩm nào chưa qua sử dụng, còn nguyên bao bì trong vòng 30 ngày kể từ khi mua để được hoàn tiền hoặc đổi sản phẩm mới. Liên hệ hỗ trợ để được hướng dẫn thêm.';
    }
    if (query.contains('giờ') || query.contains('mở cửa') || query.contains('đóng cửa') || query.contains('làm việc') || query.contains('hour') || query.contains('open') || query.contains('close') || query.contains('time')) {
      return 'Showroom chính của chúng tôi mở cửa từ 9:00 sáng đến 9:00 tối từ Thứ Hai đến Chủ Nhật. Vui lòng xem tab "Chi nhánh" để xem vị trí các cửa hàng gần nhất!';
    }
    if (query.contains('bảo hành') || query.contains('sửa') || query.contains('hỏng') || query.contains('warranty') || query.contains('guarantee') || query.contains('repair')) {
      return 'Tất cả các sản phẩm điện tử cao cấp tại Luxura đều được bảo hành chính hãng 12 tháng tại các trung tâm bảo hành trong nước. Phụ kiện đi kèm được bảo hành 6 tháng.';
    }
    if (query.contains('khuyến mãi') || query.contains('giảm giá') || query.contains('mã') || query.contains('coupon') || query.contains('promo') || query.contains('sale')) {
      return 'Bạn có thể dùng mã WELCOME10 để được giảm giá 10% cho đơn hàng đầu tiên, hoặc mã SUPERDEAL20 để được giảm giá 20% cho bộ sưu tập hè!';
    }
    if (query.contains('chào') || query.contains('hello') || query.contains('hi') || query.contains('hey')) {
      return 'Xin chào! Hãy cho tôi biết nếu bạn cần hỗ trợ về các vấn đề: giao hàng, chính sách đổi trả, giờ mở cửa showroom, chế độ bảo hành hoặc các mã giảm giá nhé!';
    }

    return 'Cảm ơn bạn đã nhắn tin. Tôi là trợ lý ảo Luxura. Đối với các yêu cầu cụ thể hoặc vấn đề tài khoản, xin vui lòng gửi email về support@luxurastore.com hoặc hotline 1-800-LUXURA.';
  }

  Future<void> clearChat() async {
    if (_userId == null) return;
    _messages = [];
    notifyListeners();
    await _dbHelper.clearMessages(_userId!);
    await _insertBotMessage('Lịch sử trò chuyện đã được xóa. Tôi có thể giúp gì thêm cho bạn?');
  }
}
