import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../core/config/app_constants.dart';
import '../services/xp_system.dart';
import '../models/user.dart';

/// Loyalty tier enumeration
enum LoyaltyTier {
  bronze('Bronze', 0, Color(0xFFCD7F32), Icons.looks_one),
  silver('Silver', 1000, Color(0xFFC0C0C0), Icons.looks_two),
  gold('Gold', 5000, Color(0xFFFFD700), Icons.looks_3),
  platinum('Platinum', 15000, Color(0xFFE5E4E2), Icons.looks_4),
  diamond('Diamond', 50000, Color(0xFFB9F2FF), Icons.diamond);

  const LoyaltyTier(this.displayName, this.requiredPoints, this.color, this.icon);
  final String displayName;
  final int requiredPoints;
  final Color color;
  final IconData icon;
}

/// Loyalty benefit types
enum BenefitType {
  discount,
  freeShipping,
  earlyAccess,
  prioritySupport,
  exclusiveProducts,
  bonusPoints,
  birthdayReward,
  memberEvents
}

/// Loyalty benefit model
class LoyaltyBenefit {
  final String id;
  final String title;
  final String description;
  final BenefitType type;
  final dynamic value; // Could be percentage, boolean, etc.
  final LoyaltyTier requiredTier;
  final IconData icon;
  final bool isActive;
  final DateTime? expiresAt;

  const LoyaltyBenefit({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    required this.requiredTier,
    required this.icon,
    this.isActive = true,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'value': value,
      'required_tier': requiredTier.name,
      'is_active': isActive,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  static LoyaltyBenefit fromJson(Map<String, dynamic> json) {
    return LoyaltyBenefit(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: BenefitType.values.firstWhere((e) => e.name == json['type']),
      value: json['value'],
      requiredTier: LoyaltyTier.values.firstWhere((e) => e.name == json['required_tier']),
      icon: _getIconForBenefitType(BenefitType.values.firstWhere((e) => e.name == json['type'])),
      isActive: json['is_active'] ?? true,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    );
  }

  static IconData _getIconForBenefitType(BenefitType type) {
    switch (type) {
      case BenefitType.discount:
        return Icons.percent;
      case BenefitType.freeShipping:
        return Icons.local_shipping;
      case BenefitType.earlyAccess:
        return Icons.schedule;
      case BenefitType.prioritySupport:
        return Icons.support_agent;
      case BenefitType.exclusiveProducts:
        return Icons.star;
      case BenefitType.bonusPoints:
        return Icons.add_circle;
      case BenefitType.birthdayReward:
        return Icons.cake;
      case BenefitType.memberEvents:
        return Icons.event;
    }
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Loyalty transaction model
class LoyaltyTransaction {
  final String id;
  final String userId;
  final String type; // earned, redeemed, expired
  final int points;
  final String description;
  final DateTime timestamp;
  final String? orderId;
  final Map<String, dynamic>? metadata;

  const LoyaltyTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.points,
    required this.description,
    required this.timestamp,
    this.orderId,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'points': points,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'order_id': orderId,
      'metadata': metadata,
    };
  }

  static LoyaltyTransaction fromJson(Map<String, dynamic> json) {
    return LoyaltyTransaction(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      points: json['points'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      orderId: json['order_id'],
      metadata: json['metadata'],
    );
  }

  bool get isEarned => type == 'earned';
  bool get isRedeemed => type == 'redeemed';
  bool get isExpired => type == 'expired';
}

/// Loyalty reward model
class LoyaltyReward {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String imageUrl;
  final String category;
  final bool isAvailable;
  final int? quantityLimit;
  final int? quantityRemaining;
  final DateTime? expiresAt;
  final LoyaltyTier? minimumTier;

  const LoyaltyReward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.imageUrl,
    required this.category,
    this.isAvailable = true,
    this.quantityLimit,
    this.quantityRemaining,
    this.expiresAt,
    this.minimumTier,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points_cost': pointsCost,
      'image_url': imageUrl,
      'category': category,
      'is_available': isAvailable,
      'quantity_limit': quantityLimit,
      'quantity_remaining': quantityRemaining,
      'expires_at': expiresAt?.toIso8601String(),
      'minimum_tier': minimumTier?.name,
    };
  }

  static LoyaltyReward fromJson(Map<String, dynamic> json) {
    return LoyaltyReward(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      pointsCost: json['points_cost'],
      imageUrl: json['image_url'],
      category: json['category'],
      isAvailable: json['is_available'] ?? true,
      quantityLimit: json['quantity_limit'],
      quantityRemaining: json['quantity_remaining'],
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      minimumTier: json['minimum_tier'] != null 
          ? LoyaltyTier.values.firstWhere((e) => e.name == json['minimum_tier'])
          : null,
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isOutOfStock => quantityRemaining != null && quantityRemaining! <= 0;
  bool canRedeem(LoyaltyTier userTier, int userPoints) {
    if (!isAvailable || isExpired || isOutOfStock) return false;
    if (pointsCost > userPoints) return false;
    if (minimumTier != null && userTier.index < minimumTier!.index) return false;
    return true;
  }
}

/// Comprehensive loyalty program system
class LoyaltyProgram extends ChangeNotifier {
  static LoyaltyProgram? _instance;
  static LoyaltyProgram get instance => _instance ??= LoyaltyProgram._internal();
  
  LoyaltyProgram._internal();

  // Dependencies
  late XPSystem _xpSystem;

  // User loyalty data
  int _loyaltyPoints = 0;
  LoyaltyTier _currentTier = LoyaltyTier.bronze;
  List<LoyaltyTransaction> _transactions = [];
  List<LoyaltyBenefit> _activeBenefits = [];
  Map<String, DateTime> _redeemedRewards = {};

  // System data
  late List<LoyaltyBenefit> _allBenefits;
  late List<LoyaltyReward> _availableRewards;
  
  // Loading and error states
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  int get loyaltyPoints => _loyaltyPoints;
  LoyaltyTier get currentTier => _currentTier;
  List<LoyaltyTransaction> get transactions => List.unmodifiable(_transactions);
  List<LoyaltyBenefit> get activeBenefits => List.unmodifiable(_activeBenefits);
  List<LoyaltyReward> get availableRewards => List.unmodifiable(_availableRewards);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  LoyaltyTier? get nextTier {
    final currentIndex = _currentTier.index;
    if (currentIndex < LoyaltyTier.values.length - 1) {
      return LoyaltyTier.values[currentIndex + 1];
    }
    return null;
  }

  int get pointsToNextTier {
    final next = nextTier;
    if (next != null) {
      return next.requiredPoints - _loyaltyPoints;
    }
    return 0;
  }

  double get progressToNextTier {
    final next = nextTier;
    if (next == null) return 1.0;
    
    final currentRequired = _currentTier.requiredPoints;
    final nextRequired = next.requiredPoints;
    final pointsInTier = _loyaltyPoints - currentRequired;
    final pointsNeededForTier = nextRequired - currentRequired;
    
    return pointsNeededForTier > 0 ? pointsInTier / pointsNeededForTier : 0.0;
  }

  /// Initialize the loyalty program
  Future<void> initialize() async {
    try {
      _xpSystem = XPSystem.instance;
      _initializeBenefits();
      _initializeRewards();
      await _loadUserData();
      _updateTierAndBenefits();
      
      debugPrint('LoyaltyProgram initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize LoyaltyProgram: $e');
      _setError('Failed to initialize loyalty program');
    }
  }

  /// Award loyalty points
  Future<void> awardPoints(int points, String description, {String? orderId}) async {
    final transaction = LoyaltyTransaction(
      id: 'loyalty_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'current_user', // In real app, get from auth
      type: 'earned',
      points: points,
      description: description,
      timestamp: DateTime.now(),
      orderId: orderId,
    );

    _loyaltyPoints += points;
    _transactions.insert(0, transaction);
    
    // Check for tier upgrade
    final oldTier = _currentTier;
    _updateTierAndBenefits();
    
    await _saveUserData();
    notifyListeners();

    // Show tier upgrade notification
    if (_currentTier != oldTier) {
      _showTierUpgradeNotification(oldTier, _currentTier);
    }
  }

  /// Redeem loyalty points for rewards
  Future<bool> redeemReward(LoyaltyReward reward) async {
    if (!reward.canRedeem(_currentTier, _loyaltyPoints)) {
      _setError('Cannot redeem this reward');
      return false;
    }

    _setLoading(true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Deduct points
      final transaction = LoyaltyTransaction(
        id: 'loyalty_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current_user',
        type: 'redeemed',
        points: -reward.pointsCost,
        description: 'Redeemed: ${reward.title}',
        timestamp: DateTime.now(),
        metadata: {'reward_id': reward.id},
      );

      _loyaltyPoints -= reward.pointsCost;
      _transactions.insert(0, transaction);
      _redeemedRewards[reward.id] = DateTime.now();

      await _saveUserData();
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to redeem reward: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get benefits available for current tier
  List<LoyaltyBenefit> getBenefitsForTier(LoyaltyTier tier) {
    return _allBenefits.where((benefit) => 
      benefit.requiredTier.index <= tier.index && benefit.isActive && !benefit.isExpired
    ).toList();
  }

  /// Get rewards available for current tier
  List<LoyaltyReward> getRewardsForTier(LoyaltyTier tier) {
    return _availableRewards.where((reward) => 
      reward.isAvailable && !reward.isExpired && !reward.isOutOfStock &&
      (reward.minimumTier == null || reward.minimumTier!.index <= tier.index)
    ).toList();
  }

  /// Get transaction history with pagination
  List<LoyaltyTransaction> getTransactionHistory({int limit = 50}) {
    return _transactions.take(limit).toList();
  }

  /// Calculate points earned from purchase
  int calculatePointsFromPurchase(double purchaseAmount) {
    double multiplier = 1.0;
    
    // Tier-based multipliers
    switch (_currentTier) {
      case LoyaltyTier.bronze:
        multiplier = 1.0;
        break;
      case LoyaltyTier.silver:
        multiplier = 1.2;
        break;
      case LoyaltyTier.gold:
        multiplier = 1.5;
        break;
      case LoyaltyTier.platinum:
        multiplier = 2.0;
        break;
      case LoyaltyTier.diamond:
        multiplier = 2.5;
        break;
    }
    
    // Base: 1 point per dollar spent
    return (purchaseAmount * multiplier).round();
  }

  /// Get discount percentage for current tier
  double getDiscountPercentage() {
    switch (_currentTier) {
      case LoyaltyTier.bronze:
        return 0.0;
      case LoyaltyTier.silver:
        return 5.0;
      case LoyaltyTier.gold:
        return 10.0;
      case LoyaltyTier.platinum:
        return 15.0;
      case LoyaltyTier.diamond:
        return 20.0;
    }
  }

  /// Check if user has free shipping benefit
  bool hasFreeShipping() {
    return _activeBenefits.any((benefit) => 
      benefit.type == BenefitType.freeShipping && benefit.isActive
    );
  }

  /// Check if user has early access benefit
  bool hasEarlyAccess() {
    return _activeBenefits.any((benefit) => 
      benefit.type == BenefitType.earlyAccess && benefit.isActive
    );
  }

  /// Reset loyalty program (for testing)
  Future<void> reset() async {
    _loyaltyPoints = 0;
    _currentTier = LoyaltyTier.bronze;
    _transactions.clear();
    _activeBenefits.clear();
    _redeemedRewards.clear();
    
    _updateTierAndBenefits();
    await _saveUserData();
    notifyListeners();
  }

  // =============================================================================
  // PRIVATE HELPER METHODS
  // =============================================================================

  /// Initialize loyalty benefits
  void _initializeBenefits() {
    _allBenefits = [
      // Bronze benefits
      const LoyaltyBenefit(
        id: 'welcome_points',
        title: 'Welcome Bonus',
        description: 'Get 100 bonus points on signup',
        type: BenefitType.bonusPoints,
        value: 100,
        requiredTier: LoyaltyTier.bronze,
        icon: Icons.card_giftcard,
      ),
      
      // Silver benefits
      const LoyaltyBenefit(
        id: 'silver_discount',
        title: '5% Member Discount',
        description: 'Get 5% off all purchases',
        type: BenefitType.discount,
        value: 5.0,
        requiredTier: LoyaltyTier.silver,
        icon: Icons.percent,
      ),
      
      // Gold benefits
      const LoyaltyBenefit(
        id: 'free_shipping',
        title: 'Free Shipping',
        description: 'Free shipping on all orders',
        type: BenefitType.freeShipping,
        value: true,
        requiredTier: LoyaltyTier.gold,
        icon: Icons.local_shipping,
      ),
      const LoyaltyBenefit(
        id: 'gold_discount',
        title: '10% Member Discount',
        description: 'Get 10% off all purchases',
        type: BenefitType.discount,
        value: 10.0,
        requiredTier: LoyaltyTier.gold,
        icon: Icons.percent,
      ),
      
      // Platinum benefits
      const LoyaltyBenefit(
        id: 'early_access',
        title: 'Early Access',
        description: 'Get early access to sales and new products',
        type: BenefitType.earlyAccess,
        value: true,
        requiredTier: LoyaltyTier.platinum,
        icon: Icons.schedule,
      ),
      const LoyaltyBenefit(
        id: 'priority_support',
        title: 'Priority Support',
        description: 'Get priority customer support',
        type: BenefitType.prioritySupport,
        value: true,
        requiredTier: LoyaltyTier.platinum,
        icon: Icons.support_agent,
      ),
      const LoyaltyBenefit(
        id: 'platinum_discount',
        title: '15% Member Discount',
        description: 'Get 15% off all purchases',
        type: BenefitType.discount,
        value: 15.0,
        requiredTier: LoyaltyTier.platinum,
        icon: Icons.percent,
      ),
      
      // Diamond benefits
      const LoyaltyBenefit(
        id: 'exclusive_products',
        title: 'Exclusive Products',
        description: 'Access to diamond-only exclusive products',
        type: BenefitType.exclusiveProducts,
        value: true,
        requiredTier: LoyaltyTier.diamond,
        icon: Icons.star,
      ),
      const LoyaltyBenefit(
        id: 'birthday_reward',
        title: 'Birthday Reward',
        description: 'Special birthday bonus points and gifts',
        type: BenefitType.birthdayReward,
        value: 500,
        requiredTier: LoyaltyTier.diamond,
        icon: Icons.cake,
      ),
      const LoyaltyBenefit(
        id: 'diamond_discount',
        title: '20% Member Discount',
        description: 'Get 20% off all purchases',
        type: BenefitType.discount,
        value: 20.0,
        requiredTier: LoyaltyTier.diamond,
        icon: Icons.percent,
      ),
    ];
  }

  /// Initialize loyalty rewards
  void _initializeRewards() {
    _availableRewards = [
      // Low-tier rewards
      const LoyaltyReward(
        id: 'discount_5',
        title: '\$5 Off Coupon',
        description: 'Get \$5 off your next purchase',
        pointsCost: 500,
        imageUrl: 'https://example.com/coupon5.jpg',
        category: 'Discounts',
      ),
      const LoyaltyReward(
        id: 'free_shipping_voucher',
        title: 'Free Shipping Voucher',
        description: 'Free shipping on your next order',
        pointsCost: 300,
        imageUrl: 'https://example.com/shipping.jpg',
        category: 'Shipping',
      ),
      
      // Mid-tier rewards
      const LoyaltyReward(
        id: 'discount_10',
        title: '\$10 Off Coupon',
        description: 'Get \$10 off your next purchase',
        pointsCost: 1000,
        imageUrl: 'https://example.com/coupon10.jpg',
        category: 'Discounts',
        minimumTier: LoyaltyTier.silver,
      ),
      const LoyaltyReward(
        id: 'premium_support',
        title: '1 Month Premium Support',
        description: 'Get premium customer support for 1 month',
        pointsCost: 2000,
        imageUrl: 'https://example.com/support.jpg',
        category: 'Services',
        minimumTier: LoyaltyTier.gold,
      ),
      
      // High-tier rewards
      const LoyaltyReward(
        id: 'exclusive_product',
        title: 'Exclusive Limited Edition Product',
        description: 'Access to limited edition exclusive products',
        pointsCost: 5000,
        imageUrl: 'https://example.com/exclusive.jpg',
        category: 'Products',
        minimumTier: LoyaltyTier.platinum,
        quantityLimit: 100,
        quantityRemaining: 87,
      ),
      const LoyaltyReward(
        id: 'vip_experience',
        title: 'VIP Shopping Experience',
        description: 'Personal shopping session with style expert',
        pointsCost: 10000,
        imageUrl: 'https://example.com/vip.jpg',
        category: 'Experiences',
        minimumTier: LoyaltyTier.diamond,
        quantityLimit: 10,
        quantityRemaining: 7,
      ),
    ];
  }

  /// Update user tier and active benefits
  void _updateTierAndBenefits() {
    // Update tier based on points
    for (int i = LoyaltyTier.values.length - 1; i >= 0; i--) {
      final tier = LoyaltyTier.values[i];
      if (_loyaltyPoints >= tier.requiredPoints) {
        _currentTier = tier;
        break;
      }
    }

    // Update active benefits
    _activeBenefits = getBenefitsForTier(_currentTier);
  }

  /// Save user data to storage
  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final data = {
        'loyalty_points': _loyaltyPoints,
        'current_tier': _currentTier.name,
        'transactions': _transactions.map((t) => t.toJson()).toList(),
        'redeemed_rewards': _redeemedRewards.map(
          (key, value) => MapEntry(key, value.toIso8601String())
        ),
      };
      
      await prefs.setString('loyalty_program_data', jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving loyalty program data: $e');
    }
  }

  /// Load user data from storage
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('loyalty_program_data');
      
      if (dataString != null) {
        final data = jsonDecode(dataString);
        
        _loyaltyPoints = data['loyalty_points'] ?? 0;
        _currentTier = LoyaltyTier.values.firstWhere(
          (tier) => tier.name == data['current_tier'],
          orElse: () => LoyaltyTier.bronze,
        );
        
        _transactions = (data['transactions'] as List? ?? [])
            .map((t) => LoyaltyTransaction.fromJson(t))
            .toList();
        
        final redeemedData = data['redeemed_rewards'] as Map<String, dynamic>? ?? {};
        _redeemedRewards = redeemedData.map(
          (key, value) => MapEntry(key, DateTime.parse(value))
        );
      }
    } catch (e) {
      debugPrint('Error loading loyalty program data: $e');
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Show tier upgrade notification
  void _showTierUpgradeNotification(LoyaltyTier oldTier, LoyaltyTier newTier) {
    debugPrint('🎉 Tier Upgrade! ${oldTier.displayName} → ${newTier.displayName}');
    // In a real app, this would show a toast or dialog
  }
}