import 'package:flutter/material.dart';
import 'package:prm_project/models/product.dart';

class ProductViewModel extends ChangeNotifier {
  final List<Product> _allProducts = [
    Product(
      id: 1,
      name: 'iPhone 15 Pro Max',
      description: 'The ultimate iPhone featuring a strong and lightweight titanium design, a new Action button, powerful camera upgrades, and the A17 Pro chip for next-level mobile gaming and productivity.',
      price: 1199.99,
      imageUrl: 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=500&auto=format&fit=crop&q=60',
      rating: 4.8,
      category: 'Smartphones',
      reviews: [
        ProductReview(userName: 'Alex Carter', rating: 5.0, comment: 'Phenomenal build quality! The titanium feel is premium and battery life is stellar.', date: '2026-06-10'),
        ProductReview(userName: 'Sophia Nguyen', rating: 4.5, comment: 'Amazing camera, zoom is incredible. Slightly heavy but gorgeous screen.', date: '2026-06-15'),
      ],
    ),
    Product(
      id: 2,
      name: 'MacBook Pro M3 Max',
      description: 'Supercharged by the M3 Max chip, this laptop is engineered for workflows that require heavy processing, 3D rendering, and video editing. Includes a beautiful Liquid Retina XDR display.',
      price: 2499.99,
      imageUrl: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=500&auto=format&fit=crop&q=60',
      rating: 4.9,
      category: 'Laptops',
      reviews: [
        ProductReview(userName: 'Daniel K.', rating: 5.0, comment: 'Absolute beast of a machine. It handles 4K video exports without turning on the fans.', date: '2026-05-20'),
        ProductReview(userName: 'Elena Rostova', rating: 4.8, comment: 'Best laptop screen I have ever seen. Pricey but completely worth it.', date: '2026-06-02'),
      ],
    ),
    Product(
      id: 3,
      name: 'Sony WH-1000XM5',
      description: 'Industry-leading noise canceling headphones with dual processors, 8 microphones, and Auto NC Optimizer. Enjoy crystal-clear hands-free calling and exceptional wireless audio quality.',
      price: 349.99,
      imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500&auto=format&fit=crop&q=60',
      rating: 4.7,
      category: 'Audio',
      reviews: [
        ProductReview(userName: 'Marcus Aurelius', rating: 5.0, comment: 'ANC is like entering a silent room. Bass is deep, mids are extremely clean.', date: '2026-06-18'),
      ],
    ),
    Product(
      id: 4,
      name: 'Apple Watch Ultra 2',
      description: 'The most rugged and capable Apple Watch. Designed for outdoor adventures and athletic endurance, featuring a lightweight titanium case, extra-long battery life, and the brightest display ever.',
      price: 799.99,
      imageUrl: 'https://images.unsplash.com/photo-1434494878577-86c23bcb06b9?w=500&auto=format&fit=crop&q=60',
      rating: 4.6,
      category: 'Wearables',
      reviews: [
        ProductReview(userName: 'Jenna Smith', rating: 4.0, comment: 'Extremely durable, battery lasts 3 full days. Quite large on smaller wrists.', date: '2026-06-11'),
      ],
    ),
    Product(
      id: 5,
      name: 'Keychron Q1 Pro',
      description: 'A fully customizable mechanical keyboard with QMK/VIA support, double-gasket design, full CNC aluminum body, and dual wireless/wired modes for productivity and gaming.',
      price: 199.99,
      imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=500&auto=format&fit=crop&q=60',
      rating: 4.8,
      category: 'Accessories',
      reviews: [
        ProductReview(userName: 'Devin Cole', rating: 5.0, comment: 'The typing feel is incredibly tactile and poppy. Build like a solid block of steel.', date: '2026-06-05'),
      ],
    ),
    Product(
      id: 6,
      name: 'Dell UltraSharp 32" 4K',
      description: 'Experience outstanding color coverage and contrast with this premium 32-inch 4K USB-C hub monitor, designed for professional creators and multitasking efficiency.',
      price: 899.99,
      imageUrl: 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=500&auto=format&fit=crop&q=60',
      rating: 4.5,
      category: 'Monitors',
      reviews: [],
    ),
    Product(
      id: 7,
      name: 'JBL Charge 5 Speaker',
      description: 'Take the party with you. The Charge 5 delivers bold JBL Original Pro Sound, with an optimized long excursion driver, separate tweeter, and dual pumping JBL bass radiators.',
      price: 179.99,
      imageUrl: 'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=500&auto=format&fit=crop&q=60',
      rating: 4.6,
      category: 'Audio',
      reviews: [
        ProductReview(userName: 'Sam Miller', rating: 4.8, comment: 'Loud, great bass, and charges my phone while playing. Prefect for beach trips.', date: '2026-05-12'),
      ],
    ),
    Product(
      id: 8,
      name: 'Dyson V15 Detect',
      description: 'The most powerful, intelligent cordless vacuum. Engineered with a laser that reveals microscopic dust, automatically adapting suction power based on floor type.',
      price: 749.99,
      imageUrl: 'https://images.unsplash.com/photo-1558317374-067fb5f30001?w=500&auto=format&fit=crop&q=60',
      rating: 4.7,
      category: 'Home Smart',
      reviews: [
        ProductReview(userName: 'Karen G.', rating: 5.0, comment: 'The laser is a game changer, shows dirt I did not know existed. Very easy to clean.', date: '2026-06-08'),
      ],
    ),
  ];

  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'Popularity'; // Popularity, PriceLowToHigh, PriceHighToLow

  List<Product> get products => _filteredProducts.isEmpty && _searchQuery.isEmpty && _selectedCategory == 'All' && _sortBy == 'Popularity'
      ? _allProducts
      : _filteredProducts;

  List<Product> get allProducts => _allProducts;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;

  List<String> get categories {
    final list = _allProducts.map((p) => p.category).toSet().toList();
    list.sort();
    return ['All', ...list];
  }

  ProductViewModel() {
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _applyFilters();
  }

  void _applyFilters() {
    List<Product> results = List.from(_allProducts);

    // Apply category filter
    if (_selectedCategory != 'All') {
      results = results.where((p) => p.category == _selectedCategory).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      results = results.where((p) => p.name.toLowerCase().contains(query) || p.description.toLowerCase().contains(query)).toList();
    }

    // Apply sorting
    if (_sortBy == 'PriceLowToHigh') {
      results.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'PriceHighToLow') {
      results.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'Popularity') {
      results.sort((a, b) => b.rating.compareTo(a.rating));
    }

    _filteredProducts = results;
    notifyListeners();
  }

  Product getProductById(int id) {
    return _allProducts.firstWhere((p) => p.id == id);
  }
}
