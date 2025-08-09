import 'menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  final int quantity;
  final String? specialInstructions;

  CartItem({
    required this.menuItem,
    required this.quantity,
    this.specialInstructions,
  });

  CartItem copyWith({
    MenuItem? menuItem,
    int? quantity,
    String? specialInstructions,
  }) {
    return CartItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  double get totalPrice => menuItem.price * quantity;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.menuItem == menuItem &&
        other.quantity == quantity &&
        other.specialInstructions == specialInstructions;
  }

  @override
  int get hashCode {
    return Object.hash(menuItem, quantity, specialInstructions);
  }

  @override
  String toString() {
    return 'CartItem(menuItem: $menuItem, quantity: $quantity, specialInstructions: $specialInstructions)';
  }
}

