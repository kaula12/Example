class OrderItem {
  final int menuItemId;
  final int quantity;
  final String? specialInstructions;
  final String? menuItemName;
  final double? menuItemPrice;

  OrderItem({
    required this.menuItemId,
    required this.quantity,
    this.specialInstructions,
    this.menuItemName,
    this.menuItemPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menu_item_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      specialInstructions: json['special_instructions'],
      menuItemName: json['menu_items']?['name'],
      menuItemPrice: json['menu_items']?['price']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menu_item_id': menuItemId,
      'quantity': quantity,
      'special_instructions': specialInstructions,
    };
  }

  OrderItem copyWith({
    int? menuItemId,
    int? quantity,
    String? specialInstructions,
    String? menuItemName,
    double? menuItemPrice,
  }) {
    return OrderItem(
      menuItemId: menuItemId ?? this.menuItemId,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      menuItemName: menuItemName ?? this.menuItemName,
      menuItemPrice: menuItemPrice ?? this.menuItemPrice,
    );
  }

  double get totalPrice => (menuItemPrice ?? 0) * quantity;
}

class Order {
  final int? id;
  final int tableNumber;
  final List<OrderItem> items;
  final String status;
  final double totalAmount;
  final String? customerName;
  final String? specialInstructions;
  final DateTime? createdAt;
  final String? paymentStatus;

  Order({
    this.id,
    required this.tableNumber,
    required this.items,
    this.status = 'pending',
    required this.totalAmount,
    this.customerName,
    this.specialInstructions,
    this.createdAt,
    this.paymentStatus,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> orderItems = [];
    
    if (json['order_items'] != null) {
      orderItems = (json['order_items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList();
    } else if (json['items'] != null) {
      orderItems = (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList();
    }

    return Order(
      id: json['id'],
      tableNumber: json['table_number'] ?? 0,
      items: orderItems,
      status: json['status'] ?? 'pending',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      customerName: json['customer_name'],
      specialInstructions: json['special_instructions'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      paymentStatus: json['payment_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'table_number': tableNumber,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status,
      'total_amount': totalAmount,
      'customer_name': customerName,
      'special_instructions': specialInstructions,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'payment_status': paymentStatus,
    };
  }

  Order copyWith({
    int? id,
    int? tableNumber,
    List<OrderItem>? items,
    String? status,
    double? totalAmount,
    String? customerName,
    String? specialInstructions,
    DateTime? createdAt,
    String? paymentStatus,
  }) {
    return Order(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      items: items ?? this.items,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      customerName: customerName ?? this.customerName,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      createdAt: createdAt ?? this.createdAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'served':
        return 'Served';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool get isPaid => paymentStatus == 'paid';
  bool get isCompleted => status == 'served' || status == 'cancelled';
}

