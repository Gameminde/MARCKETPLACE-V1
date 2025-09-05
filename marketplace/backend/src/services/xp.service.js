const { UserXP, XPTransaction, Achievement, Challenge, Leaderboard } = require('../models/XPSystem');
const { UserMongo } = require('../models/User');
const loggerService = require('./logger.service');
const notificationService = require('./notification.service');

class XPService {
  constructor() {
    this.xpRates = {
      product_view: 2,
      purchase: 50,
      review: 25,
      share: 10,
      referral: 100,
      daily_bonus: 20,
      streak_bonus: 5 // per day of streak
    };

    this.achievements = [
      {
        id: 'first_purchase',
        name: 'First Purchase',
        description: 'Make your first purchase',
        icon: '🛍️',
        category: 'shopping',
        xpReward: 100,
        rarity: 'common',
        requirements: { purchases: 1 }
      },
      {
        id: 'shopaholic',
        name: 'Shopaholic',
        description: 'Make 10 purchases',
        icon: '🛒',
        category: 'shopping',
        xpReward: 500,
        rarity: 'rare',
        requirements: { purchases: 10 }
      },
      {
        id: 'big_spender',
        name: 'Big Spender',
        description: 'Spend over $500',
        icon: '💰',
        category: 'shopping',
        xpReward: 750,
        rarity: 'epic',
        requirements: { totalSpent: 500 }
      },
      {
        id: 'reviewer',
        name: 'Reviewer',
        description: 'Write 5 reviews',
        icon: '⭐',
        category: 'engagement',
        xpReward: 200,
        rarity: 'common',
        requirements: { reviews: 5 }
      },
      {
        id: 'social_butterfly',
        name: 'Social Butterfly',
        description: 'Share 10 products',
        icon: '🦋',
        category: 'social',
        xpReward: 300,
        rarity: 'rare',
        requirements: { shares: 10 }
      },
      {
        id: 'streak_master',
        name: 'Streak Master',
        description: 'Maintain a 7-day streak',
        icon: '🔥',
        category: 'engagement',
        xpReward: 400,
        rarity: 'epic',
        requirements: { streak: 7 }
      },
      {
        id: 'explorer',
        name: 'Explorer',
        description: 'View 100 products',
        icon: '🔍',
        category: 'engagement',
        xpReward: 150,
        rarity: 'common',
        requirements: { productViews: 100 }
      },
      {
        id: 'legend',
        name: 'Legend',
        description: 'Reach level 50',
        icon: '👑',
        category: 'milestone',
        xpReward: 2000,
        rarity: 'legendary',
        requirements: { level: 50 }
      }
    ];
  }

  /**
   * Initialize XP system for a new user
   */
  async initializeUserXP(userId) {
    try {
      const existingUserXP = await UserXP.findOne({ userId });
      if (existingUserXP) {
        return existingUserXP;
      }

      const userXP = new UserXP({
        userId,
        totalXP: 0,
        currentLevel: 1,
        xpToNextLevel: 100
      });

      await userXP.save();
      
      // Award welcome bonus
      await this.awardXP(userId, 50, 'daily_bonus', null, 'Welcome bonus!');
      
      loggerService.info(`XP system initialized for user ${userId}`);
      return userXP;
    } catch (error) {
      loggerService.error('Error initializing user XP:', error);
      throw error;
    }
  }

  /**
   * Award XP to a user
   */
  async awardXP(userId, amount, source, sourceId = null, description = '') {
    try {
      let userXP = await UserXP.findOne({ userId });
      if (!userXP) {
        userXP = await this.initializeUserXP(userId);
      }

      // Reset daily/weekly/monthly stats if needed
      userXP.resetDailyStats();
      userXP.resetWeeklyStats();
      userXP.resetMonthlyStats();

      const result = userXP.addXP(amount, source, sourceId, description);
      await userXP.save();

      // Create transaction record
      const transaction = new XPTransaction({
        userId,
        type: 'gain',
        amount,
        source,
        sourceId,
        description
      });
      await transaction.save();

      // Send XP notification
      if (result.leveledUp) {
        await notificationService.sendXPNotification(
          userId, 
          amount, 
          source, 
          true, 
          result.newLevel
        );
      } else if (amount >= 10) { // Only notify for significant XP gains
        await notificationService.sendXPNotification(
          userId, 
          amount, 
          source, 
          false
        );
      }

      // Check for achievements
      const newAchievements = await this.checkAchievements(userId);

      // Send achievement notifications
      for (const achievement of newAchievements) {
        await notificationService.sendAchievementNotification(userId, achievement);
      }

      // Update leaderboards
      await this.updateLeaderboards(userId);

      loggerService.info(`Awarded ${amount} XP to user ${userId} for ${source}`);

      return {
        ...result,
        newAchievements,
        userXP: await this.getUserXP(userId)
      };
    } catch (error) {
      loggerService.error('Error awarding XP:', error);
      throw error;
    }
  }

  /**
   * Get user XP data
   */
  async getUserXP(userId) {
    try {
      let userXP = await UserXP.findOne({ userId }).populate('userId', 'firstName lastName email');
      if (!userXP) {
        userXP = await this.initializeUserXP(userId);
      }

      return {
        userId: userXP.userId,
        totalXP: userXP.totalXP,
        currentLevel: userXP.currentLevel,
        xpToNextLevel: userXP.xpToNextLevel,
        levelProgress: userXP.levelProgress,
        dailyXP: userXP.dailyXP,
        weeklyXP: userXP.weeklyXP,
        monthlyXP: userXP.monthlyXP,
        streak: userXP.streak,
        unlockedAchievements: userXP.unlockedAchievements,
        badges: userXP.badges,
        stats: userXP.stats
      };
    } catch (error) {
      loggerService.error('Error getting user XP:', error);
      throw error;
    }
  }

  /**
   * Track user activity and award XP
   */
  async trackActivity(userId, activityType, metadata = {}) {
    try {
      const xpAmount = this.xpRates[activityType] || 0;
      if (xpAmount === 0) {
        return null;
      }

      let userXP = await UserXP.findOne({ userId });
      if (!userXP) {
        userXP = await this.initializeUserXP(userId);
      }

      // Update stats
      switch (activityType) {
        case 'product_view':
          userXP.stats.productsViewed += 1;
          break;
        case 'purchase':
          userXP.stats.productsPurchased += 1;
          break;
        case 'review':
          userXP.stats.reviewsWritten += 1;
          break;
        case 'share':
          userXP.stats.socialShares += 1;
          break;
        case 'referral':
          userXP.stats.friendsReferred += 1;
          break;
      }

      await userXP.save();

      // Award XP
      const result = await this.awardXP(
        userId, 
        xpAmount, 
        activityType, 
        metadata.sourceId, 
        metadata.description || `${activityType} activity`
      );

      return result;
    } catch (error) {
      loggerService.error('Error tracking activity:', error);
      throw error;
    }
  }

  /**
   * Check and unlock achievements
   */
  async checkAchievements(userId) {
    try {
      const userXP = await UserXP.findOne({ userId });
      if (!userXP) return [];

      const user = await UserMongo.findById(userId);
      if (!user) return [];

      const newAchievements = [];

      for (const achievement of this.achievements) {
        // Skip if already unlocked
        const alreadyUnlocked = userXP.unlockedAchievements.some(
          a => a.achievementId === achievement.id
        );
        if (alreadyUnlocked) continue;

        // Check requirements
        let requirementMet = false;
        const req = achievement.requirements;

        if (req.purchases && userXP.stats.productsPurchased >= req.purchases) {
          requirementMet = true;
        } else if (req.totalSpent && user.stats.totalSpent >= req.totalSpent) {
          requirementMet = true;
        } else if (req.reviews && userXP.stats.reviewsWritten >= req.reviews) {
          requirementMet = true;
        } else if (req.shares && userXP.stats.socialShares >= req.shares) {
          requirementMet = true;
        } else if (req.streak && userXP.streak.current >= req.streak) {
          requirementMet = true;
        } else if (req.productViews && userXP.stats.productsViewed >= req.productViews) {
          requirementMet = true;
        } else if (req.level && userXP.currentLevel >= req.level) {
          requirementMet = true;
        }

        if (requirementMet) {
          const unlockResult = userXP.unlockAchievement(achievement.id, achievement.xpReward);
          if (unlockResult) {
            newAchievements.push({
              ...achievement,
              unlockedAt: new Date(),
              xpEarned: achievement.xpReward
            });
          }
        }
      }

      if (newAchievements.length > 0) {
        await userXP.save();
        loggerService.info(`User ${userId} unlocked ${newAchievements.length} achievements`);
      }

      return newAchievements;
    } catch (error) {
      loggerService.error('Error checking achievements:', error);
      throw error;
    }
  }

  /**
   * Get all available achievements
   */
  async getAchievements() {
    return this.achievements;
  }

  /**
   * Get user's achievement progress
   */
  async getUserAchievements(userId) {
    try {
      const userXP = await UserXP.findOne({ userId });
      if (!userXP) {
        await this.initializeUserXP(userId);
        return { unlocked: [], available: this.achievements };
      }

      const unlocked = userXP.unlockedAchievements.map(ua => {
        const achievement = this.achievements.find(a => a.id === ua.achievementId);
        return {
          ...achievement,
          unlockedAt: ua.unlockedAt,
          xpEarned: ua.xpEarned
        };
      });

      const available = this.achievements.filter(a => 
        !userXP.unlockedAchievements.some(ua => ua.achievementId === a.id)
      );

      return { unlocked, available };
    } catch (error) {
      loggerService.error('Error getting user achievements:', error);
      throw error;
    }
  }

  /**
   * Update leaderboards
   */
  async updateLeaderboards(userId) {
    try {
      const userXP = await UserXP.findOne({ userId });
      if (!userXP) return;

      const now = new Date();
      const periods = {
        daily: now.toISOString().split('T')[0], // YYYY-MM-DD
        weekly: `${now.getFullYear()}-W${Math.ceil(now.getDate() / 7)}`,
        monthly: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`,
        all_time: 'all'
      };

      for (const [type, period] of Object.entries(periods)) {
        let leaderboard = await Leaderboard.findOne({ type, period });
        
        if (!leaderboard) {
          leaderboard = new Leaderboard({ type, period, rankings: [] });
        }

        // Remove existing entry for this user
        leaderboard.rankings = leaderboard.rankings.filter(r => 
          r.userId.toString() !== userId.toString()
        );

        // Add updated entry
        const xpValue = type === 'daily' ? userXP.dailyXP :
                       type === 'weekly' ? userXP.weeklyXP :
                       type === 'monthly' ? userXP.monthlyXP :
                       userXP.totalXP;

        leaderboard.rankings.push({
          userId,
          rank: 0, // Will be calculated below
          xp: xpValue,
          level: userXP.currentLevel
        });

        // Sort and assign ranks
        leaderboard.rankings.sort((a, b) => b.xp - a.xp);
        leaderboard.rankings.forEach((ranking, index) => {
          ranking.rank = index + 1;
        });

        // Keep only top 100
        leaderboard.rankings = leaderboard.rankings.slice(0, 100);
        leaderboard.lastUpdated = now;

        await leaderboard.save();
      }
    } catch (error) {
      loggerService.error('Error updating leaderboards:', error);
      // Don't throw - leaderboard updates shouldn't break main flow
    }
  }

  /**
   * Get leaderboard
   */
  async getLeaderboard(type = 'all_time', limit = 50) {
    try {
      const now = new Date();
      let period;

      switch (type) {
        case 'daily':
          period = now.toISOString().split('T')[0];
          break;
        case 'weekly':
          period = `${now.getFullYear()}-W${Math.ceil(now.getDate() / 7)}`;
          break;
        case 'monthly':
          period = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
          break;
        default:
          period = 'all';
      }

      const leaderboard = await Leaderboard.findOne({ type, period })
        .populate('rankings.userId', 'firstName lastName email profile.avatar');

      if (!leaderboard) {
        return { rankings: [], lastUpdated: null };
      }

      return {
        rankings: leaderboard.rankings.slice(0, limit),
        lastUpdated: leaderboard.lastUpdated
      };
    } catch (error) {
      loggerService.error('Error getting leaderboard:', error);
      throw error;
    }
  }

  /**
   * Get user's rank in leaderboard
   */
  async getUserRank(userId, type = 'all_time') {
    try {
      const leaderboard = await this.getLeaderboard(type, 1000);
      const userRanking = leaderboard.rankings.find(r => 
        r.userId._id.toString() === userId.toString()
      );

      return userRanking ? userRanking.rank : null;
    } catch (error) {
      loggerService.error('Error getting user rank:', error);
      throw error;
    }
  }

  /**
   * Create daily challenges
   */
  async createDailyChallenge() {
    try {
      const today = new Date();
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const challenges = [
        {
          id: `daily_views_${today.toISOString().split('T')[0]}`,
          name: 'Product Explorer',
          description: 'View 10 products today',
          type: 'daily',
          requirements: { productViews: 10 },
          xpReward: 100,
          startDate: today,
          endDate: tomorrow
        },
        {
          id: `daily_purchase_${today.toISOString().split('T')[0]}`,
          name: 'Shopping Spree',
          description: 'Make a purchase today',
          type: 'daily',
          requirements: { purchases: 1 },
          xpReward: 200,
          startDate: today,
          endDate: tomorrow
        },
        {
          id: `daily_review_${today.toISOString().split('T')[0]}`,
          name: 'Helpful Reviewer',
          description: 'Write a review today',
          type: 'daily',
          requirements: { reviews: 1 },
          xpReward: 150,
          startDate: today,
          endDate: tomorrow
        }
      ];

      for (const challengeData of challenges) {
        const existingChallenge = await Challenge.findOne({ id: challengeData.id });
        if (!existingChallenge) {
          const challenge = new Challenge(challengeData);
          await challenge.save();
          loggerService.info(`Created daily challenge: ${challengeData.name}`);
        }
      }
    } catch (error) {
      loggerService.error('Error creating daily challenges:', error);
    }
  }

  /**
   * Get active challenges for user
   */
  async getUserChallenges(userId) {
    try {
      const now = new Date();
      const challenges = await Challenge.find({
        isActive: true,
        startDate: { $lte: now },
        endDate: { $gte: now }
      });

      const userXP = await UserXP.findOne({ userId });
      
      return challenges.map(challenge => {
        const participant = challenge.participants.find(p => 
          p.userId.toString() === userId.toString()
        );

        return {
          id: challenge.id,
          name: challenge.name,
          description: challenge.description,
          type: challenge.type,
          requirements: challenge.requirements,
          xpReward: challenge.xpReward,
          startDate: challenge.startDate,
          endDate: challenge.endDate,
          progress: participant ? participant.progress : 0,
          completed: participant ? participant.completed : false,
          completedAt: participant ? participant.completedAt : null
        };
      });
    } catch (error) {
      loggerService.error('Error getting user challenges:', error);
      throw error;
    }
  }

  /**
   * Initialize achievements in database
   */
  async initializeAchievements() {
    try {
      for (const achievementData of this.achievements) {
        const existingAchievement = await Achievement.findOne({ id: achievementData.id });
        if (!existingAchievement) {
          const achievement = new Achievement(achievementData);
          await achievement.save();
          loggerService.info(`Created achievement: ${achievementData.name}`);
        }
      }
    } catch (error) {
      loggerService.error('Error initializing achievements:', error);
    }
  }

  /**
   * Get XP statistics
   */
  async getXPStats() {
    try {
      const totalUsers = await UserXP.countDocuments();
      const totalXPAwarded = await UserXP.aggregate([
        { $group: { _id: null, total: { $sum: '$totalXP' } } }
      ]);
      
      const levelDistribution = await UserXP.aggregate([
        { $group: { _id: '$currentLevel', count: { $sum: 1 } } },
        { $sort: { _id: 1 } }
      ]);

      const topUsers = await UserXP.find()
        .populate('userId', 'firstName lastName')
        .sort({ totalXP: -1 })
        .limit(10);

      return {
        totalUsers,
        totalXPAwarded: totalXPAwarded[0]?.total || 0,
        levelDistribution,
        topUsers: topUsers.map(user => ({
          user: user.userId,
          totalXP: user.totalXP,
          level: user.currentLevel
        }))
      };
    } catch (error) {
      loggerService.error('Error getting XP stats:', error);
      throw error;
    }
  }
}

module.exports = new XPService();