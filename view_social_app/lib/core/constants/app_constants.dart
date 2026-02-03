import 'dart:io';

class AppConstants {
  // API Configuration - Dynamic based on platform and Docker environment
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine
      // For Docker container, use the container's host IP
      return 'http://10.0.2.2:3000/api/v1';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost for Docker containers
      return 'http://localhost:3000/api/v1';
    } else {
      // For web or other platforms, use localhost for Docker
      return 'http://localhost:3000/api/v1';
    }
  }

  static String get wsUrl {
    if (Platform.isAndroid) {
      return 'ws://10.0.2.2:3000/ws';
    } else if (Platform.isIOS) {
      return 'ws://localhost:3000/ws';
    } else {
      return 'ws://localhost:3000/ws';
    }
  }

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  // Pagination
  static const int defaultPageSize = 20;

  // Media
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50MB
  static const int maxReelDuration = 60; // seconds

  // Payment
  static const String currency = 'NGN';
  static const String paymentCommand = '/viewpay';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
