import 'package:prm_project/models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;

  Map<String, dynamic> toMap(int userId) {
    return {
      'userId': userId,
      'productId': product.id,
      'quantity': quantity,
    };
  }
}
