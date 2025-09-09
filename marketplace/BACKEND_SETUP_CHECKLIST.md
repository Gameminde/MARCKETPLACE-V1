# 📋 BACKEND SETUP CHECKLIST

## 🚀 IMMEDIATE SETUP REQUIREMENTS

### 1. DATABASE SETUP
- [ ] Install MongoDB Community Server (v6.0+)
  - Download from: https://www.mongodb.com/try/download/community
  - Install with default settings
- [ ] Start MongoDB service
  - Windows: `net start MongoDB`
  - macOS: `brew services start mongodb-community`
  - Linux: `sudo systemctl start mongod`
- [ ] Verify MongoDB is running
  - Command: `mongo --eval "db.runCommand({ connectionStatus: 1 })"`
  - Expected: Connection status should show "connected"

### 2. ENVIRONMENT CONFIGURATION
- [ ] Update `.env` file with secure values:
  - [ ] `MONGODB_URI` - Point to your MongoDB instance
  - [ ] `JWT_SECRET` - 64-character cryptographically secure key
  - [ ] `JWT_REFRESH_SECRET` - Different 64-character key
  - [ ] `STRIPE_SECRET_KEY` - Live secret key from Stripe
  - [ ] `STRIPE_PUBLISHABLE_KEY` - Live publishable key from Stripe
  - [ ] `GOOGLE_CLOUD_PROJECT_ID` - Actual Google Cloud project ID
  - [ ] `GOOGLE_VISION_API_KEY` - Actual Google Vision API key
  - [ ] Other sensitive values (remove placeholder text)

### 3. DEPENDENCY INSTALLATION
- [ ] Install Node.js dependencies:
  - Command: `npm install`
  - Verify: Check that `node_modules` directory is created
- [ ] Verify Node.js version compatibility:
  - Required: Node.js >= 18.0.0
  - Check: `node --version`
- [ ] Verify npm version compatibility:
  - Required: npm >= 8.0.0
  - Check: `npm --version`

### 4. INITIAL TESTING
- [ ] Start backend server:
  - Development: `npm run dev`
  - Production: `npm run start`
- [ ] Test health endpoint:
  - URL: `http://localhost:3001/health`
  - Expected: JSON response with status "OK"
- [ ] Test status endpoint:
  - URL: `http://localhost:3001/status`
  - Expected: JSON response showing database connection status

### 5. API ENDPOINT VERIFICATION
- [ ] Test authentication endpoints:
  - [ ] POST `/api/v1/auth/register` - User registration
  - [ ] POST `/api/v1/auth/login` - User login
  - [ ] GET `/api/v1/auth/me` - Get current user (with auth token)
- [ ] Test product endpoints:
  - [ ] GET `/api/v1/products` - List products
  - [ ] GET `/api/v1/products/{id}` - Get product details
- [ ] Test cart endpoints:
  - [ ] GET `/api/v1/cart` - Get cart items
  - [ ] POST `/api/v1/cart/items` - Add item to cart

### 6. FLUTTER INTEGRATION TESTING
- [ ] Update Flutter environment:
  - [ ] Check `lib/core/config/environment.dart`
  - [ ] Verify `baseUrl` points to `http://localhost:3001/api`
- [ ] Test authentication flow:
  - [ ] Register new user
  - [ ] Login and receive JWT tokens
  - [ ] Access protected endpoints
- [ ] Test core functionality:
  - [ ] Browse products
  - [ ] Add items to cart
  - [ ] Place orders

### 7. SECURITY VALIDATION
- [ ] Verify JWT token security:
  - [ ] Tokens expire correctly
  - [ ] Refresh token mechanism works
  - [ ] Token blacklisting on logout
- [ ] Test rate limiting:
  - [ ] Excessive requests are blocked
  - [ ] Brute force protection works
- [ ] Validate input sanitization:
  - [ ] XSS protection active
  - [ ] SQL injection prevention
  - [ ] Input validation enforced

### 8. PERFORMANCE CHECKS
- [ ] Database connection pooling:
  - [ ] Verify `maxPoolSize: 10` in database configuration
- [ ] Response times:
  - [ ] Auth endpoints < 200ms
  - [ ] Product endpoints < 100ms
  - [ ] Cart operations < 75ms
- [ ] Memory usage:
  - [ ] Monitor for memory leaks
  - [ ] Optimize large data responses

## 🛠️ TROUBLESHOOTING

### Common Issues and Solutions

#### MongoDB Connection Failed
**Error**: "MongoDB connection failed" or "ECONNREFUSED"
**Solution**:
1. Verify MongoDB is installed and running
2. Check MongoDB service status
3. Verify `MONGODB_URI` in `.env` file
4. Ensure MongoDB is listening on port 27017

#### Environment Variables Not Set
**Error**: "Missing required environment variable" or placeholder values
**Solution**:
1. Open `.env` file
2. Replace all placeholder values with actual secure values
3. Ensure no "your-" or "placeholder" text remains

#### Dependency Installation Errors
**Error**: "npm install" fails or package not found
**Solution**:
1. Clear npm cache: `npm cache clean --force`
2. Delete `node_modules` directory
3. Delete `package-lock.json` file
4. Run `npm install` again

#### Port Already in Use
**Error**: "Port 3001 is already in use"
**Solution**:
1. Find process using port: `netstat -ano | findstr :3001`
2. Kill process: `taskkill /PID <process_id> /F`
3. Or change port in `.env` file: `PORT=3002`

#### JWT Secret Too Short
**Error**: "JWT_SECRET must be at least 32 characters"
**Solution**:
1. Generate secure 64-character secret
2. Update `JWT_SECRET` in `.env` file
3. Ensure `JWT_REFRESH_SECRET` is different

## 📞 SUPPORT

If you encounter issues not covered in this checklist:

1. **Check logs**: Look at console output for detailed error messages
2. **Verify versions**: Ensure Node.js (>=18.0.0) and MongoDB (>=4.4) versions
3. **Consult documentation**: Review README.md files in backend directory
4. **Reach out**: Contact development team for assistance

---
*Checklist last updated: September 9, 2025*