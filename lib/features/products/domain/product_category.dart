class ProductCategory {
  const ProductCategory({required this.slug, required this.name});

  final String slug;
  final String name;

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      ProductCategory(
        slug: json['slug']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );
}
