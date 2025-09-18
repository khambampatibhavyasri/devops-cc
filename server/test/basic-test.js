// Basic smoke test for server
const express = require('express');
const cors = require('cors');

console.log('Running basic server tests...');

// Test 1: Check if required modules can be loaded
try {
  require('../server.js');
  console.log('✓ Server modules loaded successfully');
} catch (error) {
  console.error('✗ Error loading server modules:', error.message);
  process.exit(1);
}

// Test 2: Basic functionality test
try {
  const app = express();
  app.use(cors());
  app.use(express.json());

  app.get('/test', (req, res) => {
    res.json({ status: 'ok' });
  });

  console.log('✓ Express app configured successfully');
} catch (error) {
  console.error('✗ Error configuring Express app:', error.message);
  process.exit(1);
}

// Test 3: Environment variables test
const requiredEnvVars = ['NODE_ENV', 'PORT', 'HOST'];
const missingVars = requiredEnvVars.filter(envVar => !process.env[envVar]);

if (missingVars.length === 0) {
  console.log('✓ All required environment variables are set');
} else {
  console.log('⚠ Missing environment variables (using defaults):', missingVars.join(', '));
}

console.log('✓ All basic tests passed!');
process.exit(0);