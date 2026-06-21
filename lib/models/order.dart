class OrderModel {
  final String id;
  final DateTime date;
  final String status;
  final double total;
  final String shippingAddress;
  final List<String> itemNames;

  OrderModel({
    required this.id,
    required this.date,
    required this.status,
    required this.total,
    required this.shippingAddress,
    required this.itemNames,
  });

  Map<String, dynamic> toMap(int userId) {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'status': status,
      'total': total,
      'shippingAddress': shippingAddress,
      'itemNames': itemNames.join(', '),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      status: map['status'] as String,
      total: (map['total'] as num).toDouble(),
      shippingAddress: map['shippingAddress'] as String,
      itemNames: (map['itemNames'] as String).split(', '),
    );
  }
}
