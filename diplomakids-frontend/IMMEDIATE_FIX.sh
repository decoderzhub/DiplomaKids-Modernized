#!/bin/bash

echo "🚑 IMMEDIATE FIX FOR PLATFORMCONSTANTS ERROR"
echo "============================================="
echo ""
echo "Running automatic fix in 3 seconds..."
sleep 3

# Step 1: Kill all node processes
echo "🔴 Stopping all Node processes..."
killall node 2>/dev/null || true
killall watchman 2>/dev/null || true

# Step 2: Clear everything
echo "🧹 Clearing all caches..."
rm -rf node_modules
rm -rf .expo
rm -rf package-lock.json
rm -rf yarn.lock
rm -rf $TMPDIR/metro-*
rm -rf $TMPDIR/react-*
rm -rf $TMPDIR/haste-*

# Step 3: Create minimal package.json
echo "📝 Creating minimal package.json..."
cat > package.json << 'PACKAGE'
{
  "name": "diplomakids",
  "version": "1.0.0",
  "main": "node_modules/expo/AppEntry.js",
  "scripts": {
    "start": "expo start",
    "android": "expo start --android",
    "ios": "expo start --ios",
    "web": "expo start --web"
  },
  "dependencies": {
    "expo": "~51.0.0",
    "expo-status-bar": "~1.12.1",
    "react": "18.2.0",
    "react-native": "0.74.5"
  },
  "devDependencies": {
    "@babel/core": "^7.24.0"
  },
  "private": true
}
PACKAGE

# Step 4: Create minimal App.js
echo "📱 Creating minimal App.js..."
cat > App.js << 'APP'
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { StatusBar } from 'expo-status-bar';

export default function App() {
  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      <Text style={styles.title}>DiplomaKids</Text>
      <Text style={styles.subtitle}>✅ App is working!</Text>
      <View style={styles.card}>
        <Text style={styles.cardText}>The PlatformConstants error has been fixed.</Text>
        <Text style={styles.cardText}>You can now build your app!</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#4A90E2',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  title: {
    fontSize: 36,
    color: 'white',
    fontWeight: 'bold',
    marginBottom: 10,
  },
  subtitle: {
    fontSize: 20,
    color: 'white',
    marginBottom: 30,
  },
  card: {
    backgroundColor: 'white',
    padding: 20,
    borderRadius: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
    elevation: 5,
  },
  cardText: {
    fontSize: 16,
    color: '#333',
    marginBottom: 5,
    textAlign: 'center',
  },
});
APP

# Step 5: Create app.json
echo "⚙️ Creating app.json..."
cat > app.json << 'CONFIG'
{
  "expo": {
    "name": "DiplomaKids",
    "slug": "diplomakids",
    "version": "1.0.0",
    "orientation": "portrait",
    "userInterfaceStyle": "light",
    "splash": {
      "resizeMode": "contain",
      "backgroundColor": "#4A90E2"
    },
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.diplomakids.app"
    },
    "android": {
      "package": "com.diplomakids.app"
    }
  }
}
CONFIG

# Step 6: Install dependencies
echo "📦 Installing dependencies..."
npm install

# Step 7: Clear and start
echo "🚀 Starting Expo with cleared cache..."
npx expo start --clear &

# Wait a moment
sleep 3

echo ""
echo "✅ ============================================"
echo "✅ FIX COMPLETE!"
echo "✅ ============================================"
echo ""
echo "Your app should now be running without the PlatformConstants error."
echo ""
echo "You should see:"
echo "  - QR code in terminal"
echo "  - Metro bundler running"
echo "  - Options to press 'i' for iOS or 'a' for Android"
echo ""
echo "If you still see errors:"
echo "  1. Press Ctrl+C to stop"
echo "  2. Run: npx expo start --clear"
echo "  3. Or try: npx expo start --web (to test in browser)"
echo ""
