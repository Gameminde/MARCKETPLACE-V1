const loggerService = require('./logger.service');

class NotificationService {
  constructor() {
    this.fcm = null;
    this.initializeFirebase();
  }

  /**
   * Initialize Firebase Cloud Messaging
   */
  initializeFirebase() {
    try {
      // Only initialize if Firebase credentials are available
      if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY) {
        const admin = require('firebase-admin');
        
        if (!admin.apps.length) {
          admin.initializeApp({
            credential: admin.credential.cert({
              projectId: process.env.FIREBASE_PROJECT_ID,
              privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
              clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            }),
          });
        }
        
        this.fcm = admin.messaging();
        loggerService.info('Firebase Cloud Messaging initialized successfully');
      } else {
        loggerService.warn('Firebase credentials not found - push notifications disabled');
      }
    } catch (error) {
      loggerService.error('Failed to initialize Firebase:', error);
    }
  }

  /**
   * Send achievement unlock notification
   */
  async sendAchievementNotification(userId, achievement, userToken = null) {
    try {
      if (!this.fcm) {
        loggerService.warn('FCM not initialized - skipping push notification');
        return null;
      }

      // Get user's FCM token if not provided
      if (!userToken) {
        userToken = await this.getUserFCMToken(userId);
        if (!userToken) {
          loggerService.warn(`No FCM token found for user ${userId}`);
          return null;
        }
      }

      const message = {
        token: userToken,
        notification: {
          title: '🏆 Achievement Unlocked!',
          body: `You've earned "${achievement.name}" - ${achievement.description}`,
          imageUrl: this.getAchievementImageUrl(achievement.icon)
        },
        data: {
          type: 'achievement',
          achievementId: achievement.id,
          xpReward: achievement.xpReward.toString(),
          rarity: achievement.rarity
        },
        android: {
          notification: {
            icon: 'achievement_icon',
            color: this.getRarityColor(achievement.rarity),
            sound: 'achievement_sound',
            channelId: 'achievements'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'achievement.wav',
              badge: 1
            }
          }
        }
      };

      const response = await this.fcm.send(message);
      loggerService.info(`Achievement notification sent to user ${userId}: ${response}`);
      
      return response;
    } catch (error) {
      loggerService.error('Error sending achievement notification:', error);
      return null;
    }
  }

  /**
   * Send XP gain notification
   */
  async sendXPNotification(userId, xpGained, source, leveledUp = false, newLevel = null, userToken = null) {
    try {
      if (!this.fcm) {
        return null;
      }

      if (!userToken) {
        userToken = await this.getUserFCMToken(userId);
        if (!userToken) {
          return null;
        }
      }

      let title, body;
      
      if (leveledUp) {
        title = '🎉 Level Up!';
        body = `Congratulations! You've reached level ${newLevel} and earned ${xpGained} XP!`;
      } else {
        title = '⚡ XP Earned!';
        body = `+${xpGained} XP from ${this.getSourceDisplayName(source)}`;
      }

      const message = {
        token: userToken,
        notification: {
          title,
          body
        },
        data: {
          type: leveledUp ? 'level_up' : 'xp_gain',
          xpGained: xpGained.toString(),
          source,
          ...(leveledUp && { newLevel: newLevel.toString() })
        },
        android: {
          notification: {
            icon: leveledUp ? 'level_up_icon' : 'xp_icon',
            color: leveledUp ? '#FFD700' : '#FF6B35',
            sound: leveledUp ? 'level_up_sound' : 'xp_sound',
            channelId: leveledUp ? 'level_ups' : 'xp_gains'
          }
        }
      };

      const response = await this.fcm.send(message);
      loggerService.info(`XP notification sent to user ${userId}: ${response}`);
      
      return response;
    } catch (error) {
      loggerService.error('Error sending XP notification:', error);
      return null;
    }
  }

  /**
   * Send challenge completion notification
   */
  async sendChallengeNotification(userId, challenge, userToken = null) {
    try {
      if (!this.fcm) {
        return null;
      }

      if (!userToken) {
        userToken = await this.getUserFCMToken(userId);
        if (!userToken) {
          return null;
        }
      }

      const message = {
        token: userToken,
        notification: {
          title: '🎯 Challenge Complete!',
          body: `You've completed "${challenge.name}" and earned ${challenge.xpReward} XP!`
        },
        data: {
          type: 'challenge_complete',
          challengeId: challenge.id,
          xpReward: challenge.xpReward.toString()
        },
        android: {
          notification: {
            icon: 'challenge_icon',
            color: '#4ECDC4',
            sound: 'challenge_sound',
            channelId: 'challenges'
          }
        }
      };

      const response = await this.fcm.send(message);
      loggerService.info(`Challenge notification sent to user ${userId}: ${response}`);
      
      return response;
    } catch (error) {
      loggerService.error('Error sending challenge notification:', error);
      return null;
    }
  }

  /**
   * Send leaderboard position notification
   */
  async sendLeaderboardNotification(userId, rank, type, userToken = null) {
    try {
      if (!this.fcm || rank > 10) { // Only notify top 10
        return null;
      }

      if (!userToken) {
        userToken = await this.getUserFCMToken(userId);
        if (!userToken) {
          return null;
        }
      }

      const typeDisplay = type.replace('_', ' ').toUpperCase();
      const rankSuffix = this.getRankSuffix(rank);

      const message = {
        token: userToken,
        notification: {
          title: '🏅 Leaderboard Update!',
          body: `You're now ${rank}${rankSuffix} on the ${typeDisplay} leaderboard!`
        },
        data: {
          type: 'leaderboard_update',
          rank: rank.toString(),
          leaderboardType: type
        },
        android: {
          notification: {
            icon: 'leaderboard_icon',
            color: rank <= 3 ? '#FFD700' : '#C0C0C0',
            sound: 'leaderboard_sound',
            channelId: 'leaderboard'
          }
        }
      };

      const response = await this.fcm.send(message);
      loggerService.info(`Leaderboard notification sent to user ${userId}: ${response}`);
      
      return response;
    } catch (error) {
      loggerService.error('Error sending leaderboard notification:', error);
      return null;
    }
  }

  /**
   * Send daily bonus notification
   */
  async sendDailyBonusNotification(userId, xpAmount, streakDays, userToken = null) {
    try {
      if (!this.fcm) {
        return null;
      }

      if (!userToken) {
        userToken = await this.getUserFCMToken(userId);
        if (!userToken) {
          return null;
        }
      }

      const message = {
        token: userToken,
        notification: {
          title: '🔥 Daily Bonus!',
          body: `${streakDays} day streak! Earned ${xpAmount} XP. Keep it up!`
        },
        data: {
          type: 'daily_bonus',
          xpAmount: xpAmount.toString(),
          streakDays: streakDays.toString()
        },
        android: {
          notification: {
            icon: 'streak_icon',
            color: '#FF6B35',
            sound: 'daily_bonus_sound',
            channelId: 'daily_bonus'
          }
        }
      };

      const response = await this.fcm.send(message);
      loggerService.info(`Daily bonus notification sent to user ${userId}: ${response}`);
      
      return response;
    } catch (error) {
      loggerService.error('Error sending daily bonus notification:', error);
      return null;
    }
  }

  /**
   * Store user's FCM token
   */
  async storeUserFCMToken(userId, token) {
    try {
      // Store in database or cache
      // For now, we'll use a simple in-memory store
      if (!this.userTokens) {
        this.userTokens = new Map();
      }
      
      this.userTokens.set(userId.toString(), token);
      loggerService.info(`FCM token stored for user ${userId}`);
      
      return true;
    } catch (error) {
      loggerService.error('Error storing FCM token:', error);
      return false;
    }
  }

  /**
   * Get user's FCM token
   */
  async getUserFCMToken(userId) {
    try {
      if (!this.userTokens) {
        return null;
      }
      
      return this.userTokens.get(userId.toString()) || null;
    } catch (error) {
      loggerService.error('Error getting FCM token:', error);
      return null;
    }
  }

  /**
   * Remove user's FCM token
   */
  async removeUserFCMToken(userId) {
    try {
      if (this.userTokens) {
        this.userTokens.delete(userId.toString());
      }
      
      loggerService.info(`FCM token removed for user ${userId}`);
      return true;
    } catch (error) {
      loggerService.error('Error removing FCM token:', error);
      return false;
    }
  }

  /**
   * Send bulk notifications
   */
  async sendBulkNotifications(notifications) {
    try {
      if (!this.fcm || !Array.isArray(notifications) || notifications.length === 0) {
        return [];
      }

      const messages = notifications.map(notification => ({
        token: notification.token,
        notification: notification.notification,
        data: notification.data || {},
        android: notification.android || {},
        apns: notification.apns || {}
      }));

      const response = await this.fcm.sendAll(messages);
      loggerService.info(`Bulk notifications sent: ${response.successCount} successful, ${response.failureCount} failed`);
      
      return response;
    } catch (error) {
      loggerService.error('Error sending bulk notifications:', error);
      return null;
    }
  }

  // Helper methods
  getAchievementImageUrl(icon) {
    // Return URL for achievement icon
    return `${process.env.BASE_URL || 'http://localhost:3001'}/public/achievements/${icon}.png`;
  }

  getRarityColor(rarity) {
    const colors = {
      common: '#808080',
      rare: '#4ECDC4',
      epic: '#8B5CF6',
      legendary: '#FFD700'
    };
    return colors[rarity] || colors.common;
  }

  getSourceDisplayName(source) {
    const displayNames = {
      product_view: 'viewing products',
      purchase: 'making a purchase',
      review: 'writing a review',
      share: 'sharing products',
      referral: 'referring friends',
      daily_bonus: 'daily activity',
      streak_bonus: 'maintaining streak',
      achievement: 'unlocking achievement',
      challenge: 'completing challenge'
    };
    return displayNames[source] || source;
  }

  getRankSuffix(rank) {
    if (rank >= 11 && rank <= 13) {
      return 'th';
    }
    switch (rank % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
}

module.exports = new NotificationService();