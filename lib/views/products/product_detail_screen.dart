import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm_project/models/product.dart';
import 'package:prm_project/viewmodels/product_viewmodel.dart';
import 'package:prm_project/viewmodels/cart_viewmodel.dart';
import 'package:prm_project/views/theme/theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final productVm = Provider.of<ProductViewModel>(context, listen: false);
    final cartVm = Provider.of<CartViewModel>(context, listen: false);

    final product = productVm.getProductById(widget.productId);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name.toUpperCase()),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Hero Image
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(product.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNeon.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.4)),
                        ),
                        child: Text(
                          product.category,
                          style: const TextStyle(
                            color: AppTheme.primaryNeon,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${product.rating}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMain,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Name & Price
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppTheme.formatVnd(product.price),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryTeal,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Tổng quan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quantity Selector
                  Row(
                    children: [
                      const Text(
                        'Số lượng:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMain,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: AppTheme.textMain),
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() {
                                    _quantity--;
                                  });
                                }
                              },
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMain,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: AppTheme.textMain),
                              onPressed: () {
                                setState(() {
                                  _quantity++;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Customer Reviews
                  const Text(
                    'Đánh giá từ khách hàng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (product.reviews.isEmpty)
                    const Text(
                      'Chưa có đánh giá nào cho sản phẩm này.',
                      style: TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                    )
                  else
                    ...product.reviews.map((rev) => _buildReviewTile(rev)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.darkSurface,
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  cartVm.addToCart(product, quantity: _quantity);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã thêm $_quantity x ${product.name} vào giỏ hàng!'),
                      backgroundColor: AppTheme.secondaryTeal,
                      action: SnackBarAction(
                        label: 'XEM GIỎ HÀNG',
                        textColor: Colors.white,
                        onPressed: () {
                          Navigator.pop(context); // Go back to shop
                          // Note: Shop tab can open cart from header
                        },
                      ),
                    ),
                  );
                },
                child: const Text('THÊM VÀO GIỎ HÀNG'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewTile(ProductReview review) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  review.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  review.date,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  Icons.star,
                  size: 14,
                  color: i < review.rating ? Colors.amber : Colors.white10,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              review.comment,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
