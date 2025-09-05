const mongoose = require('mongoose');

// Achievement Schema
const achievementSchema = new mongoose.Schema({
  id: {
    type: String,
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  icon: {
    type: String,
    required: true
  },
  category: {
    type: String,
    enum: ['shopping', 'social', 'engagement', 'milestone', 'special'],
    required: true
  },
  xpReward: {
    type: Number,
    required: true,
    min: 0
  },
  rarity: {
    type: String,
    enum: ['common', 'rare', 'epic', 'legendary'],
    default: 'common'
  },
  requirements: {
    type: mongoose.Schema.Types.Mixed,
    required: true
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// User XP Schema
const userXPSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  totalXP: {
    type: Number,
    default: 0,
    min: 0
  },
  currentLevel: {
    type: Number,
    default: 1,
    min: 1
  },
  xpToNextLevel: {
    type: Number,
    default: 100
  },
  unlockedAchievements: [{
    achievementId: {
      type: String,
      required: true
    },
    unlockedAt: {
      type: Date,
      default: Date.now
    },
    xpEarned: {
      type: Number,
      required: true
    }
  }],
  dailyXP: {
    type: Number,
    default: 0
  },
  weeklyXP: {
    type: Number,
    default: 0
  },
  monthlyXP: {
    type: Number,
    default: 0
  },
  lastDailyReset: {
    type: Date,
    default: Date.now
  },
  lastWeeklyReset: {
    type: Date,
    default: Date.now
  },
  lastMonthlyReset: {
    type: Date,
    default: Date.now
  },
  streak: {
    current: {
      type: Number,
      default: 0
    },
    longest: {
      type: Number,
      default: 0
    },
    lastActivity: {
      type: Date,
      default: Date.now
    }
  },
  badges: [{
    badgeId: {
      type: String,
      required: true
    },
    earnedAt: {
      type: Date,
      default: Date.now
    },
    level: {
      type: Number,
      default: 1
    }
  }],
  stats: {
    productsViewed: {
      type: Number,
      default: 0
    },
    productsPurchased: {
      type: Number,
      default: 0
    },
    reviewsWritten: {
      type: Number,
      default: 0
    },
    socialShares: {
      type: Number,
      default: 0
    },
    friendsReferred: {
      type: Number,
      default: 0
    },
    challengesCompleted: {
      type: Number,
      default: 0
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// XP Transaction Schema (for tracking XP gains/losses)
const xpTransactionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  type: {
    type: String,
    enum: ['gain', 'loss', 'bonus', 'penalty'],
    required: true
  },
  amount: {
    type: Number,
    required: true
  },
  source: {
    type: String,
    enum: ['product_view', 'purchase', 'review', 'share', 'referral', 'achievement', 'daily_bonus', 'streak_bonus', 'challenge', 'admin'],
    required: true
  },
  sourceId: {
    type: String // ID of the related entity (product, review, etc.)
  },
  description: {
    type: String,
    required: true
  },
  metadata: {
    type: mongoose.Schema.Types.Mixed
  }
}, {
  timestamps: true
});

// Challenge Schema
const challengeSchema = new mongoose.Schema({
  id: {
    type: String,
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  type: {
    type: String,
    enum: ['daily', 'weekly', 'monthly', 'special'],
    required: true
  },
  requirements: {
    type: mongoose.Schema.Types.Mixed,
    required: true
  },
  xpReward: {
    type: Number,
    required: true,
    min: 0
  },
  startDate: {
    type: Date,
    required: true
  },
  endDate: {
    type: Date,
    required: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  participants: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    progress: {
      type: Number,
      default: 0
    },
    completed: {
      type: Boolean,
      default: false
    },
    completedAt: Date
  }]
}, {
  timestamps: true
});

// Leaderboard Schema
const leaderboardSchema = new mongoose.Schema({
  type: {
    type: String,
    enum: ['daily', 'weekly', 'monthly', 'all_time'],
    required: true
  },
  period: {
    type: String,
    required: true // Format: YYYY-MM-DD for daily, YYYY-WW for weekly, YYYY-MM for monthly, 'all' for all-time
  },
  rankings: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    rank: {
      type: Number,
      required: true
    },
    xp: {
      type: Number,
      required: true
    },
    level: {
      type: Number,
      required: true
    }
  }],
  lastUpdated: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Indexes for performance
userXPSchema.index({ userId: 1 });
userXPSchema.index({ totalXP: -1 });
userXPSchema.index({ currentLevel: -1 });
userXPSchema.index({ 'streak.current': -1 });

xpTransactionSchema.index({ userId: 1, createdAt: -1 });
xpTransactionSchema.index({ source: 1 });
xpTransactionSchema.index({ type: 1 });

challengeSchema.index({ type: 1, isActive: 1 });
challengeSchema.index({ startDate: 1, endDate: 1 });

leaderboardSchema.index({ type: 1, period: 1 });
leaderboardSchema.index({ 'rankings.rank': 1 });

// Virtual methods for UserXP
userXPSchema.virtual('levelProgress').get(function() {
  const currentLevelXP = this.calculateXPForLevel(this.currentLevel);
  const nextLevelXP = this.calculateXPForLevel(this.currentLevel + 1);
  const progressXP = this.totalXP - currentLevelXP;
  const requiredXP = nextLevelXP - currentLevelXP;
  
  return {
    current: progressXP,
    required: requiredXP,
    percentage: Math.round((progressXP / requiredXP) * 100)
  };
});

// Methods for UserXP
userXPSchema.methods.calculateXPForLevel = function(level) {
  // Exponential XP curve: XP = 100 * (level - 1)^1.5
  return Math.floor(100 * Math.pow(level - 1, 1.5));
};

userXPSchema.methods.calculateLevelFromXP = function(xp) {
  let level = 1;
  while (this.calculateXPForLevel(level + 1) <= xp) {
    level++;
  }
  return level;
};

userXPSchema.methods.addXP = function(amount, source, sourceId = null, description = '') {
  this.totalXP += amount;
  this.dailyXP += amount;
  this.weeklyXP += amount;
  this.monthlyXP += amount;
  
  const newLevel = this.calculateLevelFromXP(this.totalXP);
  const leveledUp = newLevel > this.currentLevel;
  
  this.currentLevel = newLevel;
  this.xpToNextLevel = this.calculateXPForLevel(newLevel + 1) - this.totalXP;
  
  // Update streak
  const now = new Date();
  const lastActivity = new Date(this.streak.lastActivity);
  const daysDiff = Math.floor((now - lastActivity) / (1000 * 60 * 60 * 24));
  
  if (daysDiff === 1) {
    this.streak.current += 1;
    if (this.streak.current > this.streak.longest) {
      this.streak.longest = this.streak.current;
    }
  } else if (daysDiff > 1) {
    this.streak.current = 1;
  }
  
  this.streak.lastActivity = now;
  
  return {
    leveledUp,
    newLevel,
    xpGained: amount,
    totalXP: this.totalXP
  };
};

userXPSchema.methods.unlockAchievement = function(achievementId, xpReward) {
  const existingAchievement = this.unlockedAchievements.find(
    a => a.achievementId === achievementId
  );
  
  if (!existingAchievement) {
    this.unlockedAchievements.push({
      achievementId,
      unlockedAt: new Date(),
      xpEarned: xpReward
    });
    
    return this.addXP(xpReward, 'achievement', achievementId, `Achievement unlocked: ${achievementId}`);
  }
  
  return null;
};

userXPSchema.methods.resetDailyStats = function() {
  const now = new Date();
  const lastReset = new Date(this.lastDailyReset);
  
  if (now.getDate() !== lastReset.getDate() || 
      now.getMonth() !== lastReset.getMonth() || 
      now.getFullYear() !== lastReset.getFullYear()) {
    this.dailyXP = 0;
    this.lastDailyReset = now;
  }
};

userXPSchema.methods.resetWeeklyStats = function() {
  const now = new Date();
  const lastReset = new Date(this.lastWeeklyReset);
  const weeksDiff = Math.floor((now - lastReset) / (1000 * 60 * 60 * 24 * 7));
  
  if (weeksDiff >= 1) {
    this.weeklyXP = 0;
    this.lastWeeklyReset = now;
  }
};

userXPSchema.methods.resetMonthlyStats = function() {
  const now = new Date();
  const lastReset = new Date(this.lastMonthlyReset);
  
  if (now.getMonth() !== lastReset.getMonth() || 
      now.getFullYear() !== lastReset.getFullYear()) {
    this.monthlyXP = 0;
    this.lastMonthlyReset = now;
  }
};

// Create models
const Achievement = mongoose.model('Achievement', achievementSchema);
const UserXP = mongoose.model('UserXP', userXPSchema);
const XPTransaction = mongoose.model('XPTransaction', xpTransactionSchema);
const Challenge = mongoose.model('Challenge', challengeSchema);
const Leaderboard = mongoose.model('Leaderboard', leaderboardSchema);

module.exports = {
  Achievement,
  UserXP,
  XPTransaction,
  Challenge,
  Leaderboard
};