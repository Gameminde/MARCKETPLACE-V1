import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import '../core/config/app_constants.dart';
import '../services/xp_system.dart';
import '../widgets/glassmorphic_container.dart';

/// Comprehensive gamification screen showing XP, badges, and leaderboards
class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoadingLeaderboard = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLeaderboard();
    XPSystem.instance.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Progress', icon: Icon(Icons.trending_up)),
            Tab(text: 'Badges', icon: Icon(Icons.military_tech)),
            Tab(text: 'Leaderboard', icon: Icon(Icons.leaderboard)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProgressTab(),
          _buildBadgesTab(),
          _buildLeaderboardTab(),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return Consumer<XPSystem>(
      builder: (context, xpSystem, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            children: [
              _buildLevelCard(xpSystem),
              const SizedBox(height: AppConstants.spacingL),
              _buildXPStatsCard(xpSystem),
              const SizedBox(height: AppConstants.spacingL),
              _buildRecentActivityCard(xpSystem),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadgesTab() {
    return Consumer<XPSystem>(
      builder: (context, xpSystem, child) {
        final badges = xpSystem.getAvailableBadges();
        final unlockedBadges = badges.where((b) => b.isUnlocked).toList();
        final lockedBadges = badges.where((b) => !b.isUnlocked).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge summary
              GlassmorphicContainer.card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Row(
                    children: [
                      Icon(
                        Icons.military_tech,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Badge Collection',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${unlockedBadges.length} of ${badges.length} badges unlocked',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircularProgressIndicator(
                        value: badges.isNotEmpty ? unlockedBadges.length / badges.length : 0,
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        strokeWidth: 3,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppConstants.spacingL),
              
              // Unlocked badges
              if (unlockedBadges.isNotEmpty) ...[
                Text(
                  'Unlocked Badges',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildBadgeGrid(unlockedBadges, unlocked: true),
                const SizedBox(height: AppConstants.spacingL),
              ],
              
              // Locked badges
              Text(
                'Locked Badges',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              _buildBadgeGrid(lockedBadges, unlocked: false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardTab() {
    return _isLoadingLeaderboard
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              children: [
                // Current user rank card
                Consumer<XPSystem>(
                  builder: (context, xpSystem, child) {
                    return GlassmorphicContainer.card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingL),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppConstants.spacingM),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Rank',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Level ${xpSystem.currentLevel} • ${xpSystem.totalXP} XP',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            FutureBuilder<int>(
                              future: xpSystem.getUserRank(),
                              builder: (context, snapshot) {
                                return Text(
                                  '#${snapshot.data ?? '?'}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: AppConstants.spacingL),
                
                // Leaderboard list
                GlassmorphicContainer.card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingL),
                        child: Row(
                          children: [
                            Icon(
                              Icons.leaderboard,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: AppConstants.spacingM),
                            Text(
                              'Top Players',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...List.generate(_leaderboard.length, (index) {
                        final entry = _leaderboard[index];
                        return _buildLeaderboardEntry(entry);
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildLevelCard(XPSystem xpSystem) {
    final currentLevel = xpSystem.currentLevelInfo;
    final nextLevel = xpSystem.nextLevelInfo;
    final progress = xpSystem.levelProgress;

    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: currentLevel.color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${currentLevel.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentLevel.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${xpSystem.totalXP} XP',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.spacingL),
            
            // Progress bar
            if (nextLevel != null) ...[
              Row(
                children: [
                  Text(
                    'Level ${currentLevel.level}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    'Level ${nextLevel.level}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingS),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(currentLevel.color),
              ),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                '${xpSystem.xpToNextLevel} XP to next level',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: currentLevel.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: currentLevel.color,
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Text(
                      'Max Level Reached!',
                      style: TextStyle(
                        color: currentLevel.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: AppConstants.spacingL),
            
            // Benefits
            Text(
              'Level Benefits',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            ...currentLevel.benefits.map((benefit) => Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: currentLevel.color,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  benefit,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildXPStatsCard(XPSystem xpSystem) {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'XP Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total XP',
                    '${xpSystem.totalXP}',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Login Streak',
                    '${xpSystem.consecutiveLoginDays} days',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Badges',
                    '${xpSystem.unlockedBadges.length}',
                    Icons.military_tech,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Activities',
                    '${xpSystem.transactions.length}',
                    Icons.show_chart,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(XPSystem xpSystem) {
    final recentTransactions = xpSystem.getRecentTransactions();
    
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            
            if (recentTransactions.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      'No recent activity',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...recentTransactions.take(5).map((transaction) => _buildActivityItem(transaction)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(XPTransaction transaction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingS),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add,
              color: Colors.green,
              size: 16,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? transaction.action.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  _formatDateTime(transaction.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${transaction.points} XP',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeGrid(List<Badge> badges, {required bool unlocked}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppConstants.spacingM,
        mainAxisSpacing: AppConstants.spacingM,
        childAspectRatio: 0.8,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _buildBadgeItem(badge, unlocked: unlocked);
      },
    );
  }

  Widget _buildBadgeItem(Badge badge, {required bool unlocked}) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(badge),
      child: GlassmorphicContainer.card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: unlocked ? badge.rarityColor : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  unlocked ? Icons.military_tech : Icons.lock,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                badge.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: unlocked ? null : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (unlocked && badge.unlockedAt != null) ...[
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  _formatDate(badge.unlockedAt!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingM,
      ),
      decoration: BoxDecoration(
        color: entry.isCurrentUser 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: entry.rank <= 3 ? _getRankColor(entry.rank) : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: AppConstants.spacingM),
          
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            child: entry.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      entry.avatarUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.person),
                    ),
                  )
                : const Icon(Icons.person),
          ),
          
          const SizedBox(width: AppConstants.spacingM),
          
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: entry.isCurrentUser ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  'Level ${entry.level}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // XP
          Text(
            '${entry.totalXP} XP',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return Colors.brown; // Bronze
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
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

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _showBadgeDetails(Badge badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(badge.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badge.description),
            const SizedBox(height: AppConstants.spacingM),
            Row(
              children: [
                const Text('Rarity: '),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badge.rarityColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge.rarity.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (badge.requiredXP > 0) ...[
              const SizedBox(height: AppConstants.spacingS),
              Text('Required XP: ${badge.requiredXP}'),
            ],
            if (badge.unlockedAt != null) ...[
              const SizedBox(height: AppConstants.spacingS),
              Text('Unlocked: ${_formatDate(badge.unlockedAt!)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoadingLeaderboard = true;
    });

    try {
      final leaderboard = await XPSystem.instance.getLeaderboard();
      setState(() {
        _leaderboard = leaderboard;
        _isLoadingLeaderboard = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLeaderboard = false;
      });
      debugPrint('Error loading leaderboard: $e');
    }
  }
}

/// XP progress widget for use in other screens
class XPProgressWidget extends StatelessWidget {
  final bool compact;
  
  const XPProgressWidget({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<XPSystem>(
      builder: (context, xpSystem, child) {
        if (compact) {
          return GlassmorphicContainer.card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: xpSystem.currentLevelInfo.color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${xpSystem.currentLevel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${xpSystem.totalXP} XP',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        LinearProgressIndicator(
                          value: xpSystem.levelProgress,
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation(xpSystem.currentLevelInfo.color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Full progress widget would go here
        return const SizedBox.shrink();
      },
    );
  }
}