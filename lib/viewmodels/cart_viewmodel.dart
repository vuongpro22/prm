import 'package:flutter/material.dart';
import 'package:prm_project/database/database_helper.dart';
import 'package:prm_project/models/cart_item.dart';
import 'package:prm_project/models/product.dart';
import 'package:prm_project/models/order.dart';

class CartViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  int? _userId;
  List<CartItem> _items = [];
  bool _isLoading = false;
  String _promoCode = '';
  double _discountPercentage = 0.0;

  int? get userId => _userId;
  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String get promoCode => _promoCode;
  double get discountPercentage => _discountPercentage;

  Future<void> setUserId(int? id, List<Product> availableProducts) async {
    if (_userId != id) {
      _userId = id;
      _items = [];
      _promoCode = '';
      _discountPercentage = 0.0;
      if (id != null) {
        await loadCart(availableProducts);
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> loadCart(List<Product> availableProducts) async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final dbItems = await _dbHelper.getCartItems(_userId!);
      _items = [];
      for (var map in dbItems) {
        final productId = map['productId'] as int;
        final quantity = map['quantity'] as int;
        
        final product = availableProducts.firstWhere(
          (p) => p.id == productId,
          orElse: () => Product(
            id: productId,
            name: 'Unknown Product',
            description: '',
            price: 0.0,
            imageUrl: '',
            rating: 0.0,
            category: '',
            reviews: [],
          ),
        );

        if (product.price > 0.0) {
          _items.add(CartItem(product: product, quantity: quantity));
        }
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    if (_userId == null) return;
    
    // Check local list
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();

    // Persist to DB
    await _dbHelper.insertCartItem(_userId!, product.id, quantity);
  }

  Future<void> updateQuantity(Product product, int quantity) async {
    if (_userId == null) return;
    if (quantity <= 0) {
      await removeFromCart(product);
      return;
    }

    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      _items[index].quantity = quantity;
      notifyListeners();
      await _dbHelper.updateCartItemQuantity(_userId!, product.id, quantity);
    }
  }

  Future<void> removeFromCart(Product product) async {
    if (_userId == null) return;

    _items.removeWhere((item) => item.product.id == product.id);
    notifyListeners();
    await _dbHelper.removeCartItem(_userId!, product.id);
  }

  Future<void> clearCart() async {
    if (_userId == null) return;
    _items = [];
    _promoCode = '';
    _discountPercentage = 0.0;
    notifyListeners();
    await _dbHelper.clearCart(_userId!);
  }

  // Cost calculations
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get discountAmount => subtotal * _discountPercentage;
  double get shippingFee => (subtotal == 0.0 || subtotal > 500.0) ? 0.0 : 15.0; // Free shipping on orders over $500
  double get taxAmount => (subtotal - discountAmount) * 0.08; // 8% sales tax
  double get total => subtotal == 0.0 ? 0.0 : (subtotal - discountAmount + shippingFee + taxAmount);

  bool applyPromoCode(String code) {
    final cleaned = code.trim().toUpperCase();
    if (cleaned == 'WELCOME10') {
      _promoCode = cleaned;
      _discountPercentage = 0.10; // 10% off
      notifyListeners();
      return true;
    } else if (cleaned == 'SUPERDEAL20') {
      _promoCode = cleaned;
      _discountPercentage = 0.20; // 20% off
      notifyListeners();
      return true;
    }
    return false;
  }

  void removePromoCode() {
    _promoCode = '';
    _discountPercentage = 0.0;
    notifyListeners();
  }

  // Checkout process
  Future<OrderModel?> checkout({
    required String shippingAddress,
    required String cardHolder,
    required String cardNumber,
  }) async {
    if (_userId == null || _items.isEmpty) return null;

    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
    final newOrder = OrderModel(
      id: orderId,
      date: DateTime.now(),
      status: 'Processing',
      total: total,
      shippingAddress: shippingAddress,
      itemNames: _items.map((item) => '${item.product.name} (x${item.quantity})').toList(),
    );

    // Save order to db
    await _dbHelper.insertOrder(_userId!, newOrder);

    // Clear cart in db & memory
    await clearCart();

    return newOrder;
  }
}
