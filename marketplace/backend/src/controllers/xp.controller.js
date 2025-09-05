const BaseController = require('./BaseController');
const xpService = require('../services/xp.service');
const Joi = require('joi');

class XPController extends BaseController {
  constructor() {
    super('XP');
    
    // Validation schemas
    this.schemas = {
      trackActivity: Joi.object({
        activityType: Joi.string().valid(
          'product_view', 'purchase', 'review', 'share', 'referral'
        ).required(),
        sourceId: Joi.string().optional(),
        description: Joi.string().max(200).optional(),
        metadata: Joi.object().optional()
      }),
      
      awardXP: Joi.object({
        amount: Joi.number().integer().min(1).max(10000).required(),
        source: Joi.string().required(),
        sourceId: Joi.string().optional(),
        description: Joi.string().max(200).required()
      }),
      
      getLeaderboard: Joi.object({
        type: Joi.string().valid('daily', 'weekly', 'monthly', 'all_time').default('all_time'),
        limit: Joi.number().integer().min(1).max(100).default(50)
      })
    };
  }

  /**
   * Get user's XP data
   * GET /api/v1/xp/user
   */
  async getUserXP(req, res, next) {
    try {
      const userId = req.user.id;
      const userXP = await xpService.getUserXP(userId);
      
      this.sendSuccess(res, {
        data: userXP,
        message: 'User XP data retrieved successfully'
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  /**
   * Track user activity and award XP
   * POST /api/v1/xp/track
   */
  async trackActivity(req, res, next) {
    try {
      const { error, value } = this.schemas.trackActivity.validate(req.body);
      if (error) {
        return this.sendError(res, 'Validation failed', 400, error.details);
      }

      const userId = req.user.id;
      const { activityType, sourceId, description, metadata } = value;
      
      const result = await xpService.trackActivity(userId, activityType, {
        sourceId,
        description,
        ...metadata
      });

      if (!result) {
        return this.sendError(res, 'Invalid activity type or no XP awarded', 400);
      }

      this.sendSuccess(res, {
        data: result,
        message: `Activity tracked successfully. ${result.xpGained} XP awarded!`
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  /**
   * Award XP to user (admin only)
   * POST /api/v1/xp/award
   */
  async awardXP(req, res, next) {
    try {
      const { error, value } = this.schemas.awardXP.validate(req.body);
      if (error) {
        return this.sendError(res, 'Validation failed', 400, error.details);
      }

      const userId = req.params.userId || req.user.id;
      const { amount, source, sourceId, description } = value;
      
      const result = await xpService.awardXP(userId, amount, source, sourceId, description);

      this.sendSuccess(res, {
        data: result,
        message: `${amount} XP awarded successfully!`
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  /**
   * Get all achievements
   * GET /api/v1/xp/achievements
   */
  async getAchievements(req, res, next) {
    try {
      const achievements = await xpService.getAchievements();
      
      this.sendSuccess(res, {
        data: achievements,
        message: 'Achievements retrieved successfully'
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  /**
   * Get user's achievements
   * GET /api/v1/xp/user/achievements
   */
  async getUserAchievements(req, res, next) {
    try {
      const userId = req.user.id;
      const achievements = await xpService.getUserAchievements(userId);
      
      this.sendSuccess(res, {
        data: achievements,
        message: 'User achievements retrieved successfully'
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  /**
   * Get leaderboard
   * GET /api/v1/xp/leaderboard
   */
  async getLeaderboard(req, res, next) {
    try {
      const { error, value } = this.schemas.getLeaderboard.validate(req.query);
      if (error) {
        return this.sendError(res, 'Validation failed', 400, error.details);
      }

      const { type, limit } = value;
      const leaderboard = await xpService.getLeaderboard(type, limit);
      
      // Get user's rank if authenticated
      let userRank = null;
      if (req.user) {
        userRank = await xpService.getUserRank(req.user.id, type);
      }

      this.sendSuccess(res, {
        data: {
          ...leaderboard,
          userRank
        },
        message: 'Leaderboard retrieved successfully'
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  /**
   * Get user's challenges
   * GET /api/v1/xp/user/challenges
   */
  async getUserChallenges(req, res, next) {
    try {
      const userId = req.user.id;
      const challenges = await xpService.getUserChallenges(userId);
      
      this.sendSuccess(res, {
        data: challenges,
        message: 'User challenges retrieved successfully'
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  /**
   * Get user's rank in leaderboard
   * GET /api/v1/xp/user/rank
   */
  async getUserRank(req, res, next) {
    try {
      const userId = req.user.id;
      const type = req.query.type || 'all_time';
      
      const rank = await xpService.getUserRank(userId, type);
      
      this.sendSuccess(res, {
        data: { rank, type },
        message: 'User rank retrieved successfully'
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  /**
   * Get XP statistics (admin only)
   * GET /api/v1/xp/stats
   */
  async getXPStats(req, res, next) {
    try {
      const stats = await xpService.getXPStats();
      
      this.sendSuccess(res, {
        data: stats,
        message: 'XP statistics retrieved successfully'
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  /**
   * Initialize user XP (for new users)
   * POST /api/v1/xp/initialize
   */
  async initializeUserXP(req, res, next) {
    try {
      const userId = req.user.id;
      const userXP = await xpService.initializeUserXP(userId);
      
      this.sendSuccess(res, {
        data: userXP,
        message: 'XP system initialized successfully'
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  /**
   * Bulk track activities (for batch operations)
   * POST /api/v1/xp/track/bulk
   */
  async trackBulkActivities(req, res, next) {
    try {
      const userId = req.user.id;
      const { activities } = req.body;

      if (!Array.isArray(activities) || activities.length === 0) {
        return this.sendError(res, 'Activities array is required', 400);
      }

      if (activities.length > 50) {
        return this.sendError(res, 'Maximum 50 activities per batch', 400);
      }

      const results = [];
      let totalXPGained = 0;

      for (const activity of activities) {
        const { error, value } = this.schemas.trackActivity.validate(activity);
        if (error) {
          continue; // Skip invalid activities
        }

        const result = await xpService.trackActivity(userId, value.activityType, {
          sourceId: value.sourceId,
          description: value.description,
          ...value.metadata
        });

        if (result) {
          results.push(result);
          totalXPGained += result.xpGained;
        }
      }

      this.sendSuccess(res, {
        data: {
          results,
          totalXPGained,
          activitiesProcessed: results.length
        },
        message: `Bulk activities tracked. ${totalXPGained} total XP awarded!`
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  /**
   * Get XP history/transactions for user
   * GET /api/v1/xp/user/history
   */
  async getUserXPHistory(req, res, next) {
    try {
      const userId = req.user.id;
      const page = parseInt(req.query.page) || 1;
      const limit = Math.min(parseInt(req.query.limit) || 20, 100);
      const skip = (page - 1) * limit;

      const { XPTransaction } = require('../models/XPSystem');
      
      const transactions = await XPTransaction.find({ userId })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit);

      const total = await XPTransaction.countDocuments({ userId });

      this.sendSuccess(res, {
        data: {
          transactions,
          pagination: {
            page,
            limit,
            total,
            pages: Math.ceil(total / limit)
          }
        },
        message: 'XP history retrieved successfully'
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }

  /**
   * Get level information
   * GET /api/v1/xp/levels
   */
  async getLevelInfo(req, res, next) {
    try {
      const levels = [];
      for (let level = 1; level <= 100; level++) {
        const xpRequired = Math.floor(100 * Math.pow(level - 1, 1.5));
        levels.push({
          level,
          xpRequired,
          xpToNext: level < 100 ? Math.floor(100 * Math.pow(level, 1.5)) - xpRequired : 0
        });
      }

      this.sendSuccess(res, {
        data: { levels },
        message: 'Level information retrieved successfully'
      });
    } catch (error) {
      this.handleError(error, req, res, next);
    }
  }
}

module.exports = new XPController();