// Register Request
class RegisterRequest {
  final String username;
  final String password;
  final String identifier; // email or phone
  final String registrationType; // "email" or "phone"
  final String? displayName;

  RegisterRequest({
    required this.username,
    required this.password,
    required this.identifier,
    required this.registrationType,
    this.displayName,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'identifier': identifier,
      'registration_type': registrationType,
      if (displayName != null) 'display_name': displayName,
    };
  }
}

// Register Response
class RegisterResponse {
  final String message;
  final String verificationId;
  final String userId;
  final String verificationType;
  final String identifier;

  RegisterResponse({
    required this.message,
    required this.verificationId,
    required this.userId,
    required this.verificationType,
    required this.identifier,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    try {
      print('RegisterResponse.fromJson input: $json');
      print('RegisterResponse.fromJson input type: ${json.runtimeType}');

      // Safely check types
      json.forEach((key, value) {
        print('Key: $key, Value: $value, Type: ${value.runtimeType}');
      });

      return RegisterResponse(
        message: json['message'] as String,
        verificationId: json['verification_id'].toString(),
        userId: json['user_id'].toString(),
        verificationType: json['verification_type'] as String,
        identifier: json['identifier'] as String,
      );
    } catch (e) {
      print('ERROR in RegisterResponse.fromJson: $e');
      print('JSON data: $json');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
}

// Verify Request
class VerifyRequest {
  final String identifier;
  final String code;

  VerifyRequest({required this.identifier, required this.code});

  Map<String, dynamic> toJson() {
    return {'identifier': identifier, 'code': code};
  }
}

// Login Request
class LoginRequest {
  final String identifier; // username, email, or phone
  final String password;

  LoginRequest({required this.identifier, required this.password});

  Map<String, dynamic> toJson() {
    return {'identifier': identifier, 'password': password};
  }
}

// Login Response
class LoginResponse {
  final String token;
  final String userId;
  final String username;
  final String email;
  final bool emailVerified;
  final bool phoneVerified;

  LoginResponse({
    required this.token,
    required this.userId,
    required this.username,
    required this.email,
    required this.emailVerified,
    required this.phoneVerified,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    try {
      print('LoginResponse.fromJson input: $json');
      print('LoginResponse.fromJson input type: ${json.runtimeType}');

      // Safely check types
      json.forEach((key, value) {
        print('Key: $key, Value: $value, Type: ${value.runtimeType}');
      });

      return LoginResponse(
        token: json['token'] as String,
        userId: json['user_id'].toString(),
        username: json['username'] as String,
        email: json['email'] as String,
        emailVerified: json['email_verified'] as bool,
        phoneVerified: json['phone_verified'] as bool,
      );
    } catch (e) {
      print('ERROR in LoginResponse.fromJson: $e');
      print('JSON data: $json');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user_id': userId,
      'username': username,
      'email': email,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
    };
  }
}

// Resend Verification Request
class ResendVerificationRequest {
  final String identifier;

  ResendVerificationRequest({required this.identifier});

  Map<String, dynamic> toJson() {
    return {'identifier': identifier};
  }
}

// User Model for local storage
class User {
  final String id;
  final String username;
  final String email;
  final bool emailVerified;
  final bool phoneVerified;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.emailVerified,
    required this.phoneVerified,
    this.displayName,
    this.bio,
    this.avatarUrl,
  });

  factory User.fromLoginResponse(LoginResponse response) {
    return User(
      id: response.userId,
      username: response.username,
      email: response.email,
      emailVerified: response.emailVerified,
      phoneVerified: response.phoneVerified,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      emailVerified: json['email_verified'],
      phoneVerified: json['phone_verified'],
      displayName: json['display_name'],
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
      'display_name': displayName,
      'bio': bio,
      'avatar_url': avatarUrl,
    };
  }
}
