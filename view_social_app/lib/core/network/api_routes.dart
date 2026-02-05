/// API Routes for VIEW Social Backend
/// Base URL should be configured in environment variables
class ApiRoutes {
  // Authentication Routes
  static const String register = '/auth/register';
  static const String verify = '/auth/verify';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String resendVerification = '/auth/resend';

  // User Routes
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String uploadAvatar = '/users/avatar';
  static const String searchUsers = '/users/search';
  static const String getUserById = '/users'; // + /{id}

  // Posts Routes
  static const String posts = '/posts';
  static const String createPost = '/posts';
  static const String getPost = '/posts'; // + /{id}
  static const String updatePost = '/posts'; // + /{id}
  static const String deletePost = '/posts'; // + /{id}
  static const String likePost = '/posts'; // + /{id}/like
  static const String unlikePost = '/posts'; // + /{id}/unlike
  static const String getPostComments = '/posts'; // + /{id}/comments
  static const String addComment = '/posts'; // + /{id}/comments

  // Messages Routes
  static const String conversations = '/conversations';
  static const String createConversation = '/conversations';
  static String conversationMessages(String conversationId) =>
      '/conversations/$conversationId/messages';
  static String conversationTyping(String conversationId) =>
      '/conversations/$conversationId/typing';
  static String conversationRead(String conversationId) =>
      '/conversations/$conversationId/read';

  // Payments Routes
  static const String wallet = '/payments/wallet';
  static const String createWallet = '/payments/wallet';
  static const String sendMoney = '/payments/send';
  static const String requestMoney = '/payments/request';
  static const String getTransactions = '/payments/transactions';
  static const String getTransaction = '/payments/transactions'; // + /{id}

  // Notifications Routes
  static const String notifications = '/notifications';
  static const String markNotificationRead = '/notifications'; // + /{id}/read
  static const String markAllNotificationsRead = '/notifications/read-all';

  // WebSocket Routes
  static const String wsMessages = '/ws/messages';
  static const String wsNotifications = '/ws/notifications';
  static const String wsTyping = '/ws/typing';

  // Utility Methods
  static String getUserByIdUrl(String userId) => '$getUserById/$userId';
  static String getPostUrl(String postId) => '$getPost/$postId';
  static String updatePostUrl(String postId) => '$updatePost/$postId';
  static String deletePostUrl(String postId) => '$deletePost/$postId';
  static String likePostUrl(String postId) => '$likePost/$postId/like';
  static String unlikePostUrl(String postId) => '$unlikePost/$postId/unlike';
  static String getPostCommentsUrl(String postId) =>
      '$getPostComments/$postId/comments';
  static String addCommentUrl(String postId) => '$addComment/$postId/comments';
  static String getConversationUrl(String conversationId) =>
      '$conversations/$conversationId';
  static String getTransactionUrl(String transactionId) =>
      '$getTransaction/$transactionId';
  static String markNotificationReadUrl(String notificationId) =>
      '$markNotificationRead/$notificationId/read';
}

/// HTTP Methods
class HttpMethods {
  static const String get = 'GET';
  static const String post = 'POST';
  static const String put = 'PUT';
  static const String patch = 'PATCH';
  static const String delete = 'DELETE';
}

/// API Response Status Codes
class ApiStatusCodes {
  static const int success = 200;
  static const int created = 201;
  static const int noContent = 204;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int conflict = 409;
  static const int unprocessableEntity = 422;
  static const int internalServerError = 500;
}
