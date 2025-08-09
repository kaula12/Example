class RestaurantTable {
  final int? id;
  final int tableNumber;
  final int? waiterId;
  final String status;

  RestaurantTable({
    this.id,
    required this.tableNumber,
    this.waiterId,
    this.status = 'available',
  });

  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    return RestaurantTable(
      id: json['id'],
      tableNumber: json['table_number'] ?? 0,
      waiterId: json['waiter_id'],
      status: json['status'] ?? 'available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'table_number': tableNumber,
      'waiter_id': waiterId,
      'status': status,
    };
  }

  RestaurantTable copyWith({
    int? id,
    int? tableNumber,
    int? waiterId,
    String? status,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      waiterId: waiterId ?? this.waiterId,
      status: status ?? this.status,
    );
  }

  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Available';
      case 'occupied':
        return 'Occupied';
      case 'reserved':
        return 'Reserved';
      default:
        return status;
    }
  }

  bool get isAvailable => status == 'available';
  bool get isOccupied => status == 'occupied';
  bool get isReserved => status == 'reserved';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RestaurantTable &&
        other.id == id &&
        other.tableNumber == tableNumber &&
        other.waiterId == waiterId &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(id, tableNumber, waiterId, status);
  }

  @override
  String toString() {
    return 'RestaurantTable(id: $id, tableNumber: $tableNumber, waiterId: $waiterId, status: $status)';
  }
}

