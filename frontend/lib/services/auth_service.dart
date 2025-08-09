import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/models.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  User? _currentUser;
  String? _authToken;

  AuthService(this._apiService);

  User? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isAuthenticated => _currentUser != null && _authToken != null;

  // Initialize auth state
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      final userJson = prefs.getString(AppConstants.userKey);

      if (token != null && userJson != null) {
        _authToken = token;
        _apiService.setAuthToken(token);
        
        // Try to get current user to validate token
        try {
          _currentUser = await _apiService.getCurrentUser();
        } catch (e) {
          // Token is invalid, clear it
          await signOut();
        }
      }

      // Check Supabase session
      final session = _supabase.auth.currentSession;
      if (session != null && _currentUser == null) {
        await _handleSupabaseAuth(session.accessToken);
      }
    } catch (e) {
      print('Auth initialization error: $e');
    }
  }

  // Register with email/password
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      // Register with Supabase
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
        },
      );

      if (response.user == null) {
        throw 'Registration failed';
      }

      // Register with our backend
      final userData = await _apiService.register({
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'supabase_id': response.user!.id,
        'role': AppConstants.roleCustomer,
      });

      _currentUser = User.fromJson(userData);
      
      // Get auth token from Supabase session
      if (response.session != null) {
        await _handleSupabaseAuth(response.session!.accessToken);
      }

      return _currentUser!;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign in with email/password
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with Supabase
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null || response.session == null) {
        throw 'Sign in failed';
      }

      // Authenticate with our backend
      await _handleSupabaseAuth(response.session!.accessToken);

      return _currentUser!;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign in with Supabase token
  Future<User> signInWithSupabaseToken(String token) async {
    try {
      await _handleSupabaseAuth(token);
      return _currentUser!;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Handle Supabase authentication
  Future<void> _handleSupabaseAuth(String supabaseToken) async {
    try {
      final response = await _apiService.supabaseAuth(supabaseToken);
      
      _authToken = response['access_token'];
      _apiService.setAuthToken(_authToken!);
      
      // Get current user
      _currentUser = await _apiService.getCurrentUser();
      
      // Save to local storage
      await _saveAuthData();
    } catch (e) {
      throw 'Authentication failed: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Supabase
      await _supabase.auth.signOut();
      
      // Clear local data
      _currentUser = null;
      _authToken = null;
      _apiService.clearAuthToken();
      
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userKey);
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // Update user profile
  Future<User> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    try {
      if (_currentUser == null) throw 'Not authenticated';

      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (phone != null) updateData['phone'] = phone;

      // Update in Supabase
      await _supabase.auth.updateUser(
        UserAttributes(
          data: updateData,
        ),
      );

      // Update in our backend
      final response = await _apiService._dio.put('/auth/me', data: updateData);
      _currentUser = User.fromJson(response.data);

      await _saveAuthData();
      return _currentUser!;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Save auth data to local storage
  Future<void> _saveAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_authToken != null) {
        await prefs.setString(AppConstants.tokenKey, _authToken!);
      }
      
      if (_currentUser != null) {
        await prefs.setString(AppConstants.userKey, _currentUser!.toJson().toString());
      }
    } catch (e) {
      print('Save auth data error: $e');
    }
  }

  // Handle auth errors
  String _handleAuthError(dynamic error) {
    if (error is AuthException) {
      switch (error.statusCode) {
        case '400':
          return 'Invalid email or password';
        case '422':
          return 'Email already registered';
        case '429':
          return 'Too many requests. Please try again later';
        default:
          return error.message;
      }
    }
    return error.toString();
  }

  // Check if user has role
  bool hasRole(String role) {
    return _currentUser?.role == role;
  }

  // Check if user is admin
  bool get isAdmin => hasRole(AppConstants.roleAdmin);

  // Check if user is kitchen staff
  bool get isKitchen => hasRole(AppConstants.roleKitchen);

  // Check if user is waiter
  bool get isWaiter => hasRole(AppConstants.roleWaiter);

  // Check if user is customer
  bool get isCustomer => hasRole(AppConstants.roleCustomer);
}

