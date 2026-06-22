import 'package:flutter/material.dart';
import 'package:prm_project/models/product.dart';

class ProductViewModel extends ChangeNotifier {
  final List<Product> _allProducts = [
    Product(
      id: 1,
      name: 'iPhone 15 Pro Max',
      description: 'Chiếc iPhone đỉnh cao với thiết kế titan siêu bền và nhẹ, nút Tác vụ mới, nâng cấp camera mạnh mẽ và chip A17 Pro cho trải nghiệm chơi game và làm việc vượt trội.',
      price: 29990000.0,
      imageUrl: 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=500&auto=format&fit=crop&q=60',
      rating: 4.8,
      category: 'Điện thoại',
      reviews: [
        ProductReview(userName: 'Anh Tuấn', rating: 5.0, comment: 'Chất lượng hoàn thiện tuyệt vời! Khung viền titan cho cảm giác cầm rất cao cấp và thời lượng pin cực kỳ trâu.', date: '2026-06-10'),
        ProductReview(userName: 'Vy Nguyễn', rating: 4.5, comment: 'Camera chụp ảnh xuất sắc, khả năng zoom xa rất ấn tượng. Máy hơi nặng một chút nhưng màn hình hiển thị thì siêu đẹp.', date: '2026-06-15'),
      ],
    ),
    Product(
      id: 2,
      name: 'MacBook Pro M3 Max',
      description: 'Sức mạnh vượt trội từ chip M3 Max, được tối ưu hóa cho các tác vụ xử lý cực nặng, dựng hình 3D và biên tập video chuyên nghiệp. Màn hình Liquid Retina XDR sắc nét.',
      price: 69990000.0,
      imageUrl: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=500&auto=format&fit=crop&q=60',
      rating: 4.9,
      category: 'Laptop',
      reviews: [
        ProductReview(userName: 'Duy Khánh', rating: 5.0, comment: 'Một con quái vật thực sự. Xuất video 4K siêu nhanh mà máy vẫn chạy cực kỳ êm ái, quạt tản nhiệt hầu như không cần quay.', date: '2026-05-20'),
        ProductReview(userName: 'Mai Phương', rating: 4.8, comment: 'Màn hình laptop đẹp nhất mà tôi từng trải nghiệm. Giá hơi đắt đỏ nhưng hoàn toàn xứng đáng với hiệu năng mang lại.', date: '2026-06-02'),
      ],
    ),
    Product(
      id: 3,
      name: 'Sony WH-1000XM5',
      description: 'Tai nghe chống ồn đỉnh cao hàng đầu thế giới với bộ xử lý kép, 8 micrô và tính năng Auto NC Optimizer. Mang lại chất lượng âm thanh cuộc gọi sắc nét và âm thanh không dây tuyệt hảo.',
      price: 2000.0,
      imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500&auto=format&fit=crop&q=60',
      rating: 4.7,
      category: 'Âm thanh',
      reviews: [
        ProductReview(userName: 'Minh Quân', rating: 5.0, comment: 'Chống ồn đỉnh chóp, đeo vào như bước vào thế giới khác. Âm trầm sâu lắng, âm trung và cao cực kỳ trong trẻo.', date: '2026-06-18'),
      ],
    ),
    Product(
      id: 4,
      name: 'Apple Watch Ultra 2',
      description: 'Dòng Apple Watch bền bỉ và mạnh mẽ nhất hiện nay. Được thiết kế chuyên biệt cho các hoạt động thám hiểm ngoài trời và thể thao bền bỉ, với vỏ titan siêu nhẹ và thời lượng pin vượt trội.',
      price: 19990000.0,
      imageUrl: 'https://images.unsplash.com/photo-1434494878577-86c23bcb06b9?w=500&auto=format&fit=crop&q=60',
      rating: 4.6,
      category: 'Thiết bị đeo',
      reviews: [
        ProductReview(userName: 'Hoàng Nam', rating: 4.0, comment: 'Cực kỳ bền bỉ, pin dùng thoải mái 3 ngày liền. Tuy nhiên kích thước hơi to so với người có cổ tay nhỏ.', date: '2026-06-11'),
      ],
    ),
    Product(
      id: 5,
      name: 'Keychron Q1 Pro',
      description: 'Bàn phím cơ núm xoay cao cấp hỗ trợ custom hoàn toàn qua QMK/VIA. Thiết kế double-gasket êm ái, vỏ nhôm nguyên khối CNC sắc sảo và hỗ trợ kết nối không dây tiện lợi.',
      price: 4990000.0,
      imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=500&auto=format&fit=crop&q=60',
      rating: 4.8,
      category: 'Phụ kiện',
      reviews: [
        ProductReview(userName: 'Lâm Phong', rating: 5.0, comment: 'Cảm giác gõ phím cực kỳ đầm tay và âm thanh rất cuốn. Build chắc chắn như một khối thép.', date: '2026-06-05'),
      ],
    ),
    Product(
      id: 6,
      name: 'Dell UltraSharp 32" 4K',
      description: 'Trải nghiệm độ chính xác màu sắc và độ tương phản tuyệt vời với màn hình chuyên nghiệp 32 inch 4K USB-C Hub, được thiết kế cho các nhà sáng tạo nội dung và thiết kế đồ họa.',
      price: 22490000.0,
      imageUrl: 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=500&auto=format&fit=crop&q=60',
      rating: 4.5,
      category: 'Màn hình',
      reviews: [],
    ),
    Product(
      id: 7,
      name: 'Loa JBL Charge 5',
      description: 'Mang âm nhạc cùng bạn đi khắp nơi. JBL Charge 5 mang đến âm thanh JBL Original Pro mạnh mẽ, với củ loa excursion tối ưu, loa tweeter độc lập và bộ tản âm trầm kép.',
      price: 4490000.0,
      imageUrl: 'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=500&auto=format&fit=crop&q=60',
      rating: 4.6,
      category: 'Âm thanh',
      reviews: [
        ProductReview(userName: 'Thanh Hải', rating: 4.8, comment: 'Âm thanh lớn, bass căng, còn có thể sạc pin cho điện thoại khi cần. Rất phù hợp đem đi dã ngoại hoặc du lịch biển.', date: '2026-05-12'),
      ],
    ),
    Product(
      id: 8,
      name: 'Máy hút bụi Dyson V15 Detect',
      description: 'Dòng máy hút bụi không dây thông minh và mạnh mẽ nhất của Dyson. Tích hợp tia laser giúp phát hiện bụi bẩn siêu nhỏ và tự động điều chỉnh lực hút theo loại sàn.',
      price: 18490000.0,
      imageUrl: 'https://images.unsplash.com/photo-1558317374-067fb5f30001?w=500&auto=format&fit=crop&q=60',
      rating: 4.7,
      category: 'Nhà thông minh',
      reviews: [
        ProductReview(userName: 'Hồng Hạnh', rating: 5.0, comment: 'Tia laser quét bụi rất đỉnh, soi ra được rất nhiều bụi mịn mà mắt thường không thấy. Vệ sinh hộp bụi cũng rất dễ dàng.', date: '2026-06-08'),
      ],
    ),
  ];

  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';
  String _sortBy = 'Popularity'; // Popularity, PriceLowToHigh, PriceHighToLow

  List<Product> get products => _filteredProducts.isEmpty && _searchQuery.isEmpty && _selectedCategory == 'Tất cả' && _sortBy == 'Popularity'
      ? _allProducts
      : _filteredProducts;

  List<Product> get allProducts => _allProducts;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;

  List<String> get categories {
    final list = _allProducts.map((p) => p.category).toSet().toList();
    list.sort();
    return ['Tất cả', ...list];
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
    if (_selectedCategory != 'Tất cả') {
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
