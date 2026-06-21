class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final double rating;
  final String category;
  final List<ProductReview> reviews;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.rating,
    required this.category,
    required this.reviews,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'rating': rating,
      'category': category,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, {List<ProductReview> reviews = const []}) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String,
      rating: (map['rating'] as num).toDouble(),
      category: map['category'] as String,
      reviews: reviews,
    );
  }
}

class ProductReview {
  final String userName;
  final double rating;
  final String comment;
  final String date;

  ProductReview({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}
