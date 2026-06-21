class ChatMessage {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });

  Map<String, dynamic> toMap(int userId) {
    return {
      'id': id,
      'userId': userId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isMe': isMe ? 1 : 0,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      text: map['text'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isMe: (map['isMe'] as int) == 1,
    );
  }
}
