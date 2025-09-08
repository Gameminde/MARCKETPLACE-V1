import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_constants.dart';
import '../services/loyalty_program.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/loading_states.dart';
import '../widgets/custom_app_bar.dart';

/// Comprehensive loyalty program screen
class LoyaltyProgramScreen extends StatefulWidget {
  const LoyaltyProgramScreen({super.key});

  @override
  State<LoyaltyProgramScreen> createState() => _LoyaltyProgramScreenState();
}

class _LoyaltyProgramScreenState extends State<LoyaltyProgramScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    LoyaltyProgram.instance.initialize();
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
        title: const Text('Loyalty Program'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Benefits', icon: Icon(Icons.card_giftcard)),
            Tab(text: 'Rewards', icon: Icon(Icons.redeem)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildBenefitsTab(),
          _buildRewardsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<LoyaltyProgram>(
      builder: (context, loyaltyProgram, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            children: [
              _buildTierCard(loyaltyProgram),
              const SizedBox(height: AppConstants.spacingL),
              _buildPointsCard(loyaltyProgram),
              const SizedBox(height: AppConstants.spacingL),
              _buildRecentActivityCard(loyaltyProgram),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBenefitsTab() {
    return Consumer<LoyaltyProgram>(
      builder: (context, loyaltyProgram, child) {
        final activeBenefits = loyaltyProgram.activeBenefits;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Current Benefits',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              
              if (activeBenefits.isEmpty)
                _buildEmptyState('No benefits available', Icons.card_giftcard)
              else
                ...activeBenefits.map((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                  child: _buildBenefitCard(benefit),
                )).toList(),
                
              const SizedBox(height: AppConstants.spacingL),
              
              Text(
                'Upcoming Benefits',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              _buildTierBenefitsPreview(loyaltyProgram),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRewardsTab() {
    return Consumer<LoyaltyProgram>(
      builder: (context, loyaltyProgram, child) {
        final rewards = loyaltyProgram.getRewardsForTier(loyaltyProgram.currentTier);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Rewards',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              
              if (rewards.isEmpty)
                _buildEmptyState('No rewards available', Icons.redeem)
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppConstants.spacingM,
                    mainAxisSpacing: AppConstants.spacingM,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: rewards.length,
                  itemBuilder: (context, index) {
                    return _buildRewardCard(rewards[index], loyaltyProgram);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTierCard(LoyaltyProgram loyaltyProgram) {
    final currentTier = loyaltyProgram.currentTier;
    final nextTier = loyaltyProgram.nextTier;
    final progress = loyaltyProgram.progressToNextTier;

    return GlassmorphicContainer.card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              currentTier.color.withOpacity(0.3),
              currentTier.color.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  decoration: BoxDecoration(
                    color: currentTier.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    currentTier.icon,
                    size: 32,
                    color: currentTier.color,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currentTier.displayName} Member',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: currentTier.color,
                        ),
                      ),
                      Text(
                        '${loyaltyProgram.loyaltyPoints} loyalty points',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (nextTier != null) ...[
              const SizedBox(height: AppConstants.spacingL),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress to ${nextTier.displayName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${loyaltyProgram.pointsToNextTier} points to go',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(nextTier.color),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: AppConstants.spacingL),
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: currentTier.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: currentTier.color,
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Text(
                      'Congratulations! You\'ve reached the highest tier!',
                      style: TextStyle(
                        color: currentTier.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard(LoyaltyProgram loyaltyProgram) {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Points Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            
            Row(
              children: [
                Expanded(
                  child: _buildPointsStatItem(
                    'Available Points',
                    '${loyaltyProgram.loyaltyPoints}',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildPointsStatItem(
                    'Discount Rate',
                    '${loyaltyProgram.getDiscountPercentage().toStringAsFixed(0)}%',
                    Icons.percent,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            Row(
              children: [
                Expanded(
                  child: _buildPointsStatItem(
                    'Total Earned',
                    '${loyaltyProgram.transactions.where((t) => t.isEarned).fold<int>(0, (sum, t) => sum + t.points)}',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildPointsStatItem(
                    'Total Redeemed',
                    '${loyaltyProgram.transactions.where((t) => t.isRedeemed).fold<int>(0, (sum, t) => sum + t.points.abs())}',
                    Icons.redeem,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsStatItem(String label, String value, IconData icon, Color color) {
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(LoyaltyProgram loyaltyProgram) {
    final recentTransactions = loyaltyProgram.getTransactionHistory(limit: 5);
    
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _showFullHistory(loyaltyProgram),
                  child: const Text('View All'),
                ),
              ],
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
              ...recentTransactions.map((transaction) => 
                _buildTransactionItem(transaction)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(LoyaltyTransaction transaction) {
    final isPositive = transaction.points > 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingS),
            decoration: BoxDecoration(
              color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.add : Icons.remove,
              color: isPositive ? Colors.green : Colors.red,
              size: 16,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
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
            '${isPositive ? '+' : ''}${transaction.points}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(LoyaltyBenefit benefit) {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: benefit.requiredTier.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                benefit.icon,
                color: benefit.requiredTier.color,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    benefit.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Text(
                    benefit.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingS,
                vertical: AppConstants.spacingXS,
              ),
              decoration: BoxDecoration(
                color: benefit.requiredTier.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                benefit.requiredTier.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierBenefitsPreview(LoyaltyProgram loyaltyProgram) {
    final nextTier = loyaltyProgram.nextTier;
    if (nextTier == null) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: const Center(
          child: Text('You\'ve unlocked all benefits!'),
        ),
      );
    }

    final nextBenefits = loyaltyProgram.getBenefitsForTier(nextTier)
        .where((benefit) => !loyaltyProgram.activeBenefits.contains(benefit))
        .toList();

    return Column(
      children: nextBenefits.map((benefit) => Padding(
        padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
        child: Opacity(
          opacity: 0.7,
          child: _buildBenefitCard(benefit),
        ),
      )).toList(),
    );
  }

  Widget _buildRewardCard(LoyaltyReward reward, LoyaltyProgram loyaltyProgram) {
    final canRedeem = reward.canRedeem(loyaltyProgram.currentTier, loyaltyProgram.loyaltyPoints);
    
    return GlassmorphicContainer.card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.borderRadius),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.card_giftcard,
                  size: 48,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  reward.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppConstants.spacingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${reward.pointsCost} pts',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: canRedeem
                          ? () => _redeemReward(reward, loyaltyProgram)
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(60, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        canRedeem ? 'Redeem' : 'Locked',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
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

  void _redeemReward(LoyaltyReward reward, LoyaltyProgram loyaltyProgram) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redeem ${reward.title}?'),
        content: Text(
          'This will cost ${reward.pointsCost} loyalty points. Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await loyaltyProgram.redeemReward(reward);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully redeemed ${reward.title}!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to redeem ${reward.title}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showFullHistory(LoyaltyProgram loyaltyProgram) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoyaltyHistoryScreen(loyaltyProgram: loyaltyProgram),
      ),
    );
  }
}

/// Loyalty history screen
class LoyaltyHistoryScreen extends StatelessWidget {
  final LoyaltyProgram loyaltyProgram;

  const LoyaltyHistoryScreen({
    super.key,
    required this.loyaltyProgram,
  });

  @override
  Widget build(BuildContext context) {
    final allTransactions = loyaltyProgram.getTransactionHistory(limit: 100);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty History'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        itemCount: allTransactions.length,
        itemBuilder: (context, index) {
          final transaction = allTransactions[index];
          final isPositive = transaction.points > 0;
          
          return Card(
            margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppConstants.spacingS),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPositive ? Icons.add : Icons.remove,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
              title: Text(transaction.description),
              subtitle: Text(
                '${transaction.timestamp.day}/${transaction.timestamp.month}/${transaction.timestamp.year}',
              ),
              trailing: Text(
                '${isPositive ? '+' : ''}${transaction.points}',
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Compact loyalty status widget for use in other screens
class LoyaltyStatusWidget extends StatelessWidget {
  const LoyaltyStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LoyaltyProgram>(
      builder: (context, loyaltyProgram, child) {
        return GlassmorphicContainer.card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingS),
                  decoration: BoxDecoration(
                    color: loyaltyProgram.currentTier.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    loyaltyProgram.currentTier.icon,
                    color: loyaltyProgram.currentTier.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loyaltyProgram.currentTier.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${loyaltyProgram.loyaltyPoints} points',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${loyaltyProgram.getDiscountPercentage().toStringAsFixed(0)}% OFF',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: loyaltyProgram.currentTier.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}