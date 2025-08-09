import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/menu_screen.dart';
import '../screens/item_detail_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/order_tracking_screen.dart';
import '../screens/kitchen_dashboard.dart';
import '../screens/admin_dashboard.dart';
import '../screens/menu_management_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/profile_screen.dart';
import 'providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.user != null;
      final isLoading = authState.isLoading;
      
      // Show splash screen while loading
      if (isLoading) {
        return '/';
      }
      
      // Public routes that don't require authentication
      final publicRoutes = [
        '/',
        '/login',
        '/register',
        '/qr-scanner',
      ];
      
      final isPublicRoute = publicRoutes.contains(state.location) ||
          state.location.startsWith('/menu/') ||
          state.location.startsWith('/item/');
      
      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }
      
      // If authenticated and on auth pages, redirect to appropriate dashboard
      if (isAuthenticated && (state.location == '/login' || state.location == '/register')) {
        final user = authState.user!;
        switch (user.role) {
          case 'admin':
            return '/admin';
          case 'kitchen':
            return '/kitchen';
          case 'waiter':
            return '/kitchen'; // Waiters also use kitchen dashboard
          default:
            return '/qr-scanner';
        }
      }
      
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Authentication Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Customer Routes
      GoRoute(
        path: '/qr-scanner',
        builder: (context, state) => const QRScannerScreen(),
      ),
      GoRoute(
        path: '/menu/:restaurantId/:tableId',
        builder: (context, state) {
          final restaurantId = int.parse(state.pathParameters['restaurantId']!);
          final tableId = int.parse(state.pathParameters['tableId']!);
          return MenuScreen(
            restaurantId: restaurantId,
            tableId: tableId,
          );
        },
      ),
      GoRoute(
        path: '/item/:itemId',
        builder: (context, state) {
          final itemId = int.parse(state.pathParameters['itemId']!);
          final restaurantId = int.tryParse(state.queryParameters['restaurantId'] ?? '');
          final tableId = int.tryParse(state.queryParameters['tableId'] ?? '');
          return ItemDetailScreen(
            itemId: itemId,
            restaurantId: restaurantId,
            tableId: tableId,
          );
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) {
          final restaurantId = int.tryParse(state.queryParameters['restaurantId'] ?? '');
          final tableId = int.tryParse(state.queryParameters['tableId'] ?? '');
          return CartScreen(
            restaurantId: restaurantId,
            tableId: tableId,
          );
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) {
          final restaurantId = int.parse(state.queryParameters['restaurantId']!);
          final tableId = int.parse(state.queryParameters['tableId']!);
          return CheckoutScreen(
            restaurantId: restaurantId,
            tableId: tableId,
          );
        },
      ),
      GoRoute(
        path: '/order-tracking/:orderId',
        builder: (context, state) {
          final orderId = int.parse(state.pathParameters['orderId']!);
          return OrderTrackingScreen(orderId: orderId);
        },
      ),
      
      // Kitchen/Staff Routes
      GoRoute(
        path: '/kitchen',
        builder: (context, state) => const KitchenDashboard(),
      ),
      
      // Admin Routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/menu/:restaurantId',
        builder: (context, state) {
          final restaurantId = int.parse(state.pathParameters['restaurantId']!);
          return MenuManagementScreen(restaurantId: restaurantId);
        },
      ),
      GoRoute(
        path: '/admin/analytics/:restaurantId',
        builder: (context, state) {
          final restaurantId = int.parse(state.pathParameters['restaurantId']!);
          return AnalyticsScreen(restaurantId: restaurantId);
        },
      ),
      
      // Profile Route
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
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

