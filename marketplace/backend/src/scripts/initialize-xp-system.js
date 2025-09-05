const mongoose = require('mongoose');
const xpService = require('../services/xp.service');
const loggerService = require('../services/logger.service');

/**
 * Initialize XP System
 * This script sets up the gamification system with achievements and daily challenges
 */
async function initializeXPSystem() {
  try {
    console.log('🎮 Initializing XP System...');
    
    // Initialize achievements in database
    await xpService.initializeAchievements();
    console.log('✅ Achievements initialized');
    
    // Create daily challenges
    await xpService.createDailyChallenge();
    console.log('✅ Daily challenges created');
    
    // Log system status
    const stats = await xpService.getXPStats();
    console.log('📊 XP System Statistics:');
    console.log(`   - Total Users: ${stats.totalUsers}`);
    console.log(`   - Total XP Awarded: ${stats.totalXPAwarded}`);
    console.log(`   - Level Distribution: ${JSON.stringify(stats.levelDistribution)}`);
    
    console.log('🎉 XP System initialization complete!');
    
    return true;
  } catch (error) {
    console.error('❌ Error initializing XP system:', error);
    loggerService.error('XP System initialization failed:', error);
    return false;
  }
}

/**
 * Schedule daily challenge creation
 * This should be called daily to create new challenges
 */
async function scheduleDailyChallenges() {
  try {
    console.log('📅 Creating daily challenges...');
    await xpService.createDailyChallenge();
    console.log('✅ Daily challenges created successfully');
    return true;
  } catch (error) {
    console.error('❌ Error creating daily challenges:', error);
    loggerService.error('Daily challenge creation failed:', error);
    return false;
  }
}

/**
 * Migrate existing users to XP system
 * This initializes XP for all existing users
 */
async function migrateExistingUsers() {
  try {
    console.log('👥 Migrating existing users to XP system...');
    
    const { UserMongo } = require('../models/User');
    const users = await UserMongo.find({});
    
    let migratedCount = 0;
    
    for (const user of users) {
      try {
        await xpService.initializeUserXP(user._id);
        migratedCount++;
        
        if (migratedCount % 10 === 0) {
          console.log(`   Migrated ${migratedCount}/${users.length} users...`);
        }
      } catch (error) {
        console.warn(`   Warning: Failed to migrate user ${user._id}:`, error.message);
      }
    }
    
    console.log(`✅ Successfully migrated ${migratedCount}/${users.length} users`);
    return true;
  } catch (error) {
    console.error('❌ Error migrating existing users:', error);
    loggerService.error('User migration failed:', error);
    return false;
  }
}

/**
 * Clean up expired challenges and leaderboards
 */
async function cleanupExpiredData() {
  try {
    console.log('🧹 Cleaning up expired data...');
    
    const { Challenge, Leaderboard } = require('../models/XPSystem');
    const now = new Date();
    
    // Remove expired challenges
    const expiredChallenges = await Challenge.deleteMany({
      endDate: { $lt: now },
      type: 'daily' // Only clean up daily challenges
    });
    
    // Remove old daily leaderboards (keep last 30 days)
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const oldLeaderboards = await Leaderboard.deleteMany({
      type: 'daily',
      lastUpdated: { $lt: thirtyDaysAgo }
    });
    
    console.log(`✅ Cleanup complete:`);
    console.log(`   - Removed ${expiredChallenges.deletedCount} expired challenges`);
    console.log(`   - Removed ${oldLeaderboards.deletedCount} old leaderboards`);
    
    return true;
  } catch (error) {
    console.error('❌ Error during cleanup:', error);
    loggerService.error('Data cleanup failed:', error);
    return false;
  }
}

/**
 * Generate test data for development
 */
async function generateTestData() {
  try {
    if (process.env.NODE_ENV === 'production') {
      console.log('⚠️  Skipping test data generation in production');
      return false;
    }
    
    console.log('🧪 Generating test XP data...');
    
    const { UserMongo } = require('../models/User');
    const users = await UserMongo.find({}).limit(5);
    
    if (users.length === 0) {
      console.log('   No users found for test data generation');
      return false;
    }
    
    for (const user of users) {
      // Simulate various activities
      const activities = [
        { type: 'product_view', count: Math.floor(Math.random() * 20) + 5 },
        { type: 'purchase', count: Math.floor(Math.random() * 3) + 1 },
        { type: 'review', count: Math.floor(Math.random() * 2) + 1 },
        { type: 'share', count: Math.floor(Math.random() * 5) + 1 }
      ];
      
      for (const activity of activities) {
        for (let i = 0; i < activity.count; i++) {
          await xpService.trackActivity(user._id, activity.type, {
            sourceId: `test_${Date.now()}_${i}`,
            description: `Test ${activity.type} activity`
          });
        }
      }
    }
    
    console.log(`✅ Generated test data for ${users.length} users`);
    return true;
  } catch (error) {
    console.error('❌ Error generating test data:', error);
    loggerService.error('Test data generation failed:', error);
    return false;
  }
}

// CLI interface
if (require.main === module) {
  const command = process.argv[2];
  
  const commands = {
    'init': initializeXPSystem,
    'daily': scheduleDailyChallenges,
    'migrate': migrateExistingUsers,
    'cleanup': cleanupExpiredData,
    'test-data': generateTestData
  };
  
  if (!command || !commands[command]) {
    console.log('🎮 XP System Management Script');
    console.log('');
    console.log('Available commands:');
    console.log('  init      - Initialize XP system with achievements and challenges');
    console.log('  daily     - Create daily challenges');
    console.log('  migrate   - Migrate existing users to XP system');
    console.log('  cleanup   - Clean up expired data');
    console.log('  test-data - Generate test data (development only)');
    console.log('');
    console.log('Usage: node initialize-xp-system.js <command>');
    process.exit(1);
  }
  
  // Connect to database and run command
  const databaseService = require('../services/database.service');
  
  databaseService.connect()
    .then(() => {
      console.log('📊 Connected to database');
      return commands[command]();
    })
    .then((success) => {
      if (success) {
        console.log('🎉 Command completed successfully');
        process.exit(0);
      } else {
        console.log('❌ Command failed');
        process.exit(1);
      }
    })
    .catch((error) => {
      console.error('💥 Fatal error:', error);
      process.exit(1);
    });
}

module.exports = {
  initializeXPSystem,
  scheduleDailyChallenges,
  migrateExistingUsers,
  cleanupExpiredData,
  generateTestData
};