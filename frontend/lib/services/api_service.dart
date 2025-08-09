import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/models.dart';

class ApiService {
  late final Dio _dio;
  String? _authToken;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        print('API Error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  // Authentication
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post('/auth/register', data: userData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return User.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> supabaseAuth(String token) async {
    try {
      final response = await _dio.post('/auth/supabase-auth', data: {
        'token': token,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Menu
  Future<QRCodeResponse> scanQRCode(String qrCode) async {
    try {
      final response = await _dio.get('/menu/qr/$qrCode');
      return QRCodeResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<MenuResponse> getMenu(int restaurantId) async {
    try {
      final response = await _dio.get('/menu/restaurant/$restaurantId');
      return MenuResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Category>> getCategories(int restaurantId) async {
    try {
      final response = await _dio.get('/menu/categories/$restaurantId');
      return (response.data as List)
          .map((e) => Category.fromJson(e))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<MenuItem>> getMenuItems(
    int restaurantId, {
    int? categoryId,
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (isVegetarian != null) queryParams['is_vegetarian'] = isVegetarian;
      if (isVegan != null) queryParams['is_vegan'] = isVegan;
      if (isGlutenFree != null) queryParams['is_gluten_free'] = isGlutenFree;

      final response = await _dio.get(
        '/menu/items/$restaurantId',
        queryParameters: queryParams,
      );
      return (response.data as List)
          .map((e) => MenuItem.fromJson(e))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<MenuItem> getMenuItem(int itemId) async {
    try {
      final response = await _dio.get('/menu/item/$itemId');
      return MenuItem.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<MenuItem>> searchMenuItems(int restaurantId, String query) async {
    try {
      final response = await _dio.get(
        '/menu/search/$restaurantId',
        queryParameters: {'q': query},
      );
      return (response.data as List)
          .map((e) => MenuItem.fromJson(e))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Orders
  Future<Order> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await _dio.post('/orders/', data: orderData);
      return Order.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Order>> getOrders({
    int? restaurantId,
    String? status,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (restaurantId != null) queryParams['restaurant_id'] = restaurantId;
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get('/orders/', queryParameters: queryParams);
      return (response.data as List)
          .map((e) => Order.fromJson(e))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Order> getOrder(int orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId');
      return Order.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Order> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await _dio.put('/orders/$orderId/status', data: {
        'status': status,
      });
      return Order.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Order>> getKitchenOrders(int restaurantId) async {
    try {
      final response = await _dio.get('/orders/kitchen/$restaurantId');
      return (response.data as List)
          .map((e) => Order.fromJson(e))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Service Requests
  Future<Map<String, dynamic>> createServiceRequest(Map<String, dynamic> requestData) async {
    try {
      final response = await _dio.post('/orders/service-request', data: requestData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getServiceRequests(
    int restaurantId, {
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/orders/service-requests/$restaurantId',
        queryParameters: queryParams,
      );
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Payments
  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> paymentData) async {
    try {
      final response = await _dio.post('/payments/', data: paymentData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getOrderPayments(int orderId) async {
    try {
      final response = await _dio.get('/payments/order/$orderId');
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPayment(int paymentId) async {
    try {
      final response = await _dio.get('/payments/$paymentId');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getStripeConfig() async {
    try {
      final response = await _dio.get('/payments/stripe/config');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Admin
  Future<List<Map<String, dynamic>>> getRestaurants() async {
    try {
      final response = await _dio.get('/admin/restaurants');
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getAnalytics(int restaurantId, {int days = 30}) async {
    try {
      final response = await _dio.get(
        '/admin/analytics/$restaurantId',
        queryParameters: {'days': days},
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Error handling
  String _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['detail'] ?? 
                          error.response?.data?['message'] ?? 
                          'Server error occurred';
          return '$message (Status: $statusCode)';
        case DioExceptionType.cancel:
          return 'Request was cancelled';
        case DioExceptionType.unknown:
          return 'Network error. Please check your internet connection.';
        default:
          return 'An unexpected error occurred';
      }
    }
    return error.toString();
  }
}

