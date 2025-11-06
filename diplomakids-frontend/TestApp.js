// TestApp.js - Ultra minimal test to verify Expo works
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

export default function App() {
  return (
    <View style={styles.container}>
      <Text style={styles.text}>✅ Expo Works!</Text>
      <Text style={styles.subtext}>PlatformConstants Error Fixed</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#4A90E2',
    justifyContent: 'center',
    alignItems: 'center',
  },
  text: {
    fontSize: 32,
    color: 'white',
    fontWeight: 'bold',
  },
  subtext: {
    fontSize: 18,
    color: 'white',
    marginTop: 10,
  },
});
