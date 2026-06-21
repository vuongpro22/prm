import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm_project/viewmodels/product_viewmodel.dart';
import 'package:prm_project/viewmodels/cart_viewmodel.dart';
import 'package:prm_project/views/products/product_detail_screen.dart';
import 'package:prm_project/views/cart/cart_screen.dart';
import 'package:prm_project/views/theme/theme.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productVm = Provider.of<ProductViewModel>(context);
    final cartVm = Provider.of<CartViewModel>(context);

    // Calculate cart item count
    final cartItemCount = cartVm.items.fold(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('L U X U R A'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.accentRose,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Promotional Banner Carousel / Slider
          _buildPromoBanner(),

          // Search Bar & Filter Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
              ),
              onChanged: (val) => productVm.setSearchQuery(val),
            ),
          ),

          // Categories chips
          _buildCategorySelector(productVm),

          // Sorting & Results Count bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${productVm.products.length} Products Found',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                DropdownButton<String>(
                  value: productVm.sortBy,
                  dropdownColor: AppTheme.darkSurface,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.swap_vert, color: AppTheme.secondaryTeal, size: 20),
                  style: const TextStyle(color: AppTheme.textMain, fontSize: 13, fontWeight: FontWeight.bold),
                  items: const [
                    DropdownMenuItem(value: 'Popularity', child: Text('Sort: Popularity')),
                    DropdownMenuItem(value: 'PriceLowToHigh', child: Text('Sort: Price L-H')),
                    DropdownMenuItem(value: 'PriceHighToLow', child: Text('Sort: Price H-L')),
                  ],
                  onChanged: (val) {
                    if (val != null) productVm.setSortBy(val);
                  },
                ),
              ],
            ),
          ),

          // Products grid
          Expanded(
            child: productVm.products.isEmpty
                ? const Center(
                    child: Text(
                      'No products found matching filters.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: productVm.products.length,
                    itemBuilder: (context, index) {
                      final product = productVm.products[index];
                      return _buildProductCard(context, product, cartVm);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      height: 90,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryNeon, AppTheme.secondaryTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Summer Collection 2026',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'Use code: SUPERDEAL20 for 20% off!',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          Icon(Icons.flash_on, color: Colors.amber, size: 36),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(ProductViewModel productVm) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: productVm.categories.length,
        itemBuilder: (context, index) {
          final cat = productVm.categories[index];
          final isSelected = productVm.selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.primaryNeon,
              backgroundColor: AppTheme.darkSurface,
              onSelected: (selected) {
                if (selected) {
                  productVm.setCategory(cat);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic product, CartViewModel cartVm) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with category tag overlay
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, size: 50, color: AppTheme.textMuted),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '${product.rating}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.secondaryTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.add_shopping_cart,
                          color: AppTheme.primaryNeon,
                          size: 20,
                        ),
                        onPressed: () {
                          cartVm.addToCart(product);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} added to cart!'),
                              backgroundColor: AppTheme.secondaryTeal,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
