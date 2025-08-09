import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/customer/presentation/screens/table_selection_screen.dart';
import '../../features/customer/presentation/screens/menu_screen.dart';
import '../../features/customer/presentation/screens/cart_screen.dart';
import '../../features/customer/presentation/screens/order_tracking_screen.dart';
import '../../features/waiter/presentation/screens/waiter_dashboard_screen.dart';
import '../../features/kitchen/presentation/screens/kitchen_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/menu_management_screen.dart';
import '../../features/admin/presentation/screens/table_management_screen.dart';
import '../../features/admin/presentation/screens/analytics_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Home Route
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      
      // Customer Routes
      GoRoute(
        path: '/customer/table-selection',
        name: 'table-selection',
        builder: (context, state) => const TableSelectionScreen(),
      ),
      GoRoute(
        path: '/customer/menu/:tableNumber',
        name: 'menu',
        builder: (context, state) {
          final tableNumber = int.parse(state.pathParameters['tableNumber']!);
          return MenuScreen(tableNumber: tableNumber);
        },
      ),
      GoRoute(
        path: '/customer/cart/:tableNumber',
        name: 'cart',
        builder: (context, state) {
          final tableNumber = int.parse(state.pathParameters['tableNumber']!);
          return CartScreen(tableNumber: tableNumber);
        },
      ),
      GoRoute(
        path: '/customer/order-tracking/:orderId',
        name: 'order-tracking',
        builder: (context, state) {
          final orderId = int.parse(state.pathParameters['orderId']!);
          return OrderTrackingScreen(orderId: orderId);
        },
      ),
      
      // Waiter Routes
      GoRoute(
        path: '/waiter/dashboard',
        name: 'waiter-dashboard',
        builder: (context, state) => const WaiterDashboardScreen(),
      ),
      
      // Kitchen Routes
      GoRoute(
        path: '/kitchen/dashboard',
        name: 'kitchen-dashboard',
        builder: (context, state) => const KitchenDashboardScreen(),
      ),
      
      // Admin Routes
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/menu-management',
        name: 'menu-management',
        builder: (context, state) => const MenuManagementScreen(),
      ),
      GoRoute(
        path: '/admin/table-management',
        name: 'table-management',
        builder: (context, state) => const TableManagementScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.location}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

