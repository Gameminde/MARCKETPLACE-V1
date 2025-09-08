import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../core/config/app_constants.dart';
import '../services/cache_service.dart';

/// XP Action types that users can perform to earn points
enum XPAction {
  registration(100, 'Welcome to Marketplace!'),
  profileComplete(50, 'Profile completed'),
  firstPurchase(200, 'First purchase made'),
  purchase(20, 'Purchase completed'),
  review(30, 'Review submitted'),
  photoReview(50, 'Photo review submitted'),
  referral(100, 'Friend referred'),
  wishlistAdd(5, 'Item added to wishlist'),
  shareProduct(10, 'Product shared'),
  dailyLogin(5, 'Daily login bonus'),
  weeklyLogin(25, 'Weekly login streak'),
  categoryExplorer(15, 'New category explored'),
  bargainHunter(40, 'Used discount code'),
  loyalCustomer(75, 'Loyalty milestone reached'),
  socialConnect(30, 'Social account connected'),
  feedbackSubmit(25, 'Feedback submitted'),
  tutorialComplete(20, 'Tutorial completed'),
  achievementUnlock(50, 'Achievement unlocked');

  const XPAction(this.points, this.description);
  final int points;
  final String description;
}

/// Badge rarity levels
enum BadgeRarity { common, uncommon, rare, epic, legendary }

/// User badge model
class Badge {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final BadgeRarity rarity;
  final int requiredXP;
  final List<XPAction> requiredActions;
  final Map<String, dynamic>? criteria;
  final DateTime? unlockedAt;
  final bool isUnlocked;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.rarity,
    this.requiredXP = 0,
    this.requiredActions = const [],
    this.criteria,
    this.unlockedAt,
    this.isUnlocked = false,
  });

  Badge copyWith({
    String? id,
    String? name,
    String? description,
    String? iconPath,
    BadgeRarity? rarity,
    int? requiredXP,
    List<XPAction>? requiredActions,
    Map<String, dynamic>? criteria,
    DateTime? unlockedAt,
    bool? isUnlocked,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      rarity: rarity ?? this.rarity,
      requiredXP: requiredXP ?? this.requiredXP,
      requiredActions: requiredActions ?? this.requiredActions,
      criteria: criteria ?? this.criteria,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_path': iconPath,
      'rarity': rarity.name,
      'required_xp': requiredXP,
      'required_actions': requiredActions.map((a) => a.name).toList(),
      'criteria': criteria,
      'unlocked_at': unlockedAt?.toIso8601String(),
      'is_unlocked': isUnlocked,
    };
  }

  static Badge fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconPath: json['icon_path'],
      rarity: BadgeRarity.values.firstWhere((e) => e.name == json['rarity']),
      requiredXP: json['required_xp'] ?? 0,
      requiredActions: (json['required_actions'] as List? ?? [])
          .map((action) => XPAction.values.firstWhere((e) => e.name == action))
          .toList(),
      criteria: json['criteria'],
      unlockedAt: json['unlocked_at'] != null 
          ? DateTime.parse(json['unlocked_at']) 
          : null,
      isUnlocked: json['is_unlocked'] ?? false,
    );
  }

  Color get rarityColor {
    switch (rarity) {
      case BadgeRarity.common:
        return Colors.grey;
      case BadgeRarity.uncommon:
        return Colors.green;
      case BadgeRarity.rare:
        return Colors.blue;
      case BadgeRarity.epic:
        return Colors.purple;
      case BadgeRarity.legendary:
        return Colors.orange;
    }
  }
}

/// XP transaction record
class XPTransaction {
  final String id;
  final XPAction action;
  final int points;
  final DateTime timestamp;
  final String? description;
  final Map<String, dynamic>? metadata;

  const XPTransaction({
    required this.id,
    required this.action,
    required this.points,
    required this.timestamp,
    this.description,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action.name,
      'points': points,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'metadata': metadata,
    };
  }

  static XPTransaction fromJson(Map<String, dynamic> json) {
    return XPTransaction(
      id: json['id'],
      action: XPAction.values.firstWhere((e) => e.name == json['action']),
      points: json['points'],
      timestamp: DateTime.parse(json['timestamp']),
      description: json['description'],
      metadata: json['metadata'],
    );
  }
}

/// User level configuration
class UserLevel {
  final int level;
  final String title;
  final int requiredXP;
  final int nextLevelXP;
  final List<String> benefits;
  final Color color;

  const UserLevel({
    required this.level,
    required this.title,
    required this.requiredXP,
    required this.nextLevelXP,
    required this.benefits,
    required this.color,
  });

  double getProgress(int currentXP) {
    if (currentXP >= nextLevelXP) return 1.0;
    final xpInLevel = currentXP - requiredXP;
    final xpNeededForLevel = nextLevelXP - requiredXP;
    return xpNeededForLevel > 0 ? xpInLevel / xpNeededForLevel : 0.0;
  }
}

/// Leaderboard entry
class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int totalXP;
  final int level;
  final int rank;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.totalXP,
    required this.level,
    required this.rank,
    this.isCurrentUser = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'total_xp': totalXP,
      'level': level,
      'rank': rank,
      'is_current_user': isCurrentUser,
    };
  }

  static LeaderboardEntry fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      totalXP: json['total_xp'],
      level: json['level'],
      rank: json['rank'],
      isCurrentUser: json['is_current_user'] ?? false,
    );
  }
}

/// Comprehensive XP System for gamification
class XPSystem extends ChangeNotifier {
  static XPSystem? _instance;
  static XPSystem get instance => _instance ??= XPSystem._internal();
  
  XPSystem._internal();

  // User XP data
  int _totalXP = 0;
  int _currentLevel = 1;
  List<XPTransaction> _transactions = [];
  List<Badge> _unlockedBadges = [];
  Map<XPAction, int> _actionCounts = {};
  DateTime? _lastLoginDate;
  int _consecutiveLoginDays = 0;

  // System configuration
  bool _isInitialized = false;
  late List<Badge> _availableBadges;
  late List<UserLevel> _userLevels;

  // Getters
  int get totalXP => _totalXP;
  int get currentLevel => _currentLevel;
  List<XPTransaction> get transactions => List.unmodifiable(_transactions);
  List<Badge> get unlockedBadges => List.unmodifiable(_unlockedBadges);
  Map<XPAction, int> get actionCounts => Map.unmodifiable(_actionCounts);
  int get consecutiveLoginDays => _consecutiveLoginDays;
  
  UserLevel get currentLevelInfo => _userLevels.firstWhere(
    (level) => level.level == _currentLevel,
    orElse: () => _userLevels.first,
  );
  
  UserLevel? get nextLevelInfo => _userLevels.where(
    (level) => level.level == _currentLevel + 1,
  ).isNotEmpty ? _userLevels.firstWhere(
    (level) => level.level == _currentLevel + 1,
  ) : null;

  double get levelProgress {
    final current = currentLevelInfo;
    final next = nextLevelInfo;
    if (next == null) return 1.0;
    return current.getProgress(_totalXP);
  }

  int get xpToNextLevel {
    final next = nextLevelInfo;
    if (next == null) return 0;
    return next.requiredXP - _totalXP;
  }

  /// Initialize the XP System
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _initializeBadges();
      _initializeUserLevels();
      await _loadUserData();
      await _checkDailyLogin();
      _isInitialized = true;
      
      debugPrint('XPSystem initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize XPSystem: $e');
    }
  }

  /// Add XP for completing an action
  Future<void> addXP(XPAction action, {String? customDescription, Map<String, dynamic>? metadata}) async {
    if (!_isInitialized) await initialize();

    final points = action.points;
    final transaction = XPTransaction(
      id: 'xp_${DateTime.now().millisecondsSinceEpoch}',
      action: action,
      points: points,
      timestamp: DateTime.now(),
      description: customDescription ?? action.description,
      metadata: metadata,
    );

    _totalXP += points;
    _transactions.insert(0, transaction);
    _actionCounts[action] = (_actionCounts[action] ?? 0) + 1;

    // Check for level up
    final oldLevel = _currentLevel;
    _updateLevel();
    
    // Check for new badges
    final newBadges = await _checkForNewBadges();

    // Save data
    await _saveUserData();

    notifyListeners();

    // Show notifications for level up and new badges
    if (_currentLevel > oldLevel) {
      _showLevelUpNotification(oldLevel, _currentLevel);
    }
    
    for (final badge in newBadges) {
      _showBadgeUnlockedNotification(badge);
    }
  }

  /// Get recent XP transactions
  List<XPTransaction> getRecentTransactions({int limit = 10}) {
    return _transactions.take(limit).toList();
  }

  /// Get XP transactions for a specific action
  List<XPTransaction> getTransactionsByAction(XPAction action) {
    return _transactions.where((t) => t.action == action).toList();
  }

  /// Get available badges (locked and unlocked)
  List<Badge> getAvailableBadges() {
    return _availableBadges.map((badge) {
      final isUnlocked = _unlockedBadges.any((b) => b.id == badge.id);
      final unlockedBadge = isUnlocked 
          ? _unlockedBadges.firstWhere((b) => b.id == badge.id)
          : null;
      
      return badge.copyWith(
        isUnlocked: isUnlocked,
        unlockedAt: unlockedBadge?.unlockedAt,
      );
    }).toList();
  }

  /// Get badges by rarity
  List<Badge> getBadgesByRarity(BadgeRarity rarity) {
    return getAvailableBadges().where((b) => b.rarity == rarity).toList();
  }

  /// Get user's rank (mock implementation)
  Future<int> getUserRank() async {
    // In a real app, this would fetch from server
    await Future.delayed(const Duration(milliseconds: 500));
    return 156; // Mock rank
  }

  /// Get leaderboard (mock implementation)
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 100}) async {
    // In a real app, this would fetch from server
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock leaderboard data
    return [
      LeaderboardEntry(
        userId: 'user_1',
        username: 'ShopMaster2024',
        avatarUrl: 'https://example.com/avatar1.jpg',
        totalXP: 15420,
        level: 8,
        rank: 1,
      ),
      LeaderboardEntry(
        userId: 'user_2',
        username: 'DealHunter',
        avatarUrl: 'https://example.com/avatar2.jpg',
        totalXP: 12890,
        level: 7,
        rank: 2,
      ),
      LeaderboardEntry(
        userId: 'current_user',
        username: 'You',
        totalXP: _totalXP,
        level: _currentLevel,
        rank: await getUserRank(),
        isCurrentUser: true,
      ),
      // Add more mock entries...
    ];
  }

  /// Reset XP system (for testing)
  Future<void> reset() async {
    _totalXP = 0;
    _currentLevel = 1;
    _transactions.clear();
    _unlockedBadges.clear();
    _actionCounts.clear();
    _lastLoginDate = null;
    _consecutiveLoginDays = 0;
    
    await _saveUserData();
    notifyListeners();
  }

  // =============================================================================
  // PRIVATE HELPER METHODS
  // =============================================================================

  /// Initialize available badges
  void _initializeBadges() {
    _availableBadges = [
      // Welcome badges
      const Badge(
        id: 'welcome',
        name: 'Welcome!',
        description: 'Welcome to the marketplace',
        iconPath: 'assets/icons/badges/welcome.png',
        rarity: BadgeRarity.common,
        requiredActions: [XPAction.registration],
      ),
      
      // Shopping badges
      const Badge(
        id: 'first_purchase',
        name: 'First Purchase',
        description: 'Made your first purchase',
        iconPath: 'assets/icons/badges/first_purchase.png',
        rarity: BadgeRarity.uncommon,
        requiredActions: [XPAction.firstPurchase],
      ),
      
      const Badge(
        id: 'shopping_spree',
        name: 'Shopping Spree',
        description: 'Made 10 purchases',
        iconPath: 'assets/icons/badges/shopping_spree.png',
        rarity: BadgeRarity.rare,
        criteria: {'purchase_count': 10},
      ),
      
      // Review badges
      const Badge(
        id: 'reviewer',
        name: 'Reviewer',
        description: 'Submitted 5 reviews',
        iconPath: 'assets/icons/badges/reviewer.png',
        rarity: BadgeRarity.uncommon,
        criteria: {'review_count': 5},
      ),
      
      const Badge(
        id: 'photo_reviewer',
        name: 'Photo Reviewer',
        description: 'Submitted 5 reviews with photos',
        iconPath: 'assets/icons/badges/photo_reviewer.png',
        rarity: BadgeRarity.rare,
        criteria: {'photo_review_count': 5},
      ),
      
      // Social badges
      const Badge(
        id: 'influencer',
        name: 'Influencer',
        description: 'Shared 20 products',
        iconPath: 'assets/icons/badges/influencer.png',
        rarity: BadgeRarity.epic,
        criteria: {'share_count': 20},
      ),
      
      // Loyalty badges
      const Badge(
        id: 'loyal_customer',
        name: 'Loyal Customer',
        description: 'Reached 1000 XP',
        iconPath: 'assets/icons/badges/loyal_customer.png',
        rarity: BadgeRarity.rare,
        requiredXP: 1000,
      ),
      
      const Badge(
        id: 'vip_member',
        name: 'VIP Member',
        description: 'Reached 5000 XP',
        iconPath: 'assets/icons/badges/vip_member.png',
        rarity: BadgeRarity.epic,
        requiredXP: 5000,
      ),
      
      const Badge(
        id: 'legend',
        name: 'Legend',
        description: 'Reached 10000 XP',
        iconPath: 'assets/icons/badges/legend.png',
        rarity: BadgeRarity.legendary,
        requiredXP: 10000,
      ),
      
      // Activity badges
      const Badge(
        id: 'daily_visitor',
        name: 'Daily Visitor',
        description: 'Logged in for 7 consecutive days',
        iconPath: 'assets/icons/badges/daily_visitor.png',
        rarity: BadgeRarity.uncommon,
        criteria: {'consecutive_login_days': 7},
      ),
      
      const Badge(
        id: 'dedicated_user',
        name: 'Dedicated User',
        description: 'Logged in for 30 consecutive days',
        iconPath: 'assets/icons/badges/dedicated_user.png',
        rarity: BadgeRarity.epic,
        criteria: {'consecutive_login_days': 30},
      ),
    ];
  }

  /// Initialize user levels
  void _initializeUserLevels() {
    _userLevels = [
      const UserLevel(
        level: 1,
        title: 'Newcomer',
        requiredXP: 0,
        nextLevelXP: 100,
        benefits: ['Basic shopping access'],
        color: Colors.grey,
      ),
      const UserLevel(
        level: 2,
        title: 'Shopper',
        requiredXP: 100,
        nextLevelXP: 250,
        benefits: ['Wishlist access', 'Basic discounts'],
        color: Colors.brown,
      ),
      const UserLevel(
        level: 3,
        title: 'Regular',
        requiredXP: 250,
        nextLevelXP: 500,
        benefits: ['Review access', '5% discount'],
        color: Colors.green,
      ),
      const UserLevel(
        level: 4,
        title: 'Frequent',
        requiredXP: 500,
        nextLevelXP: 1000,
        benefits: ['Priority support', '7% discount'],
        color: Colors.blue,
      ),
      const UserLevel(
        level: 5,
        title: 'Valued',
        requiredXP: 1000,
        nextLevelXP: 2000,
        benefits: ['Early access', '10% discount'],
        color: Colors.purple,
      ),
      const UserLevel(
        level: 6,
        title: 'Premium',
        requiredXP: 2000,
        nextLevelXP: 4000,
        benefits: ['Free shipping', '12% discount'],
        color: Colors.orange,
      ),
      const UserLevel(
        level: 7,
        title: 'Elite',
        requiredXP: 4000,
        nextLevelXP: 7000,
        benefits: ['VIP support', '15% discount'],
        color: Colors.red,
      ),
      const UserLevel(
        level: 8,
        title: 'Champion',
        requiredXP: 7000,
        nextLevelXP: 12000,
        benefits: ['Exclusive access', '18% discount'],
        color: Colors.indigo,
      ),
      const UserLevel(
        level: 9,
        title: 'Master',
        requiredXP: 12000,
        nextLevelXP: 20000,
        benefits: ['Master benefits', '20% discount'],
        color: Colors.deepPurple,
      ),
      const UserLevel(
        level: 10,
        title: 'Legend',
        requiredXP: 20000,
        nextLevelXP: 35000,
        benefits: ['Legendary status', '25% discount'],
        color: Colors.amber,
      ),
    ];
  }

  /// Update user level based on XP
  void _updateLevel() {
    for (final level in _userLevels.reversed) {
      if (_totalXP >= level.requiredXP) {
        _currentLevel = level.level;
        break;
      }
    }
  }

  /// Check for newly unlocked badges
  Future<List<Badge>> _checkForNewBadges() async {
    final newBadges = <Badge>[];
    
    for (final badge in _availableBadges) {
      // Skip if already unlocked
      if (_unlockedBadges.any((b) => b.id == badge.id)) continue;
      
      bool shouldUnlock = false;
      
      // Check XP requirement
      if (badge.requiredXP > 0 && _totalXP >= badge.requiredXP) {
        shouldUnlock = true;
      }
      
      // Check action requirements
      if (badge.requiredActions.isNotEmpty) {
        shouldUnlock = badge.requiredActions.every((action) => 
          _actionCounts.containsKey(action) && _actionCounts[action]! > 0
        );
      }
      
      // Check custom criteria
      if (badge.criteria != null) {
        shouldUnlock = _checkBadgeCriteria(badge.criteria!);
      }
      
      if (shouldUnlock) {
        final unlockedBadge = badge.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        
        _unlockedBadges.add(unlockedBadge);
        newBadges.add(unlockedBadge);
        
        // Award XP for unlocking achievement
        await addXP(XPAction.achievementUnlock, 
          customDescription: 'Unlocked badge: ${badge.name}');
      }
    }
    
    return newBadges;
  }

  /// Check custom badge criteria
  bool _checkBadgeCriteria(Map<String, dynamic> criteria) {
    for (final entry in criteria.entries) {
      switch (entry.key) {
        case 'purchase_count':
          if ((_actionCounts[XPAction.purchase] ?? 0) < entry.value) return false;
          break;
        case 'review_count':
          if ((_actionCounts[XPAction.review] ?? 0) < entry.value) return false;
          break;
        case 'photo_review_count':
          if ((_actionCounts[XPAction.photoReview] ?? 0) < entry.value) return false;
          break;
        case 'share_count':
          if ((_actionCounts[XPAction.shareProduct] ?? 0) < entry.value) return false;
          break;
        case 'consecutive_login_days':
          if (_consecutiveLoginDays < entry.value) return false;
          break;
      }
    }
    return true;
  }

  /// Check and update daily login streak
  Future<void> _checkDailyLogin() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_lastLoginDate == null) {
      // First login
      _lastLoginDate = today;
      _consecutiveLoginDays = 1;
      await addXP(XPAction.dailyLogin);
    } else {
      final lastLogin = DateTime(_lastLoginDate!.year, _lastLoginDate!.month, _lastLoginDate!.day);
      final daysDifference = today.difference(lastLogin).inDays;
      
      if (daysDifference == 1) {
        // Consecutive day
        _consecutiveLoginDays++;
        _lastLoginDate = today;
        
        if (_consecutiveLoginDays % 7 == 0) {
          await addXP(XPAction.weeklyLogin);
        } else {
          await addXP(XPAction.dailyLogin);
        }
      } else if (daysDifference > 1) {
        // Streak broken
        _consecutiveLoginDays = 1;
        _lastLoginDate = today;
        await addXP(XPAction.dailyLogin);
      }
      // If daysDifference == 0, user already logged in today
    }
  }

  /// Save user data to storage
  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final data = {
        'total_xp': _totalXP,
        'current_level': _currentLevel,
        'transactions': _transactions.map((t) => t.toJson()).toList(),
        'unlocked_badges': _unlockedBadges.map((b) => b.toJson()).toList(),
        'action_counts': _actionCounts.map((k, v) => MapEntry(k.name, v)),
        'last_login_date': _lastLoginDate?.toIso8601String(),
        'consecutive_login_days': _consecutiveLoginDays,
      };
      
      await prefs.setString('xp_system_data', jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving XP system data: $e');
    }
  }

  /// Load user data from storage
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('xp_system_data');
      
      if (dataString != null) {
        final data = jsonDecode(dataString);
        
        _totalXP = data['total_xp'] ?? 0;
        _currentLevel = data['current_level'] ?? 1;
        
        _transactions = (data['transactions'] as List? ?? [])
            .map((t) => XPTransaction.fromJson(t))
            .toList();
        
        _unlockedBadges = (data['unlocked_badges'] as List? ?? [])
            .map((b) => Badge.fromJson(b))
            .toList();
        
        final actionCountsData = data['action_counts'] as Map<String, dynamic>? ?? {};
        _actionCounts = actionCountsData.map((k, v) => MapEntry(
          XPAction.values.firstWhere((action) => action.name == k),
          v as int,
        ));
        
        _lastLoginDate = data['last_login_date'] != null 
            ? DateTime.parse(data['last_login_date'])
            : null;
            
        _consecutiveLoginDays = data['consecutive_login_days'] ?? 0;
        
        _updateLevel();
      }
    } catch (e) {
      debugPrint('Error loading XP system data: $e');
    }
  }

  /// Show level up notification
  void _showLevelUpNotification(int oldLevel, int newLevel) {
    debugPrint('🎉 Level Up! $oldLevel → $newLevel');
    // In a real app, this would show a toast or dialog
  }

  /// Show badge unlocked notification
  void _showBadgeUnlockedNotification(Badge badge) {
    debugPrint('🏆 Badge Unlocked: ${badge.name}');
    // In a real app, this would show a toast or dialog
  }
}