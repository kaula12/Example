class MenuItem {
  final int? id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? imageUrl;
  final bool available;

  MenuItem({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    this.available = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      imageUrl: json['image_url'],
      available: json['available'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image_url': imageUrl,
      'available': available,
    };
  }

  MenuItem copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    bool? available,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      available: available ?? this.available,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MenuItem &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.price == price &&
        other.category == category &&
        other.imageUrl == imageUrl &&
        other.available == available;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      price,
      category,
      imageUrl,
      available,
    );
  }

  @override
  String toString() {
    return 'MenuItem(id: $id, name: $name, description: $description, price: $price, category: $category, imageUrl: $imageUrl, available: $available)';
  }
}

