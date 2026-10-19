class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.thumbnail,
    required this.images,
    required this.category,
    this.brand,
    this.reviews = const [],
  });

  final int id;
  final String title;
  final String description;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String thumbnail;
  final List<String> images;
  final String category;
  final String? brand;
  final List<ProductReview> reviews;

  double get salePrice => price * (1 - discountPercentage / 100);
  bool get isInStock => stock > 0;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: json['title']?.toString() ?? 'Untitled product',
    description: json['description']?.toString() ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0,
    discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    stock: (json['stock'] as num?)?.toInt() ?? 0,
    thumbnail: json['thumbnail']?.toString() ?? '',
    images: (json['images'] as List<dynamic>? ?? const [])
        .map((image) => image.toString())
        .toList(),
    category: json['category']?.toString() ?? '',
    brand: json['brand']?.toString(),
    reviews: (json['reviews'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (review) => ProductReview.fromJson(Map<String, dynamic>.from(review)),
        )
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'price': price,
    'discountPercentage': discountPercentage,
    'rating': rating,
    'stock': stock,
    'thumbnail': thumbnail,
    'images': images,
    'category': category,
    if (brand != null) 'brand': brand,
    'reviews': reviews.map((review) => review.toJson()).toList(),
  };
}

class ProductReview {
  const ProductReview({
    required this.rating,
    required this.comment,
    required this.reviewerName,
    required this.date,
  });

  final double rating;
  final String comment;
  final String reviewerName;
  final String date;

  factory ProductReview.fromJson(Map<String, dynamic> json) => ProductReview(
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    comment: json['comment']?.toString() ?? '',
    reviewerName: json['reviewerName']?.toString() ?? 'Customer',
    date: json['date']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'rating': rating,
    'comment': comment,
    'reviewerName': reviewerName,
    'date': date,
  };
}

class ProductsPage {
  const ProductsPage({
    required this.products,
    required this.total,
    this.isOfflineCache = false,
  });

  final List<Product> products;
  final int total;
  final bool isOfflineCache;

  ProductsPage fromCache() =>
      ProductsPage(products: products, total: total, isOfflineCache: true);

  Map<String, dynamic> toCacheJson() => {
    'products': products.map((product) => product.toJson()).toList(),
    'total': total,
  };

  factory ProductsPage.fromJson(Map<String, dynamic> json) => ProductsPage(
    products: (json['products'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((product) => Product.fromJson(Map<String, dynamic>.from(product)))
        .toList(),
    total: (json['total'] as num?)?.toInt() ?? 0,
  );
}
