import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm_project/viewmodels/cart_viewmodel.dart';
import 'package:prm_project/views/checkout/checkout_screen.dart';
import 'package:prm_project/views/theme/theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartVm = Provider.of<CartViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Y O U R  C A R T'),
        actions: [
          if (cartVm.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppTheme.accentRose),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text('Are you sure you want to remove all items from your cart?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () {
                          cartVm.clearCart();
                          Navigator.pop(context);
                        },
                        child: const Text('CLEAR', style: TextStyle(color: AppTheme.accentRose)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cartVm.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 72, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: AppTheme.textMain, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Go browse the shop to find amazing items!',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('BROWSE PRODUCTS'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Cart Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: cartVm.items.length,
                    itemBuilder: (context, index) {
                      final item = cartVm.items[index];
                      return Dismissible(
                        key: Key('dismiss-${item.product.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRose.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          cartVm.removeFromCart(item.product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.product.name} removed from cart'),
                              backgroundColor: AppTheme.accentRose,
                            ),
                          );
                        },
                        child: _buildCartItemCard(context, item, cartVm),
                      );
                    },
                  ),
                ),

                // Cart Pricing Summary panel
                _buildSummaryPanel(context, cartVm),
              ],
            ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, dynamic item, CartViewModel cartVm) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Item Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(item.product.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Item Name & price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.product.price.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppTheme.secondaryTeal, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Quantity Control
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primaryNeon, size: 22),
                  onPressed: () {
                    cartVm.updateQuantity(item.product, item.quantity - 1);
                  },
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryNeon, size: 22),
                  onPressed: () {
                    cartVm.updateQuantity(item.product, item.quantity + 1);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPanel(BuildContext context, CartViewModel cartVm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Promo Code input
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _promoController,
                    decoration: const InputDecoration(
                      hintText: 'Enter Promo Code (WELCOME10)',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryTeal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: () {
                    if (cartVm.applyPromoCode(_promoController.text)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Promo code applied successfully!'),
                          backgroundColor: AppTheme.secondaryTeal,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid promo code'),
                          backgroundColor: AppTheme.accentRose,
                        ),
                      );
                    }
                  },
                  child: const Text('APPLY', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Active Promo Info
          if (cartVm.promoCode.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text('Code: ${cartVm.promoCode}'),
                  backgroundColor: AppTheme.primaryNeon.withOpacity(0.2),
                  labelStyle: const TextStyle(color: AppTheme.primaryNeon, fontSize: 12),
                  onDeleted: () {
                    cartVm.removePromoCode();
                    _promoController.clear();
                  },
                ),
                Text(
                  '- \$${cartVm.discountAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppTheme.accentRose, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          const SizedBox(height: 12),

          // Price Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(color: AppTheme.textMuted)),
              Text('\$${cartVm.subtotal.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textMain)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Shipping Fee', style: TextStyle(color: AppTheme.textMuted)),
              Text(
                cartVm.shippingFee == 0.0 ? 'FREE' : '\$${cartVm.shippingFee.toStringAsFixed(2)}',
                style: TextStyle(color: cartVm.shippingFee == 0.0 ? AppTheme.secondaryTeal : AppTheme.textMain),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated Tax (8%)', style: TextStyle(color: AppTheme.textMuted)),
              Text('\$${cartVm.taxAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textMain)),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
              Text(
                '\$${cartVm.total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondaryTeal),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Checkout button
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
              );
            },
            child: const Text('PROCEED TO CHECKOUT'),
          ),
        ],
      ),
    );
  }
}
