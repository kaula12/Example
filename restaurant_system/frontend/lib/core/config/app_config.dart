class AppConfig {
  // API Configuration
  static const String baseUrl = 'http://localhost:8000';
  static const String apiVersion = '/api';
  
  // Supabase Configuration
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // Firebase Configuration
  static const String firebaseProjectId = 'YOUR_FIREBASE_PROJECT_ID';
  
  // App Configuration
  static const String appName = 'Restaurant Ordering System';
  static const String appVersion = '1.0.0';
  
  // API Endpoints
  static const String menuEndpoint = '$apiVersion/menu';
  static const String ordersEndpoint = '$apiVersion/orders';
  static const String tablesEndpoint = '$apiVersion/tables';
  static const String waiterAlertsEndpoint = '$apiVersion/waiter-alerts';
  static const String paymentsEndpoint = '$apiVersion/payments';
  static const String analyticsEndpoint = '$apiVersion/analytics';
  static const String fcmTokenEndpoint = '$apiVersion/fcm-token';
  
  // User Roles
  static const String customerRole = 'customer';
  static const String waiterRole = 'waiter';
  static const String kitchenRole = 'kitchen';
  static const String adminRole = 'admin';
  
  // Order Status
  static const String pendingStatus = 'pending';
  static const String confirmedStatus = 'confirmed';
  static const String preparingStatus = 'preparing';
  static const String readyStatus = 'ready';
  static const String servedStatus = 'served';
  static const String cancelledStatus = 'cancelled';
  
  // Table Status
  static const String availableStatus = 'available';
  static const String occupiedStatus = 'occupied';
  static const String reservedStatus = 'reserved';
  
  // Payment Methods
  static const String stripePayment = 'stripe';
  static const String mpesaPayment = 'mpesa';
  static const String cashPayment = 'cash';
}

