# 🔧 Troubleshooting Guide - Glassify Forge

## Common Issues and Solutions

### 1. 🚨 Three.js Version Conflicts

**Problem:**
```
npm warn Conflicting peer dependency: three@0.179.1
npm warn Found: three@0.152.2
```

**Solution:**
```bash
# Use legacy peer deps to resolve conflicts
npm install --legacy-peer-deps

# Or force update Three.js
npm install three@^0.159.0 --save
```

### 2. 🚨 @types/vite Not Found

**Problem:**
```
npm error 404 Not Found - GET https://registry.npmjs.org/@types%2fvite
```

**Solution:**
The package `@types/vite` doesn't exist. Vite has built-in TypeScript support.
```bash
# Skip this package - it's not needed
npm run install:performance
# This will now just echo a success message
```

### 3. 🚨 MCP Servers Not Starting

**Problem:**
MCP servers show as "pending" or "failed" in the UI.

**Solution:**
```bash
# Check if all dependencies are installed
npm install --legacy-peer-deps

# Verify MCP configuration
npm run setup-mcp

# Check the browser console for errors
# Open DevTools (F12) and look for error messages
```

### 4. 🚨 3D Components Not Rendering

**Problem:**
Three.js components show blank or error.

**Solution:**
```bash
# Update Three.js to compatible version
npm install three@^0.159.0 @types/three@^0.159.0 --save

# Clear cache and restart
rm -rf node_modules package-lock.json
npm install --legacy-peer-deps
npm run dev
```

### 5. 🚨 Build Errors with Vite

**Problem:**
```
Error: Failed to resolve import
```

**Solution:**
```bash
# Check vite.config.ts aliases
# Ensure all imports use @ alias correctly

# Clear Vite cache
rm -rf node_modules/.vite
npm run dev
```

## 🛠️ Quick Fixes

### Reset Everything
```bash
# Nuclear option - reset all dependencies
rm -rf node_modules package-lock.json
npm install --legacy-peer-deps
npm run setup-mcp
npm run dev
```

### Check Installation Status
```bash
# Verify all scripts work
npm run mcp:status
npm run install-mcps
```

### Update Dependencies
```bash
# Update to latest compatible versions
npm update --legacy-peer-deps
```

## 🔍 Debugging Steps

1. **Check Console Errors:**
   - Open browser DevTools (F12)
   - Look for red errors in Console tab
   - Check Network tab for failed requests

2. **Verify File Structure:**
   ```
   src/
   ├── components/mcp/MCPController.tsx ✓
   ├── lib/mcp-integration.ts ✓
   ├── pages/MCPStudio.tsx ✓
   └── ...
   ```

3. **Test Basic Functionality:**
   - Visit http://localhost:8080/ (should load)
   - Visit http://localhost:8080/mcp (should show MCP Studio)
   - Check if buttons respond to clicks

4. **Check Environment:**
   ```bash
   node --version  # Should be 16+ 
   npm --version   # Should be 8+
   ```

## 📞 Getting Help

If issues persist:

1. **Check the logs:**
   ```bash
   npm run dev 2>&1 | tee debug.log
   ```

2. **Share error details:**
   - Full error message
   - Browser console errors
   - Node.js version
   - Operating system

3. **Common working configuration:**
   - Node.js 18+
   - npm 9+
   - Modern browser (Chrome 90+, Firefox 88+)

## ✅ Success Indicators

When everything works correctly:

- ✅ `npm run dev` starts without errors
- ✅ http://localhost:8080/ loads the marketplace
- ✅ http://localhost:8080/mcp shows MCP Studio
- ✅ MCP servers can be activated/deactivated
- ✅ Quick action buttons respond
- ✅ No console errors in browser DevTools

Happy coding! 🚀