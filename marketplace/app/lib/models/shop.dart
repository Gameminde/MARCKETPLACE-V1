class Shop {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final String? bannerUrl;
  final String ownerId;
  final String ownerName;
  final String category;
  final List<String> tags;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? productCount;
  final double? rating;
  final int? reviewCount;
  final int? followerCount;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final Map<String, dynamic>? socialLinks;

  Shop({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    this.bannerUrl,
    required this.ownerId,
    required this.ownerName,
    required this.category,
    this.tags = const [],
    this.isActive = true,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.productCount,
    this.rating,
    this.reviewCount,
    this.followerCount,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.socialLinks,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      logoUrl: json['logoUrl'] ?? json['logo_url'],
      bannerUrl: json['bannerUrl'] ?? json['banner_url'],
      ownerId: json['ownerId'] ?? json['owner_id'] ?? '',
      ownerName: json['ownerName'] ?? json['owner_name'] ?? '',
      category: json['category'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      isVerified: json['isVerified'] ?? json['is_verified'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? json['updated_at'] ?? '') ?? DateTime.now(),
      productCount: json['productCount'] ?? json['product_count'],
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? json['review_count'] ?? 0,
      followerCount: json['followerCount'] ?? json['follower_count'] ?? 0,
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      socialLinks: json['socialLinks'] ?? json['social_links'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'category': category,
      'tags': tags,
      'isActive': isActive,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'productCount': productCount,
      'rating': rating,
      'reviewCount': reviewCount,
      'followerCount': followerCount,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'socialLinks': socialLinks,
    };
  }

  Shop copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? bannerUrl,
    String? ownerId,
    String? ownerName,
    String? category,
    List<String>? tags,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? productCount,
    double? rating,
    int? reviewCount,
    int? followerCount,
    String? address,
    String? phone,
    String? email,
    String? website,
    Map<String, dynamic>? socialLinks,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productCount: productCount ?? this.productCount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      followerCount: followerCount ?? this.followerCount,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      socialLinks: socialLinks ?? this.socialLinks,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Shop && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Shop(id: $id, name: $name, category: $category, isVerified: $isVerified)';
  }
}