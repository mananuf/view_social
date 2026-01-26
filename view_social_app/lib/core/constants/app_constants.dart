class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:3000';
  static const String wsUrl = 'ws://localhost:3000/ws';
  
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