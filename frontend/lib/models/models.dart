// User Models
class User {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final bool isActive;
  final String? supabaseId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    required this.isActive,
    this.supabaseId,
    required this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      phone: json['phone'],
      role: json['role'],
      isActive: json['is_active'],
      supabaseId: json['supabase_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'is_active': isActive,
      'supabase_id': supabaseId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

// Restaurant Models
class Restaurant {
  final int id;
  final String name;
  final String? description;
  final String? address;
  final String? phone;
  final String? email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Restaurant({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.phone,
    this.email,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'phone': phone,
      'email': email,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

// Table Models
class RestaurantTable {
  final int id;
  final int restaurantId;
  final String tableNumber;
  final String qrCode;
  final int capacity;
  final bool isActive;
  final DateTime createdAt;

  RestaurantTable({
    required this.id,
    required this.restaurantId,
    required this.tableNumber,
    required this.qrCode,
    required this.capacity,
    required this.isActive,
    required this.createdAt,
  });

  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    return RestaurantTable(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      tableNumber: json['table_number'],
      qrCode: json['qr_code'],
      capacity: json['capacity'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'table_number': tableNumber,
      'qr_code': qrCode,
      'capacity': capacity,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Category Models
class Category {
  final int id;
  final int restaurantId;
  final String name;
  final String? description;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
      sortOrder: json['sort_order'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Menu Item Models
class MenuItem {
  final int id;
  final int restaurantId;
  final int categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final List<String>? ingredients;
  final List<String>? allergens;
  final Map<String, dynamic>? customizationOptions;
  final bool isAvailable;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final int preparationTime;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.ingredients,
    this.allergens,
    this.customizationOptions,
    required this.isAvailable,
    required this.isVegetarian,
    required this.isVegan,
    required this.isGlutenFree,
    required this.preparationTime,
    required this.sortOrder,
    required this.createdAt,
    this.updatedAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      imageUrl: json['image_url'],
      ingredients: json['ingredients']?.cast<String>(),
      allergens: json['allergens']?.cast<String>(),
      customizationOptions: json['customization_options'],
      isAvailable: json['is_available'],
      isVegetarian: json['is_vegetarian'],
      isVegan: json['is_vegan'],
      isGlutenFree: json['is_gluten_free'],
      preparationTime: json['preparation_time'],
      sortOrder: json['sort_order'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'ingredients': ingredients,
      'allergens': allergens,
      'customization_options': customizationOptions,
      'is_available': isAvailable,
      'is_vegetarian': isVegetarian,
      'is_vegan': isVegan,
      'is_gluten_free': isGlutenFree,
      'preparation_time': preparationTime,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

// Cart Models (Local only)
class CartItem {
  final MenuItem menuItem;
  int quantity;
  Map<String, dynamic> customizations;
  String? specialInstructions;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.customizations = const {},
    this.specialInstructions,
  });

  double get totalPrice => menuItem.price * quantity;

  CartItem copyWith({
    MenuItem? menuItem,
    int? quantity,
    Map<String, dynamic>? customizations,
    String? specialInstructions,
  }) {
    return CartItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      customizations: customizations ?? this.customizations,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}

// QR Code Response
class QRCodeResponse {
  final int restaurantId;
  final int tableId;
  final String tableNumber;
  final String restaurantName;

  QRCodeResponse({
    required this.restaurantId,
    required this.tableId,
    required this.tableNumber,
    required this.restaurantName,
  });

  factory QRCodeResponse.fromJson(Map<String, dynamic> json) {
    return QRCodeResponse(
      restaurantId: json['restaurant_id'],
      tableId: json['table_id'],
      tableNumber: json['table_number'],
      restaurantName: json['restaurant_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurant_id': restaurantId,
      'table_id': tableId,
      'table_number': tableNumber,
      'restaurant_name': restaurantName,
    };
  }
}

// Menu Response
class MenuResponse {
  final List<Category> categories;
  final List<MenuItem> items;

  MenuResponse({
    required this.categories,
    required this.items,
  });

  factory MenuResponse.fromJson(Map<String, dynamic> json) {
    return MenuResponse(
      categories: (json['categories'] as List)
          .map((e) => Category.fromJson(e))
          .toList(),
      items: (json['items'] as List)
          .map((e) => MenuItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((e) => e.toJson()).toList(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

// Order Models
class OrderItem {
  final int id;
  final int orderId;
  final int menuItemId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Map<String, dynamic>? customizations;
  final String? specialInstructions;
  final DateTime createdAt;
  final MenuItem menuItem;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.customizations,
    this.specialInstructions,
    required this.createdAt,
    required this.menuItem,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      menuItemId: json['menu_item_id'],
      quantity: json['quantity'],
      unitPrice: json['unit_price'].toDouble(),
      totalPrice: json['total_price'].toDouble(),
      customizations: json['customizations'],
      specialInstructions: json['special_instructions'],
      createdAt: DateTime.parse(json['created_at']),
      menuItem: MenuItem.fromJson(json['menu_item']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'menu_item_id': menuItemId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'customizations': customizations,
      'special_instructions': specialInstructions,
      'created_at': createdAt.toIso8601String(),
      'menu_item': menuItem.toJson(),
    };
  }
}

class Order {
  final int id;
  final int restaurantId;
  final int tableId;
  final int customerId;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double taxAmount;
  final double serviceCharge;
  final double totalAmount;
  final String? specialInstructions;
  final int? estimatedPreparationTime;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OrderItem> orderItems;
  final RestaurantTable table;
  final User customer;

  Order({
    required this.id,
    required this.restaurantId,
    required this.tableId,
    required this.customerId,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    required this.serviceCharge,
    required this.totalAmount,
    this.specialInstructions,
    this.estimatedPreparationTime,
    required this.createdAt,
    this.updatedAt,
    required this.orderItems,
    required this.table,
    required this.customer,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      tableId: json['table_id'],
      customerId: json['customer_id'],
      orderNumber: json['order_number'],
      status: json['status'],
      subtotal: json['subtotal'].toDouble(),
      taxAmount: json['tax_amount'].toDouble(),
      serviceCharge: json['service_charge'].toDouble(),
      totalAmount: json['total_amount'].toDouble(),
      specialInstructions: json['special_instructions'],
      estimatedPreparationTime: json['estimated_preparation_time'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      orderItems: (json['order_items'] as List)
          .map((e) => OrderItem.fromJson(e))
          .toList(),
      table: RestaurantTable.fromJson(json['table']),
      customer: User.fromJson(json['customer']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'table_id': tableId,
      'customer_id': customerId,
      'order_number': orderNumber,
      'status': status,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'service_charge': serviceCharge,
      'total_amount': totalAmount,
      'special_instructions': specialInstructions,
      'estimated_preparation_time': estimatedPreparationTime,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'order_items': orderItems.map((e) => e.toJson()).toList(),
      'table': table.toJson(),
      'customer': customer.toJson(),
    };
  }
}

// WebSocket Message
class WebSocketMessage {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WebSocketMessage({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

