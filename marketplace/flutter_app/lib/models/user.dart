/// User roles enum
enum UserRole {
  buyer,
  seller,
  admin,
  moderator,
}

/// User model for authentication and profile management
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? avatarUrl;
  final UserRole role;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isMfaEnabled;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? metadata;
  final String? profilePictureUrl;
  final bool isTwoFactorEnabled;
  final String? membershipTier;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.avatarUrl,
    this.role = UserRole.buyer,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isMfaEnabled = false,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
    this.preferences,
    this.metadata,
    this.profilePictureUrl,
    this.isTwoFactorEnabled = false,
    this.membershipTier,
  });

  /// Get user's full name
  String get fullName => '$firstName $lastName';

  /// Get user's display name (falls back to email if no name)
  String get displayName {
    final name = fullName.trim();
    return name.isNotEmpty ? name : email;
  }


  /// Get user's initials for avatar
  String get initials {
    String first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    String last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return first + last;
  }

  /// Check if user is verified (email and optionally phone)
  bool get isVerified => isEmailVerified;

  /// Check if user is fully verified (email + phone if provided)
  bool get isFullyVerified {
    if (phoneNumber != null) {
      return isEmailVerified && isPhoneVerified;
    }
    return isEmailVerified;
  }

  /// Copy user with modifications
  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? avatarUrl,
    UserRole? role,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isMfaEnabled,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? metadata,
    String? profilePictureUrl,
    bool? isTwoFactorEnabled,
    String? membershipTier,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isMfaEnabled: isMfaEnabled ?? this.isMfaEnabled,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      metadata: metadata ?? this.metadata,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isTwoFactorEnabled: isTwoFactorEnabled ?? this.isTwoFactorEnabled,
      membershipTier: membershipTier ?? this.membershipTier,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'role': role.name,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'isMfaEnabled': isMfaEnabled,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'preferences': preferences,
      'metadata': metadata,
      'profilePictureUrl': profilePictureUrl,
      'isTwoFactorEnabled': isTwoFactorEnabled,
      'membershipTier': membershipTier,
    };
  }

  /// Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => UserRole.buyer,
      ),
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      isMfaEnabled: json['isMfaEnabled'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      preferences: json['preferences'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      isTwoFactorEnabled: json['isTwoFactorEnabled'] as bool? ?? false,
      membershipTier: json['membershipTier'] as String?,
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
    return 'User{id: $id, email: $email, fullName: $fullName, role: $role}';
  }
}