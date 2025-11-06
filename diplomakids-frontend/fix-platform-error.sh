#!/bin/bash

# Fix for PlatformConstants error in Expo
echo "🔧 Fixing PlatformConstants error..."

# Step 1: Clear all caches
echo "📦 Clearing caches..."
rm -rf node_modules
rm -rf .expo
rm -rf package-lock.json
rm -rf yarn.lock

# For iOS
if [ -d "ios" ]; then
  cd ios
  rm -rf Pods
  rm -rf Podfile.lock
  rm -rf build
  cd ..
fi

# For Android
if [ -d "android" ]; then
  cd android
  rm -rf .gradle
  rm -rf build
  cd ..
fi

# Step 2: Clear Expo cache
echo "🧹 Clearing Expo cache..."
npx expo start --clear

# Kill the process after 5 seconds
sleep 5
pkill -f "expo start" 2>/dev/null

# Step 3: Clear watchman (if installed)
if command -v watchman &> /dev/null; then
  echo "🔄 Clearing Watchman..."
  watchman watch-del-all
fi

# Step 4: Clear Metro cache
echo "🚇 Clearing Metro cache..."
rm -rf $TMPDIR/metro-*
rm -rf $TMPDIR/react-*
rm -rf $TMPDIR/haste-*

# Step 5: Reinstall dependencies
echo "📦 Installing fresh dependencies..."
npm install

# Step 6: Create a working metro.config.js
cat > metro.config.js << 'EOF'
const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

config.resolver.assetExts.push('db');

module.exports = config;
EOF

echo "✅ Fix applied!"
echo ""
echo "Now try running the app with:"
echo "  npx expo start --clear"
echo ""
echo "If you still see errors, try:"
echo "  1. npx expo doctor"
echo "  2. npx expo install --fix"
echo "  3. npm start -- --reset-cache"
