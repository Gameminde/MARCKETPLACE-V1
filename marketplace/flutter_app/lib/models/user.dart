/// User roles enum for the marketplace
enum UserRole {
  buyer,
  seller,
  admin;

  String get name {
    switch (this) {
      case UserRole.buyer:
        return 'buyer';
      case UserRole.seller:
        return 'seller';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'seller':
        return UserRole.seller;
      case 'admin':
        return UserRole.admin;
      case 'buyer':
      default:
        return UserRole.buyer;
    }
  }
}

/// User model for the marketplace
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? profilePictureUrl; // Alternative name for compatibility
  final String? displayName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isVerified;
  final bool isEmailVerified;
  final bool isMfaEnabled;
  final bool isTwoFactorEnabled;
  final String? membershipTier;
  final UserRole role;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.profileImageUrl,
    this.profilePictureUrl,
    this.displayName,
    this.createdAt,
    this.updatedAt,
    this.isVerified = false,
    this.isEmailVerified = false,
    this.isMfaEnabled = false,
    this.isTwoFactorEnabled = false,
    this.membershipTier,
    this.role = UserRole.buyer,
  });

  String get fullName => '$firstName $lastName';
  
  /// Get display name with fallback to full name
  String get effectiveDisplayName => displayName ?? fullName;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'],
      profileImageUrl: json['profileImageUrl'],
      profilePictureUrl: json['profilePictureUrl'] ?? json['profileImageUrl'],
      displayName: json['displayName'],
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      isVerified: json['isVerified'] ?? false,
      isEmailVerified: json['isEmailVerified'] ?? false,
      isMfaEnabled: json['isMfaEnabled'] ?? false,
      isTwoFactorEnabled: json['isTwoFactorEnabled'] ?? json['isMfaEnabled'] ?? false,
      membershipTier: json['membershipTier'],
      role: UserRole.fromString(json['role'] ?? 'buyer'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'profilePictureUrl': profilePictureUrl ?? profileImageUrl,
      'displayName': displayName,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isVerified': isVerified,
      'isEmailVerified': isEmailVerified,
      'isMfaEnabled': isMfaEnabled,
      'isTwoFactorEnabled': isTwoFactorEnabled,
      'membershipTier': membershipTier,
      'role': role.name,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    String? profilePictureUrl,
    String? displayName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    bool? isEmailVerified,
    bool? isMfaEnabled,
    bool? isTwoFactorEnabled,
    String? membershipTier,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isMfaEnabled: isMfaEnabled ?? this.isMfaEnabled,
      isTwoFactorEnabled: isTwoFactorEnabled ?? this.isTwoFactorEnabled,
      membershipTier: membershipTier ?? this.membershipTier,
      role: role ?? this.role,
    );
  }
}