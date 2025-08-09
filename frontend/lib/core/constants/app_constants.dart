class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:8000';
  static const String apiVersion = '/api';
  static const String wsUrl = 'ws://localhost:8000/ws';

  // Supabase Configuration
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Stripe Configuration
  static const String stripePublishableKey = 'YOUR_STRIPE_PUBLISHABLE_KEY';

  // App Configuration
  static const String appName = 'Restaurant Ordering System';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String cartKey = 'cart_data';
  static const String settingsKey = 'app_settings';

  // API Endpoints
  static const String authEndpoint = '$apiVersion/auth';
  static const String menuEndpoint = '$apiVersion/menu';
  static const String ordersEndpoint = '$apiVersion/orders';
  static const String paymentsEndpoint = '$apiVersion/payments';
  static const String adminEndpoint = '$apiVersion/admin';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Order Status
  static const List<String> orderStatuses = [
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'served',
    'cancelled'
  ];

  // Payment Methods
  static const List<String> paymentMethods = [
    'mpesa',
    'stripe',
    'cash'
  ];

  // Service Request Types
  static const List<String> serviceRequestTypes = [
    'water',
    'bill',
    'assistance',
    'cleanup'
  ];

  // User Roles
  static const List<String> userRoles = [
    'customer',
    'waiter',
    'kitchen',
    'admin'
  ];

  // Dietary Options
  static const List<String> dietaryOptions = [
    'vegetarian',
    'vegan',
    'gluten_free',
    'dairy_free',
    'nut_free'
  ];

  // Currency
  static const String currency = 'KES';
  static const String currencySymbol = 'KSh';

  // Tax & Service Charges
  static const double taxRate = 0.16; // 16% VAT
  static const double serviceChargeRate = 0.10; // 10% service charge

  // Image Placeholders
  static const String defaultRestaurantImage = 'assets/images/restaurant_placeholder.png';
  static const String defaultMenuItemImage = 'assets/images/menu_item_placeholder.png';
  static const String defaultUserAvatar = 'assets/images/user_avatar_placeholder.png';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;

  // QR Code
  static const String qrCodePrefix = 'QR_';
  static const double qrCodeSize = 200.0;

  // Map Configuration
  static const double defaultLatitude = -1.2921; // Nairobi
  static const double defaultLongitude = 36.8219; // Nairobi
  static const double mapZoom = 15.0;

  // Notification Settings
  static const String orderUpdateChannel = 'order_updates';
  static const String serviceRequestChannel = 'service_requests';
  static const String paymentUpdateChannel = 'payment_updates';

  // Error Messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String unknownErrorMessage = 'An unknown error occurred.';
  static const String authErrorMessage = 'Authentication failed. Please login again.';

  // Success Messages
  static const String orderPlacedMessage = 'Order placed successfully!';
  static const String paymentSuccessMessage = 'Payment completed successfully!';
  static const String serviceRequestSentMessage = 'Service request sent successfully!';

  // Feature Flags
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = false;
  static const bool enableCrashReporting = false;
  static const bool enableOfflineMode = true;

  // Development Settings
  static const bool isDebugMode = true;
  static const bool showDebugInfo = true;
  static const bool enableLogging = true;
}

