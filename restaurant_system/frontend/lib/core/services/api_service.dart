import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/table.dart';

class ApiService {
  static const String baseUrl = AppConfig.baseUrl;
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
  };

  // Menu API calls
  static Future<List<MenuItem>> getMenu() async {
    final response = await http.get(
      Uri.parse('$baseUrl${AppConfig.menuEndpoint}'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => MenuItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load menu');
    }
  }

  static Future<List<String>> getMenuCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl${AppConfig.menuEndpoint}/categories'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['categories']);
    } else {
      throw Exception('Failed to load categories');
    }
  }

  static Future<List<MenuItem>> getMenuByCategory(String category) async {
    final response = await http.get(
      Uri.parse('$baseUrl${AppConfig.menuEndpoint}/category/$category'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => MenuItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load menu by category');
    }
  }

  static Future<MenuItem> createMenuItem(MenuItem item) async {
    final response = await http.post(
      Uri.parse('$baseUrl${AppConfig.menuEndpoint}'),
      headers: headers,
      body: json.encode(item.toJson()),
    );
    
    if (response.statusCode == 200) {
      return MenuItem.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create menu item');
    }
  }

  static Future<MenuItem> updateMenuItem(int id, MenuItem item) async {
    final response = await http.put(
      Uri.parse('$baseUrl${AppConfig.menuEndpoint}/$id'),
      headers: headers,
      body: json.encode(item.toJson()),
    );
    
    if (response.statusCode == 200) {
      return MenuItem.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update menu item');
    }
  }

  static Future<void> deleteMenuItem(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl${AppConfig.menuEndpoint}/$id'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete menu item');
    }
  }

  // Order API calls
  static Future<Order> createOrder(Order order) async {
    final response = await http.post(
      Uri.parse('$baseUrl${AppConfig.ordersEndpoint}'),
      headers: headers,
      body: json.encode(order.toJson()),
    );
    
    if (response.statusCode == 200) {
      return Order.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create order');
    }
  }

  static Future<List<Order>> getOrders({String? status, int? tableNumber}) async {
    String url = '$baseUrl${AppConfig.ordersEndpoint}';
    List<String> queryParams = [];
    
    if (status != null) queryParams.add('status=$status');
    if (tableNumber != null) queryParams.add('table_number=$tableNumber');
    
    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }
    
    final response = await http.get(Uri.parse(url), headers: headers);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Order.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  static Future<Order> getOrder(int orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl${AppConfig.ordersEndpoint}/$orderId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return Order.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load order');
    }
  }

  static Future<Order> updateOrderStatus(int orderId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl${AppConfig.ordersEndpoint}/$orderId/status'),
      headers: headers,
      body: json.encode({'status': status}),
    );
    
    if (response.statusCode == 200) {
      return Order.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update order status');
    }
  }

  // Table API calls
  static Future<List<RestaurantTable>> getTables() async {
    final response = await http.get(
      Uri.parse('$baseUrl${AppConfig.tablesEndpoint}'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => RestaurantTable.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load tables');
    }
  }

  static Future<RestaurantTable> createTable(RestaurantTable table) async {
    final response = await http.post(
      Uri.parse('$baseUrl${AppConfig.tablesEndpoint}'),
      headers: headers,
      body: json.encode(table.toJson()),
    );
    
    if (response.statusCode == 200) {
      return RestaurantTable.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create table');
    }
  }

  static Future<void> assignWaiterToTable(int tableNumber, int waiterId) async {
    final response = await http.put(
      Uri.parse('$baseUrl${AppConfig.tablesEndpoint}/$tableNumber/assign-waiter'),
      headers: headers,
      body: json.encode({'waiter_id': waiterId}),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to assign waiter to table');
    }
  }

  // Waiter Alert API calls
  static Future<void> sendWaiterAlert(int tableNumber, String message, {String alertType = 'customer_request'}) async {
    final response = await http.post(
      Uri.parse('$baseUrl${AppConfig.waiterAlertsEndpoint}'),
      headers: headers,
      body: json.encode({
        'table_number': tableNumber,
        'message': message,
        'alert_type': alertType,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to send waiter alert');
    }
  }

  static Future<List<dynamic>> getWaiterAlerts({int? waiterId}) async {
    String url = '$baseUrl${AppConfig.waiterAlertsEndpoint}';
    if (waiterId != null) {
      url += '?waiter_id=$waiterId';
    }
    
    final response = await http.get(Uri.parse(url), headers: headers);
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load waiter alerts');
    }
  }

  // Payment API calls
  static Future<Map<String, dynamic>> processPayment(int orderId, double amount, String paymentMethod) async {
    final response = await http.post(
      Uri.parse('$baseUrl${AppConfig.paymentsEndpoint}'),
      headers: headers,
      body: json.encode({
        'order_id': orderId,
        'amount': amount,
        'payment_method': paymentMethod,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to process payment');
    }
  }

  // Analytics API calls
  static Future<Map<String, dynamic>> getDailySales() async {
    final response = await http.get(
      Uri.parse('$baseUrl${AppConfig.analyticsEndpoint}/daily-sales'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load daily sales');
    }
  }

  static Future<Map<String, dynamic>> getPopularItems() async {
    final response = await http.get(
      Uri.parse('$baseUrl${AppConfig.analyticsEndpoint}/popular-items'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load popular items');
    }
  }

  // FCM Token registration
  static Future<void> registerFCMToken(String token, String role, {int? userId, String? deviceId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl${AppConfig.fcmTokenEndpoint}'),
      headers: headers,
      body: json.encode({
        'user_id': userId,
        'fcm_token': token,
        'role': role,
        'device_id': deviceId,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to register FCM token');
    }
  }
}

