class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:8000';
  static const String apiUrl = '$baseUrl/api';
  static const String wsUrl = 'ws://localhost:8000/ws';
  
  // Supabase Configuration
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // Stripe Configuration
  static const String stripePublishableKey = 'YOUR_STRIPE_PUBLISHABLE_KEY';
  
  // App Configuration
  static const String appName = 'Restaurant Ordering';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String restaurantKey = 'restaurant_data';
  static const String tableKey = 'table_data';
  
  // Order Status
  static const String orderStatusPending = 'pending';
  static const String orderStatusConfirmed = 'confirmed';
  static const String orderStatusInProgress = 'in_progress';
  static const String orderStatusReady = 'ready';
  static const String orderStatusServed = 'served';
  static const String orderStatusCancelled = 'cancelled';
  
  // Payment Methods
  static const String paymentMethodMpesa = 'mpesa';
  static const String paymentMethodCard = 'card';
  static const String paymentMethodCash = 'cash';
  
  // User Roles
  static const String roleCustomer = 'customer';
  static const String roleWaiter = 'waiter';
  static const String roleKitchen = 'kitchen';
  static const String roleAdmin = 'admin';
  
  // Service Request Types
  static const String serviceRequestWater = 'water';
  static const String serviceRequestBill = 'bill';
  static const String serviceRequestAssistance = 'assistance';
  static const String serviceRequestCleanup = 'cleanup';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
}

