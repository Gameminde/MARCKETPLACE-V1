import 'dart:convert';

/// User model with comprehensive data structure
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final String? profileImageUrl;
  final String? bio;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserRole role;
  final UserStatus status;
  final UserPreferences preferences;
  final UserStats stats;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.profileImageUrl,
    this.bio,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
    this.role = UserRole.user,
    this.status = UserStatus.active,
    required this.preferences,
    required this.stats,
  });

  /// Full display name
  String get fullName => '$firstName $lastName';

  /// Display name with fallback to username
  String get displayName {
    final full = fullName.trim();
    return full.isNotEmpty ? full : username;
  }

  /// Check if user has profile image
  bool get hasProfileImage => profileImageUrl != null && profileImageUrl!.isNotEmpty;
  
  /// Alias for profileImageUrl for compatibility
  String? get avatarUrl => profileImageUrl;

  /// Check if user is verified
  bool get isVerified => status == UserStatus.verified;

  /// Check if user is active
  bool get isActive => status == UserStatus.active || status == UserStatus.verified;

  /// Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? json['first_name'] ?? '',
      lastName: json['lastName'] ?? json['last_name'] ?? '',
      username: json['username'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? json['profile_image_url'],
      bio: json['bio'],
      phone: json['phone'],
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
      role: UserRole.fromString(json['role'] ?? 'user'),
      status: UserStatus.fromString(json['status'] ?? 'active'),
      preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
      stats: UserStats.fromJson(json['stats'] ?? {}),
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'role': role.value,
      'status': status.value,
      'preferences': preferences.toJson(),
      'stats': stats.toJson(),
    };
  }

  /// Create a copy with updated fields
  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? username,
    String? profileImageUrl,
    String? bio,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserRole? role,
    UserStatus? status,
    UserPreferences? preferences,
    UserStats? stats,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
      status: status ?? this.status,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, email: $email, username: $username, fullName: $fullName)';
  }

  /// Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    if (dateTime is DateTime) return dateTime;
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}

/// User role enumeration
enum UserRole {
  user('user'),
  seller('seller'),
  admin('admin'),
  moderator('moderator');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.user,
    );
  }

  bool get isAdmin => this == UserRole.admin;
  bool get isModerator => this == UserRole.moderator || isAdmin;
  bool get isSeller => this == UserRole.seller || isAdmin;
}

/// User status enumeration
enum UserStatus {
  active('active'),
  inactive('inactive'),
  suspended('suspended'),
  verified('verified'),
  pending('pending');

  const UserStatus(this.value);
  final String value;

  static UserStatus fromString(String value) {
    return UserStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => UserStatus.active,
    );
  }
}

/// User preferences data class
class UserPreferences {
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final String language;
  final String currency;
  final String timezone;
  final bool darkMode;
  final bool publicProfile;

  UserPreferences({
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
    this.language = 'fr',
    this.currency = 'EUR',
    this.timezone = 'Europe/Paris',
    this.darkMode = false,
    this.publicProfile = true,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      emailNotifications: json['emailNotifications'] ?? true,
      pushNotifications: json['pushNotifications'] ?? true,
      smsNotifications: json['smsNotifications'] ?? false,
      language: json['language'] ?? 'fr',
      currency: json['currency'] ?? 'EUR',
      timezone: json['timezone'] ?? 'Europe/Paris',
      darkMode: json['darkMode'] ?? false,
      publicProfile: json['publicProfile'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'smsNotifications': smsNotifications,
      'language': language,
      'currency': currency,
      'timezone': timezone,
      'darkMode': darkMode,
      'publicProfile': publicProfile,
    };
  }

  UserPreferences copyWith({
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
    String? language,
    String? currency,
    String? timezone,
    bool? darkMode,
    bool? publicProfile,
  }) {
    return UserPreferences(
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      darkMode: darkMode ?? this.darkMode,
      publicProfile: publicProfile ?? this.publicProfile,
    );
  }
}

/// User statistics data class
class UserStats {
  final int totalOrders;
  final int totalSales;
  final double totalSpent;
  final double totalEarned;
  final int reviewsGiven;
  final int reviewsReceived;
  final double averageRating;
  final int favoriteItems;
  final DateTime lastLoginAt;

  UserStats({
    this.totalOrders = 0,
    this.totalSales = 0,
    this.totalSpent = 0.0,
    this.totalEarned = 0.0,
    this.reviewsGiven = 0,
    this.reviewsReceived = 0,
    this.averageRating = 0.0,
    this.favoriteItems = 0,
    DateTime? lastLoginAt,
  }) : lastLoginAt = lastLoginAt ?? DateTime.now();

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalOrders: json['totalOrders'] ?? 0,
      totalSales: json['totalSales'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0.0).toDouble(),
      totalEarned: (json['totalEarned'] ?? 0.0).toDouble(),
      reviewsGiven: json['reviewsGiven'] ?? 0,
      reviewsReceived: json['reviewsReceived'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      favoriteItems: json['favoriteItems'] ?? 0,
      lastLoginAt: User._parseDateTime(json['lastLoginAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalOrders': totalOrders,
      'totalSales': totalSales,
      'totalSpent': totalSpent,
      'totalEarned': totalEarned,
      'reviewsGiven': reviewsGiven,
      'reviewsReceived': reviewsReceived,
      'averageRating': averageRating,
      'favoriteItems': favoriteItems,
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  /// Check if user is a power seller
  bool get isPowerSeller => totalSales >= 100 && averageRating >= 4.5;

  /// Check if user is a frequent buyer
  bool get isFrequentBuyer => totalOrders >= 50;
}