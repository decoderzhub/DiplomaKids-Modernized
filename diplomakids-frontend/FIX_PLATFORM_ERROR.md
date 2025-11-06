# 🚨 FIX for PlatformConstants Error

## Quick Solution (Try This First!)

```bash
# 1. Clear everything and start fresh
npx expo start --clear

# 2. If that doesn't work, run the fix script:
chmod +x fix-platform-error.sh
./fix-platform-error.sh

# 3. Then start the app:
npx expo start --clear
```

## Manual Fix Steps

If the script doesn't work, try these manual steps:

### Step 1: Complete Cache Clear
```bash
# Kill any running Metro/Expo processes
killall node

# Clear all caches
rm -rf node_modules
rm -rf .expo
rm -rf package-lock.json
rm -rf $TMPDIR/metro-*
rm -rf $TMPDIR/react-*

# Clear watchman (if you have it)
watchman watch-del-all 2>/dev/null

# Clear npm cache
npm cache clean --force
```

### Step 2: Fresh Install
```bash
# Install dependencies
npm install

# Fix any broken dependencies
npx expo install --fix

# Check for issues
npx expo doctor
```

### Step 3: Start with Clear Cache
```bash
npx expo start --clear
```

## Alternative Solutions

### Solution A: Use Expo Go App
Instead of running in the simulator, try:
```bash
npx expo start
# Then scan QR code with Expo Go app on your phone
```

### Solution B: Downgrade to Stable Expo SDK
```bash
# Use Expo SDK 51 (more stable)
npm uninstall expo
npm install expo@~51.0.0
npx expo install --fix
```

### Solution C: Create Fresh Project
```bash
# Create a new Expo project and copy code
npx create-expo-app DiplomaKidsNew --template blank
cd DiplomaKidsNew
# Copy your App.js into the new project
```

### Solution D: Reset Simulator/Emulator
**iOS Simulator:**
```bash
# Reset iOS Simulator
xcrun simctl shutdown all
xcrun simctl erase all
```

**Android Emulator:**
```bash
# Clear Android build
cd android && ./gradlew clean
cd ..
```

## Common Causes & Fixes

| Issue | Solution |
|-------|----------|
| Version mismatch | Run `npx expo install --fix` |
| Corrupted cache | Run `npx expo start --clear` |
| Bad node_modules | Delete and reinstall |
| Metro issues | Reset Metro with `npx react-native start --reset-cache` |
| Native module issues | Run `npx expo run:ios --clear` or `npx expo run:android --clear` |

## Working Minimal App

The `App.js` provided is a minimal working version that avoids problematic dependencies:
- No navigation (which can cause PlatformConstants errors)
- No complex dependencies
- Just basic React Native components
- Works with Expo Go

## Environment Check

Run this to check your environment:
```bash
# Check versions
node --version  # Should be 18+
npm --version   # Should be 9+
npx expo --version  # Should match SDK version

# Check for issues
npx expo doctor
```

## If Nothing Works

1. **Use Web Version First:**
   ```bash
   npx expo start --web
   ```
   This bypasses native module issues.

2. **Try Snack:**
   Upload your code to https://snack.expo.dev to test online.

3. **Report Issue:**
   If using Expo SDK 54 specifically causes this, it might be a bug. Report at:
   https://github.com/expo/expo/issues

## Working Project Structure

```
diplomakids-expo54-fixed/
├── App.js              # Minimal working app
├── app.json            # Basic Expo config
├── package.json        # Minimal dependencies
├── fix-platform-error.sh  # Fix script
└── assets/             # Add placeholder images
    ├── icon.png
    ├── splash.png
    ├── adaptive-icon.png
    └── favicon.png
```

## Quick Test Code

Replace your App.js with this ultra-minimal version:

```javascript
import React from 'react';
import { View, Text } from 'react-native';

export default function App() {
  return (
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
      <Text style={{ fontSize: 24 }}>DiplomaKids Works!</Text>
    </View>
  );
}
```

---

**Still having issues?** The PlatformConstants error is often related to:
- React Native version incompatibility with Expo
- Native modules not properly linked
- Simulator/emulator cache issues
- Conflicting dependencies

Try the solutions in order, and the minimal App.js should work!
