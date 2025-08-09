import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class NotificationService {
  static FirebaseMessaging? _messaging;
  static String? _fcmToken;

  static Future<void> initialize() async {
    _messaging = FirebaseMessaging.instance;

    // Request permission for iOS
    NotificationSettings settings = await _messaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get FCM token
    _fcmToken = await _messaging!.getToken();
    print('FCM Token: $_fcmToken');

    // Save token locally
    if (_fcmToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', _fcmToken!);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      _handleNotificationTap(message);
    });

    // Handle notification tap when app is terminated
    RemoteMessage? initialMessage = await _messaging!.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Listen for token refresh
    _messaging!.onTokenRefresh.listen((String token) {
      print('FCM Token refreshed: $token');
      _fcmToken = token;
      _updateTokenOnServer(token);
    });
  }

  static Future<void> registerToken(String role, {int? userId}) async {
    if (_fcmToken != null) {
      try {
        await ApiService.registerFCMToken(
          _fcmToken!,
          role,
          userId: userId,
          deviceId: await _getDeviceId(),
        );
        print('FCM token registered successfully for role: $role');
      } catch (e) {
        print('Failed to register FCM token: $e');
      }
    }
  }

  static Future<String?> getToken() async {
    if (_fcmToken == null) {
      _fcmToken = await _messaging?.getToken();
    }
    return _fcmToken;
  }

  static void _showLocalNotification(RemoteMessage message) {
    // In a real app, you would use a local notification plugin
    // like flutter_local_notifications to show notifications
    print('Showing notification: ${message.notification?.title}');
  }

  static void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    
    // Handle navigation based on notification data
    final data = message.data;
    
    if (data.containsKey('order_id')) {
      // Navigate to order details
      print('Navigate to order: ${data['order_id']}');
    } else if (data.containsKey('table_number')) {
      // Navigate to table
      print('Navigate to table: ${data['table_number']}');
    }
  }

  static Future<void> _updateTokenOnServer(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'customer';
    final userId = prefs.getInt('user_id');
    
    try {
      await ApiService.registerFCMToken(
        token,
        role,
        userId: userId,
        deviceId: await _getDeviceId(),
      );
    } catch (e) {
      print('Failed to update FCM token on server: $e');
    }
  }

  static Future<String> _getDeviceId() async {
    // In a real app, you would use a plugin like device_info_plus
    // to get a unique device identifier
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _messaging?.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging?.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  // Subscribe to role-based topics
  static Future<void> subscribeToRoleTopics(String role) async {
    await subscribeToTopic('all_users');
    await subscribeToTopic(role);
    
    if (role == 'waiter' || role == 'kitchen' || role == 'admin') {
      await subscribeToTopic('staff');
    }
  }

  static Future<void> unsubscribeFromRoleTopics(String role) async {
    await unsubscribeFromTopic('all_users');
    await unsubscribeFromTopic(role);
    
    if (role == 'waiter' || role == 'kitchen' || role == 'admin') {
      await unsubscribeFromTopic('staff');
    }
  }
}

