import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';
import '../models/models.dart';
import 'constants.dart';

// Core service providers
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthService(apiService);
});

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});

// Shared preferences provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Auth state providers
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthStateNotifier(authService);
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user;
});

// Restaurant and table providers
final restaurantProvider = StateProvider<Restaurant?>((ref) => null);
final tableProvider = StateProvider<RestaurantTable?>((ref) => null);

// Menu providers
final menuProvider = FutureProvider.family<MenuResponse, int>((ref, restaurantId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getMenu(restaurantId);
});

final categoriesProvider = FutureProvider.family<List<Category>, int>((ref, restaurantId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getCategories(restaurantId);
});

final menuItemsProvider = FutureProvider.family<List<MenuItem>, MenuItemsParams>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getMenuItems(
    params.restaurantId,
    categoryId: params.categoryId,
    isVegetarian: params.isVegetarian,
    isVegan: params.isVegan,
    isGlutenFree: params.isGlutenFree,
  );
});

// Cart provider
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

// Orders provider
final ordersProvider = FutureProvider.family<List<Order>, OrdersParams>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getOrders(
    restaurantId: params.restaurantId,
    status: params.status,
    limit: params.limit,
  );
});

final orderProvider = FutureProvider.family<Order, int>((ref, orderId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getOrder(orderId);
});

// Kitchen orders provider
final kitchenOrdersProvider = FutureProvider.family<List<Order>, int>((ref, restaurantId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getKitchenOrders(restaurantId);
});

// WebSocket messages provider
final webSocketMessagesProvider = StreamProvider<WebSocketMessage>((ref) {
  final webSocketService = ref.watch(webSocketServiceProvider);
  return webSocketService.messageStream;
});

// UI state providers
final selectedCategoryProvider = StateProvider<int?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
final isLoadingProvider = StateProvider<bool>((ref) => false);

// Auth State
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Auth State Notifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthStateNotifier(this._authService) : super(AuthState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.initialize();
      state = state.copyWith(
        user: _authService.currentUser,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.signIn(email: email, password: password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.signOut();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Cart Notifier
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(MenuItem menuItem, {
    int quantity = 1,
    Map<String, dynamic> customizations = const {},
    String? specialInstructions,
  }) {
    final existingIndex = state.indexWhere((item) => 
      item.menuItem.id == menuItem.id &&
      _mapsEqual(item.customizations, customizations)
    );

    if (existingIndex >= 0) {
      // Update existing item
      final updatedItems = [...state];
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + quantity,
      );
      state = updatedItems;
    } else {
      // Add new item
      state = [
        ...state,
        CartItem(
          menuItem: menuItem,
          quantity: quantity,
          customizations: customizations,
          specialInstructions: specialInstructions,
        ),
      ];
    }
  }

  void updateItem(int index, CartItem updatedItem) {
    if (index >= 0 && index < state.length) {
      final updatedItems = [...state];
      updatedItems[index] = updatedItem;
      state = updatedItems;
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < state.length) {
      state = [...state]..removeAt(index);
    }
  }

  void clearCart() {
    state = [];
  }

  double get subtotal {
    return state.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get taxAmount {
    return subtotal * 0.16; // 16% VAT
  }

  double get serviceCharge {
    return subtotal * 0.10; // 10% service charge
  }

  double get total {
    return subtotal + taxAmount + serviceCharge;
  }

  int get itemCount {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }

  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }
}

// Parameter classes for providers
class MenuItemsParams {
  final int restaurantId;
  final int? categoryId;
  final bool? isVegetarian;
  final bool? isVegan;
  final bool? isGlutenFree;

  MenuItemsParams({
    required this.restaurantId,
    this.categoryId,
    this.isVegetarian,
    this.isVegan,
    this.isGlutenFree,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItemsParams &&
          runtimeType == other.runtimeType &&
          restaurantId == other.restaurantId &&
          categoryId == other.categoryId &&
          isVegetarian == other.isVegetarian &&
          isVegan == other.isVegan &&
          isGlutenFree == other.isGlutenFree;

  @override
  int get hashCode =>
      restaurantId.hashCode ^
      categoryId.hashCode ^
      isVegetarian.hashCode ^
      isVegan.hashCode ^
      isGlutenFree.hashCode;
}

class OrdersParams {
  final int? restaurantId;
  final String? status;
  final int limit;

  OrdersParams({
    this.restaurantId,
    this.status,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrdersParams &&
          runtimeType == other.runtimeType &&
          restaurantId == other.restaurantId &&
          status == other.status &&
          limit == other.limit;

  @override
  int get hashCode => restaurantId.hashCode ^ status.hashCode ^ limit.hashCode;
}

