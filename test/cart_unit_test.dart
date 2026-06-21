import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prm_project/models/product.dart';
import 'package:prm_project/viewmodels/cart_viewmodel.dart';
import 'package:prm_project/database/database_helper.dart';

void main() {
  // Initialize Mock SharedPreferences values before test suites run
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CartViewModel Unit Tests', () {
    late CartViewModel cartViewModel;
    late Product sampleProduct;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      DatabaseHelper.instance.clearDatabase();
      cartViewModel = CartViewModel();
      sampleProduct = Product(
        id: 99,
        name: 'Test Device',
        description: 'A device built for unit testing.',
        price: 100.0,
        imageUrl: '',
        rating: 4.5,
        category: 'TestCategory',
        reviews: [],
      );
    });

    test('Initial cart state is empty', () {
      expect(cartViewModel.items.isEmpty, true);
      expect(cartViewModel.subtotal, 0.0);
      expect(cartViewModel.total, 0.0);
    });

    test('Adding product updates cart list and total pricing', () async {
      await cartViewModel.setUserId(1, [sampleProduct]);

      await cartViewModel.addToCart(sampleProduct, quantity: 2);

      expect(cartViewModel.items.length, 1);
      expect(cartViewModel.items[0].product.id, 99);
      expect(cartViewModel.items[0].quantity, 2);
      expect(cartViewModel.subtotal, 200.0);
    });

    test('Applying promo codes updates discount percentage', () async {
      await cartViewModel.setUserId(1, [sampleProduct]);
      await cartViewModel.addToCart(sampleProduct, quantity: 1); // Subtotal: 100.0

      // Apply invalid coupon
      bool badApplied = cartViewModel.applyPromoCode('BADCODE');
      expect(badApplied, false);
      expect(cartViewModel.discountPercentage, 0.0);

      // Apply valid coupon
      bool goodApplied = cartViewModel.applyPromoCode('WELCOME10');
      expect(goodApplied, true);
      expect(cartViewModel.discountPercentage, 0.10);
      expect(cartViewModel.discountAmount, 10.0);
    });

    test('Clearing cart resets items and totals', () async {
      await cartViewModel.setUserId(1, [sampleProduct]);
      await cartViewModel.addToCart(sampleProduct, quantity: 5);
      expect(cartViewModel.items.isNotEmpty, true);

      await cartViewModel.clearCart();
      expect(cartViewModel.items.isEmpty, true);
      expect(cartViewModel.subtotal, 0.0);
    });
  });
}
