import 'package:flutter/material.dart';

/// Shop/Vendor verification status
enum ShopVerificationStatus {
  pending('Pending', Colors.orange),
  verified('Verified', Colors.green),
  rejected('Rejected', Colors.red),
  suspended('Suspended', Colors.grey);

  const ShopVerificationStatus(this.displayName, this.color);
  final String displayName;
  final Color color;
}

/// Shop category types
enum ShopCategory {
  electronics('Electronics', Icons.devices),
  fashion('Fashion', Icons.checkroom),
  books('Books', Icons.menu_book),
  home('Home & Garden', Icons.home),
  sports('Sports', Icons.sports),
  beauty('Beauty', Icons.face),
  automotive('Automotive', Icons.directions_car),
  toys('Toys', Icons.toys),
  health('Health', Icons.health_and_safety),
  food('Food & Beverage', Icons.restaurant);

  const ShopCategory(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}

/// Shop subscription tier
enum ShopTier {
  basic('Basic', 0, Colors.grey),
  premium('Premium', 29.99, Colors.blue),
  enterprise('Enterprise', 99.99, Colors.purple);

  const ShopTier(this.displayName, this.monthlyPrice, this.color);
  final String displayName;
  final double monthlyPrice;
  final Color color;
}

/// Shop model for multi-vendor marketplace
class Shop {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String? logoUrl;
  final String? bannerUrl;
  final ShopCategory category;
  final ShopVerificationStatus verificationStatus;
  final ShopTier tier;
  final double rating;
  final int totalReviews;
  final int totalProducts;
  final int totalOrders;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final ShopBranding branding;
  final ShopSettings settings;
  final ShopStatistics statistics;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  const Shop({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    this.logoUrl,
    this.bannerUrl,
    required this.category,
    this.verificationStatus = ShopVerificationStatus.pending,
    this.tier = ShopTier.basic,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.totalProducts = 0,
    this.totalOrders = 0,
    required this.createdAt,
    required this.lastActiveAt,
    required this.branding,
    required this.settings,
    required this.statistics,
    this.tags = const [],
    this.metadata,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'],
      ownerId: json['owner_id'],
      name: json['name'],
      description: json['description'],
      logoUrl: json['logo_url'],
      bannerUrl: json['banner_url'],
      category: ShopCategory.values.firstWhere((e) => e.name == json['category']),
      verificationStatus: ShopVerificationStatus.values
          .firstWhere((e) => e.name == json['verification_status']),
      tier: ShopTier.values.firstWhere((e) => e.name == json['tier']),
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      totalProducts: json['total_products'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      lastActiveAt: DateTime.parse(json['last_active_at']),
      branding: ShopBranding.fromJson(json['branding']),
      settings: ShopSettings.fromJson(json['settings']),
      statistics: ShopStatistics.fromJson(json['statistics']),
      tags: List<String>.from(json['tags'] ?? []),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'banner_url': bannerUrl,
      'category': category.name,
      'verification_status': verificationStatus.name,
      'tier': tier.name,
      'rating': rating,
      'total_reviews': totalReviews,
      'total_products': totalProducts,
      'total_orders': totalOrders,
      'created_at': createdAt.toIso8601String(),
      'last_active_at': lastActiveAt.toIso8601String(),
      'branding': branding.toJson(),
      'settings': settings.toJson(),
      'statistics': statistics.toJson(),
      'tags': tags,
      'metadata': metadata,
    };
  }

  Shop copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? logoUrl,
    String? bannerUrl,
    ShopCategory? category,
    ShopVerificationStatus? verificationStatus,
    ShopTier? tier,
    double? rating,
    int? totalReviews,
    int? totalProducts,
    int? totalOrders,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    ShopBranding? branding,
    ShopSettings? settings,
    ShopStatistics? statistics,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return Shop(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      category: category ?? this.category,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      tier: tier ?? this.tier,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalProducts: totalProducts ?? this.totalProducts,
      totalOrders: totalOrders ?? this.totalOrders,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      branding: branding ?? this.branding,
      settings: settings ?? this.settings,
      statistics: statistics ?? this.statistics,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isVerified => verificationStatus == ShopVerificationStatus.verified;
  bool get isActive => settings.isActive && verificationStatus != ShopVerificationStatus.suspended;
  bool get isPremium => tier != ShopTier.basic;

  String get formattedRating => rating.toStringAsFixed(1);
  
  /// Mock shop data
  static List<Shop> mockShops() {
    final now = DateTime.now();
    
    return [
      Shop(
        id: 'shop_1',
        ownerId: 'vendor_1',
        name: 'TechHub Electronics',
        description: 'Premium electronics and gadgets store with latest technology products',
        logoUrl: 'https://example.com/techhub_logo.png',
        bannerUrl: 'https://example.com/techhub_banner.jpg',
        category: ShopCategory.electronics,
        verificationStatus: ShopVerificationStatus.verified,
        tier: ShopTier.premium,
        rating: 4.8,
        totalReviews: 1250,
        totalProducts: 156,
        totalOrders: 3420,
        createdAt: now.subtract(const Duration(days: 365)),
        lastActiveAt: now.subtract(const Duration(hours: 2)),
        branding: ShopBranding.defaultBranding().copyWith(
          primaryColor: const Color(0xFF2196F3),
          logoUrl: 'https://example.com/techhub_logo.png',
        ),
        settings: ShopSettings.defaultSettings(),
        statistics: const ShopStatistics(
          totalRevenue: 125000.0,
          monthlyRevenue: 15000.0,
          totalViews: 45000,
          conversionRate: 3.2,
          averageOrderValue: 89.50,
        ),
        tags: ['electronics', 'gadgets', 'tech', 'verified'],
      ),
      Shop(
        id: 'shop_2',
        ownerId: 'vendor_2',
        name: 'Fashion Forward',
        description: 'Trendy fashion and accessories for modern lifestyle',
        logoUrl: 'https://example.com/fashion_logo.png',
        bannerUrl: 'https://example.com/fashion_banner.jpg',
        category: ShopCategory.fashion,
        verificationStatus: ShopVerificationStatus.verified,
        tier: ShopTier.basic,
        rating: 4.5,
        totalReviews: 890,
        totalProducts: 234,
        totalOrders: 1890,
        createdAt: now.subtract(const Duration(days: 180)),
        lastActiveAt: now.subtract(const Duration(hours: 6)),
        branding: ShopBranding.defaultBranding().copyWith(
          primaryColor: const Color(0xFFE91E63),
          logoUrl: 'https://example.com/fashion_logo.png',
        ),
        settings: ShopSettings.defaultSettings(),
        statistics: const ShopStatistics(
          totalRevenue: 78000.0,
          monthlyRevenue: 8500.0,
          totalViews: 25000,
          conversionRate: 2.8,
          averageOrderValue: 65.30,
        ),
        tags: ['fashion', 'clothing', 'accessories', 'trendy'],
      ),
      Shop(
        id: 'shop_3',
        ownerId: 'vendor_3',
        name: 'BookWorm Corner',
        description: 'Your favorite books and educational materials',
        logoUrl: 'https://example.com/bookworm_logo.png',
        category: ShopCategory.books,
        verificationStatus: ShopVerificationStatus.pending,
        tier: ShopTier.basic,
        rating: 4.2,
        totalReviews: 320,
        totalProducts: 89,
        totalOrders: 560,
        createdAt: now.subtract(const Duration(days: 45)),
        lastActiveAt: now.subtract(const Duration(days: 1)),
        branding: ShopBranding.defaultBranding(),
        settings: ShopSettings.defaultSettings(),
        statistics: const ShopStatistics(
          totalRevenue: 12000.0,
          monthlyRevenue: 2800.0,
          totalViews: 8500,
          conversionRate: 1.9,
          averageOrderValue: 25.75,
        ),
        tags: ['books', 'education', 'reading'],
      ),
    ];
  }
}

/// Shop branding configuration
class ShopBranding {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final String? logoUrl;
  final String? bannerUrl;
  final String? customCSS;
  final String fontFamily;
  final Map<String, String> customText;

  const ShopBranding({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.logoUrl,
    this.bannerUrl,
    this.customCSS,
    this.fontFamily = 'Roboto',
    this.customText = const {},
  });

  factory ShopBranding.fromJson(Map<String, dynamic> json) {
    return ShopBranding(
      primaryColor: Color(json['primary_color'] ?? 0xFF2196F3),
      secondaryColor: Color(json['secondary_color'] ?? 0xFF03DAC6),
      accentColor: Color(json['accent_color'] ?? 0xFFFF9800),
      logoUrl: json['logo_url'],
      bannerUrl: json['banner_url'],
      customCSS: json['custom_css'],
      fontFamily: json['font_family'] ?? 'Roboto',
      customText: Map<String, String>.from(json['custom_text'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary_color': primaryColor.value,
      'secondary_color': secondaryColor.value,
      'accent_color': accentColor.value,
      'logo_url': logoUrl,
      'banner_url': bannerUrl,
      'custom_css': customCSS,
      'font_family': fontFamily,
      'custom_text': customText,
    };
  }

  ShopBranding copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    String? logoUrl,
    String? bannerUrl,
    String? customCSS,
    String? fontFamily,
    Map<String, String>? customText,
  }) {
    return ShopBranding(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      customCSS: customCSS ?? this.customCSS,
      fontFamily: fontFamily ?? this.fontFamily,
      customText: customText ?? this.customText,
    );
  }

  static ShopBranding defaultBranding() {
    return const ShopBranding(
      primaryColor: Color(0xFF2196F3),
      secondaryColor: Color(0xFF03DAC6),
      accentColor: Color(0xFFFF9800),
    );
  }
}

/// Shop settings configuration
class ShopSettings {
  final bool isActive;
  final bool acceptOrders;
  final bool autoApproveReturns;
  final bool enableChat;
  final bool requireApproval;
  final double minimumOrderAmount;
  final int processingDays;
  final List<String> shippingMethods;
  final List<String> paymentMethods;
  final Map<String, dynamic> notifications;

  const ShopSettings({
    this.isActive = true,
    this.acceptOrders = true,
    this.autoApproveReturns = false,
    this.enableChat = true,
    this.requireApproval = false,
    this.minimumOrderAmount = 0.0,
    this.processingDays = 2,
    this.shippingMethods = const ['standard', 'express'],
    this.paymentMethods = const ['card', 'paypal'],
    this.notifications = const {},
  });

  factory ShopSettings.fromJson(Map<String, dynamic> json) {
    return ShopSettings(
      isActive: json['is_active'] ?? true,
      acceptOrders: json['accept_orders'] ?? true,
      autoApproveReturns: json['auto_approve_returns'] ?? false,
      enableChat: json['enable_chat'] ?? true,
      requireApproval: json['require_approval'] ?? false,
      minimumOrderAmount: (json['minimum_order_amount'] ?? 0.0).toDouble(),
      processingDays: json['processing_days'] ?? 2,
      shippingMethods: List<String>.from(json['shipping_methods'] ?? ['standard', 'express']),
      paymentMethods: List<String>.from(json['payment_methods'] ?? ['card', 'paypal']),
      notifications: Map<String, dynamic>.from(json['notifications'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_active': isActive,
      'accept_orders': acceptOrders,
      'auto_approve_returns': autoApproveReturns,
      'enable_chat': enableChat,
      'require_approval': requireApproval,
      'minimum_order_amount': minimumOrderAmount,
      'processing_days': processingDays,
      'shipping_methods': shippingMethods,
      'payment_methods': paymentMethods,
      'notifications': notifications,
    };
  }

  ShopSettings copyWith({
    bool? isActive,
    bool? acceptOrders,
    bool? autoApproveReturns,
    bool? enableChat,
    bool? requireApproval,
    double? minimumOrderAmount,
    int? processingDays,
    List<String>? shippingMethods,
    List<String>? paymentMethods,
    Map<String, dynamic>? notifications,
  }) {
    return ShopSettings(
      isActive: isActive ?? this.isActive,
      acceptOrders: acceptOrders ?? this.acceptOrders,
      autoApproveReturns: autoApproveReturns ?? this.autoApproveReturns,
      enableChat: enableChat ?? this.enableChat,
      requireApproval: requireApproval ?? this.requireApproval,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      processingDays: processingDays ?? this.processingDays,
      shippingMethods: shippingMethods ?? this.shippingMethods,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      notifications: notifications ?? this.notifications,
    );
  }

  static ShopSettings defaultSettings() {
    return const ShopSettings();
  }
}

/// Shop statistics model
class ShopStatistics {
  final double totalRevenue;
  final double monthlyRevenue;
  final int totalViews;
  final double conversionRate;
  final double averageOrderValue;
  final Map<String, int> topCategories;
  final List<MonthlyStats> monthlyStats;

  const ShopStatistics({
    this.totalRevenue = 0.0,
    this.monthlyRevenue = 0.0,
    this.totalViews = 0,
    this.conversionRate = 0.0,
    this.averageOrderValue = 0.0,
    this.topCategories = const {},
    this.monthlyStats = const [],
  });

  factory ShopStatistics.fromJson(Map<String, dynamic> json) {
    return ShopStatistics(
      totalRevenue: (json['total_revenue'] ?? 0.0).toDouble(),
      monthlyRevenue: (json['monthly_revenue'] ?? 0.0).toDouble(),
      totalViews: json['total_views'] ?? 0,
      conversionRate: (json['conversion_rate'] ?? 0.0).toDouble(),
      averageOrderValue: (json['average_order_value'] ?? 0.0).toDouble(),
      topCategories: Map<String, int>.from(json['top_categories'] ?? {}),
      monthlyStats: (json['monthly_stats'] as List? ?? [])
          .map((m) => MonthlyStats.fromJson(m))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_revenue': totalRevenue,
      'monthly_revenue': monthlyRevenue,
      'total_views': totalViews,
      'conversion_rate': conversionRate,
      'average_order_value': averageOrderValue,
      'top_categories': topCategories,
      'monthly_stats': monthlyStats.map((m) => m.toJson()).toList(),
    };
  }
}

/// Monthly statistics model
class MonthlyStats {
  final int month;
  final int year;
  final double revenue;
  final int orders;
  final int views;

  const MonthlyStats({
    required this.month,
    required this.year,
    required this.revenue,
    required this.orders,
    required this.views,
  });

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStats(
      month: json['month'],
      year: json['year'],
      revenue: (json['revenue'] ?? 0.0).toDouble(),
      orders: json['orders'] ?? 0,
      views: json['views'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'year': year,
      'revenue': revenue,
      'orders': orders,
      'views': views,
    };
  }
}

/// Shop review model
class ShopReview {
  final String id;
  final String shopId;
  final String userId;
  final String userName;
  final double rating;
  final String? comment;
  final DateTime createdAt;
  final List<String> tags;

  const ShopReview({
    required this.id,
    required this.shopId,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.tags = const [],
  });

  factory ShopReview.fromJson(Map<String, dynamic> json) {
    return ShopReview(
      id: json['id'],
      shopId: json['shop_id'],
      userId: json['user_id'],
      userName: json['user_name'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'user_id': userId,
      'user_name': userName,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'tags': tags,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}