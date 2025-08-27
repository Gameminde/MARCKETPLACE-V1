// ========================================
// USER MODEL - POSTGRESQL - PHASE 4
// Gestion utilisateurs avec gamification
// ========================================

const databaseHybridService = require('../services/database-hybrid.service');
const bcrypt = require('bcryptjs');
const productionConfig = require('../../config/production.config');

class UserPostgreSQL {
  constructor() {
    this.tableName = 'users';
    this.init();
  }

  // ========================================
  // INITIALIZATION
  // ========================================
  
  async init() {
    try {
      await this.createTable();
      console.log('✅ Users table initialized');
    } catch (error) {
      console.error('❌ Error initializing users table:', error);
    }
  }

  async createTable() {
    const createTableSQL = `
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        uuid UUID DEFAULT gen_random_uuid() UNIQUE NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        username VARCHAR(50) UNIQUE NOT NULL,
        first_name VARCHAR(100) NOT NULL,
        last_name VARCHAR(100) NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'vendor', 'admin', 'moderator')),
        status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'banned', 'pending')),
        
        -- Profile information
        avatar_url TEXT,
        bio TEXT,
        phone VARCHAR(20),
        date_of_birth DATE,
        location JSONB,
        
        -- Gamification system
        experience_points INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1,
        badges JSONB DEFAULT '[]',
        achievements JSONB DEFAULT '[]',
        streak_days INTEGER DEFAULT 0,
        last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        
        -- Vendor specific
        vendor_verified BOOLEAN DEFAULT FALSE,
        vendor_since TIMESTAMP,
        total_sales DECIMAL(10,2) DEFAULT 0.00,
        rating_average DECIMAL(3,2) DEFAULT 0.00,
        rating_count INTEGER DEFAULT 0,
        
        -- Security & verification
        email_verified BOOLEAN DEFAULT FALSE,
        phone_verified BOOLEAN DEFAULT FALSE,
        two_factor_enabled BOOLEAN DEFAULT FALSE,
        two_factor_secret VARCHAR(255),
        last_password_change TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        password_change_required BOOLEAN DEFAULT FALSE,
        
        -- Preferences
        preferences JSONB DEFAULT '{}',
        notification_settings JSONB DEFAULT '{}',
        language VARCHAR(10) DEFAULT 'fr',
        timezone VARCHAR(50) DEFAULT 'Europe/Paris',
        currency VARCHAR(3) DEFAULT 'EUR',
        
        -- Timestamps
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        last_login TIMESTAMP,
        deleted_at TIMESTAMP
      );
      
      -- Indexes for performance
      CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
      CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
      CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
      CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
      CREATE INDEX IF NOT EXISTS idx_users_level ON users(level);
      CREATE INDEX IF NOT EXISTS idx_users_vendor_verified ON users(vendor_verified);
      CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
      
      -- Trigger for updated_at
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ language 'plpgsql';
      
      CREATE TRIGGER IF NOT EXISTS update_users_updated_at 
        BEFORE UPDATE ON users 
        FOR EACH ROW 
        EXECUTE FUNCTION update_updated_at_column();
    `;

    await databaseHybridService.queryPostgreSQL(createTableSQL);
  }

  // ========================================
  // USER CRUD OPERATIONS
  // ========================================
  
  async create(userData) {
    const {
      email,
      username,
      firstName,
      lastName,
      password,
      role = 'user',
      phone,
      location
    } = userData;

    // Validate input
    if (!email || !username || !firstName || !lastName || !password) {
      throw new Error('Missing required fields');
    }

    // Check if user already exists
    const existingUser = await this.findByEmail(email);
    if (existingUser) {
      throw new Error('User with this email already exists');
    }

    const existingUsername = await this.findByUsername(username);
    if (existingUsername) {
      throw new Error('Username already taken');
    }

    // Hash password
    const saltRounds = productionConfig.security.bcryptRounds;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    const insertSQL = `
      INSERT INTO users (
        email, username, first_name, last_name, password_hash, 
        role, phone, location, preferences, notification_settings
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      RETURNING *
    `;

    const values = [
      email.toLowerCase(),
      username.toLowerCase(),
      firstName,
      lastName,
      passwordHash,
      role,
      phone || null,
      location ? JSON.stringify(location) : null,
      JSON.stringify({ theme: 'light', notifications: true }),
      JSON.stringify({ email: true, push: true, sms: false })
    ];

    const result = await databaseHybridService.queryPostgreSQL(insertSQL, values);
    const user = result.rows[0];

    // Remove sensitive data
    delete user.password_hash;
    
    return user;
  }

  async findById(id) {
    const sql = 'SELECT * FROM users WHERE id = $1 AND deleted_at IS NULL';
    const result = await databaseHybridService.queryPostgreSQL(sql, [id]);
    
    if (result.rows.length === 0) {
      return null;
    }

    const user = result.rows[0];
    delete user.password_hash;
    return user;
  }

  async findByEmail(email) {
    const sql = 'SELECT * FROM users WHERE email = $1 AND deleted_at IS NULL';
    const result = await databaseHybridService.queryPostgreSQL(sql, [email.toLowerCase()]);
    
    if (result.rows.length === 0) {
      return null;
    }

    return result.rows[0]; // Keep password_hash for auth
  }

  async findByUsername(username) {
    const sql = 'SELECT * FROM users WHERE username = $1 AND deleted_at IS NULL';
    const result = await databaseHybridService.queryPostgreSQL(sql, [username.toLowerCase()]);
    
    if (result.rows.length === 0) {
      return null;
    }

    const user = result.rows[0];
    delete user.password_hash;
    return user;
  }

  async update(id, updateData) {
    const allowedFields = [
      'first_name', 'last_name', 'bio', 'phone', 'date_of_birth',
      'location', 'preferences', 'notification_settings', 'language',
      'timezone', 'currency'
    ];

    const updates = [];
    const values = [];
    let paramCount = 1;

    for (const [key, value] of Object.entries(updateData)) {
      if (allowedFields.includes(key) && value !== undefined) {
        updates.push(`${key} = $${paramCount}`);
        values.push(typeof value === 'object' ? JSON.stringify(value) : value);
        paramCount++;
      }
    }

    if (updates.length === 0) {
      throw new Error('No valid fields to update');
    }

    values.push(id);
    const sql = `
      UPDATE users 
      SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP
      WHERE id = $${paramCount} AND deleted_at IS NULL
      RETURNING *
    `;

    const result = await databaseHybridService.queryPostgreSQL(sql, values);
    
    if (result.rows.length === 0) {
      throw new Error('User not found');
    }

    const user = result.rows[0];
    delete user.password_hash;
    return user;
  }

  async delete(id) {
    const sql = `
      UPDATE users 
      SET deleted_at = CURRENT_TIMESTAMP, status = 'banned'
      WHERE id = $1 AND deleted_at IS NULL
      RETURNING id
    `;

    const result = await databaseHybridService.queryPostgreSQL(sql, [id]);
    return result.rows.length > 0;
  }

  // ========================================
  // AUTHENTICATION METHODS
  // ========================================
  
  async authenticate(email, password) {
    const user = await this.findByEmail(email);
    if (!user) {
      return null;
    }

    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return null;
    }

    // Update last login
    await this.updateLastLogin(user.id);

    // Remove sensitive data
    delete user.password_hash;
    return user;
  }

  async updateLastLogin(id) {
    const sql = 'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = $1';
    await databaseHybridService.queryPostgreSQL(sql, [id]);
  }

  async changePassword(id, currentPassword, newPassword) {
    const user = await this.findById(id);
    if (!user) {
      throw new Error('User not found');
    }

    // Verify current password
    const currentUser = await this.findByEmail(user.email);
    const isValidPassword = await bcrypt.compare(currentPassword, currentUser.password_hash);
    if (!isValidPassword) {
      throw new Error('Current password is incorrect');
    }

    // Hash new password
    const saltRounds = productionConfig.security.bcryptRounds;
    const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

    // Update password
    const sql = `
      UPDATE users 
      SET password_hash = $1, last_password_change = CURRENT_TIMESTAMP
      WHERE id = $2
    `;

    await databaseHybridService.queryPostgreSQL(sql, [newPasswordHash, id]);
    return true;
  }

  // ========================================
  // GAMIFICATION METHODS
  // ========================================
  
  async addExperiencePoints(id, points, reason) {
    const sql = `
      UPDATE users 
      SET experience_points = experience_points + $1,
          level = CASE 
            WHEN experience_points + $1 >= 1000 THEN 2
            WHEN experience_points + $1 >= 2500 THEN 3
            WHEN experience_points + $1 >= 5000 THEN 4
            WHEN experience_points + $1 >= 10000 THEN 5
            ELSE level
          END,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
      RETURNING experience_points, level
    `;

    const result = await databaseHybridService.queryPostgreSQL(sql, [points, id]);
    
    if (result.rows.length > 0) {
      const { experience_points, level } = result.rows[0];
      
      // Check for level up
      if (level > 1) {
        await this.addBadge(id, `level_${level}`, `Niveau ${level} atteint !`);
      }
      
      return { experience_points, level };
    }
    
    return null;
  }

  async addBadge(id, badgeId, description) {
    const sql = `
      UPDATE users 
      SET badges = CASE 
        WHEN badges IS NULL THEN $1::jsonb
        ELSE badges || $1::jsonb
      END
      WHERE id = $2 AND NOT (badges @> $1::jsonb)
    `;

    const badge = JSON.stringify([{ id: badgeId, description, earned_at: new Date().toISOString() }]);
    await databaseHybridService.queryPostgreSQL(sql, [badge, id]);
  }

  async addAchievement(id, achievementId, description, points = 0) {
    const sql = `
      UPDATE users 
      SET achievements = CASE 
        WHEN achievements IS NULL THEN $1::jsonb
        ELSE achievements || $1::jsonb
      END
      WHERE id = $2 AND NOT (achievements @> $1::jsonb)
    `;

    const achievement = JSON.stringify([{ 
      id: achievementId, 
      description, 
      points,
      earned_at: new Date().toISOString() 
    }]);
    
    await databaseHybridService.queryPostgreSQL(sql, [achievement, id]);
    
    // Add experience points for achievement
    if (points > 0) {
      await this.addExperiencePoints(id, points, `Achievement: ${description}`);
    }
  }

  // ========================================
  // VENDOR METHODS
  // ========================================
  
  async upgradeToVendor(id) {
    const sql = `
      UPDATE users 
      SET role = 'vendor', 
          vendor_since = CURRENT_TIMESTAMP,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND role = 'user'
      RETURNING *
    `;

    const result = await databaseHybridService.queryPostgreSQL(sql, [id]);
    
    if (result.rows.length > 0) {
      const user = result.rows[0];
      delete user.password_hash;
      
      // Add vendor badge
      await this.addBadge(id, 'vendor', 'Vendeur certifié !');
      
      return user;
    }
    
    throw new Error('User not found or already a vendor');
  }

  async updateVendorStats(id, sales, rating) {
    const sql = `
      UPDATE users 
      SET total_sales = total_sales + $1,
          rating_average = CASE 
            WHEN rating_count = 0 THEN $2
            ELSE ((rating_average * rating_count) + $2) / (rating_count + 1)
          END,
          rating_count = rating_count + 1,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $3 AND role = 'vendor'
      RETURNING total_sales, rating_average, rating_count
    `;

    const result = await databaseHybridService.queryPostgreSQL(sql, [sales, rating, id]);
    return result.rows[0];
  }

  // ========================================
  // SEARCH & FILTERING
  // ========================================
  
  async searchUsers(query, filters = {}, page = 1, limit = 20) {
    let sql = 'SELECT * FROM users WHERE deleted_at IS NULL';
    const values = [];
    let paramCount = 1;

    // Search query
    if (query) {
      sql += ` AND (
        username ILIKE $${paramCount} OR 
        first_name ILIKE $${paramCount} OR 
        last_name ILIKE $${paramCount} OR
        email ILIKE $${paramCount}
      )`;
      values.push(`%${query}%`);
      paramCount++;
    }

    // Role filter
    if (filters.role) {
      sql += ` AND role = $${paramCount}`;
      values.push(filters.role);
      paramCount++;
    }

    // Status filter
    if (filters.status) {
      sql += ` AND status = $${paramCount}`;
      values.push(filters.status);
      paramCount++;
    }

    // Level filter
    if (filters.minLevel) {
      sql += ` AND level >= $${paramCount}`;
      values.push(filters.minLevel);
      paramCount++;
    }

    // Vendor verified filter
    if (filters.vendorVerified !== undefined) {
      sql += ` AND vendor_verified = $${paramCount}`;
      values.push(filters.vendorVerified);
      paramCount++;
    }

    // Pagination
    const offset = (page - 1) * limit;
    sql += ` ORDER BY created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    values.push(limit, offset);

    const result = await databaseHybridService.queryPostgreSQL(sql, values);
    
    // Remove sensitive data
    const users = result.rows.map(user => {
      delete user.password_hash;
      return user;
    });

    return users;
  }

  // ========================================
  // STATISTICS & ANALYTICS
  // ========================================
  
  async getUserStats(id) {
    const sql = `
      SELECT 
        experience_points,
        level,
        (SELECT COUNT(*) FROM users WHERE level > u.level) as rank,
        (SELECT COUNT(*) FROM users) as total_users,
        vendor_verified,
        total_sales,
        rating_average,
        rating_count,
        created_at,
        last_activity
      FROM users u
      WHERE id = $1
    `;

    const result = await databaseHybridService.queryPostgreSQL(sql, [id]);
    return result.rows[0];
  }

  async getLeaderboard(limit = 10) {
    const sql = `
      SELECT 
        id, username, first_name, last_name, 
        experience_points, level, total_sales, rating_average
      FROM users 
      WHERE deleted_at IS NULL AND status = 'active'
      ORDER BY experience_points DESC, level DESC
      LIMIT $1
    `;

    const result = await databaseHybridService.queryPostgreSQL(sql, [limit]);
    return result.rows;
  }
}

module.exports = new UserPostgreSQL();
