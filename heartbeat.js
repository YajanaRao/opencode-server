#!/usr/bin/env node

/**
 * Heartbeat Service
 * 
 * Prevents Render.com free tier instance from sleeping by sending periodic
 * self-pings to the health check endpoint.
 * 
 * Features:
 * - Configurable ping interval (default: 14 minutes)
 * - Self-ping to prevent sleep on Render free tier (15 min timeout)
 * - Extensible for future scheduled tasks (daily summaries, etc.)
 */

const http = require('http');

// Configuration from environment variables
const PORT = process.env.PORT || 10000;
const HEARTBEAT_INTERVAL = process.env.HEARTBEAT_INTERVAL || 14; // minutes
const HEARTBEAT_URL = `http://localhost:${PORT}/global/health`;

// Convert minutes to milliseconds
const INTERVAL_MS = HEARTBEAT_INTERVAL * 60 * 1000;

/**
 * Ping the health check endpoint to keep the service alive
 */
function ping() {
  const startTime = Date.now();
  
  const req = http.get(HEARTBEAT_URL, (res) => {
    const duration = Date.now() - startTime;
    const timestamp = new Date().toISOString();
    
    if (res.statusCode === 200) {
      console.log(`[${timestamp}] ❤️  Heartbeat successful (${duration}ms) - Next ping in ${HEARTBEAT_INTERVAL} minutes`);
    } else {
      console.warn(`[${timestamp}] ⚠️  Heartbeat returned status ${res.statusCode}`);
    }
    
    // Consume response data to free up memory
    res.resume();
  });

  req.on('error', (error) => {
    const timestamp = new Date().toISOString();
    console.error(`[${timestamp}] ❌ Heartbeat failed:`, error.message);
  });

  req.setTimeout(10000, () => {
    req.destroy();
    const timestamp = new Date().toISOString();
    console.error(`[${timestamp}] ❌ Heartbeat timeout after 10s`);
  });
}

/**
 * Wait for server to be ready before starting heartbeat
 */
function waitForServer(maxAttempts = 30, attempt = 1) {
  const req = http.get(HEARTBEAT_URL, (res) => {
    if (res.statusCode === 200) {
      const timestamp = new Date().toISOString();
      console.log(`[${timestamp}] ✅ Server is ready, starting heartbeat service`);
      console.log(`[${timestamp}] 🔄 Heartbeat interval: ${HEARTBEAT_INTERVAL} minutes`);
      console.log(`[${timestamp}] 🎯 Target: ${HEARTBEAT_URL}`);
      
      // Start periodic heartbeat
      setInterval(ping, INTERVAL_MS);
      
      // Do initial ping
      ping();
    }
    res.resume();
  });

  req.on('error', () => {
    if (attempt < maxAttempts) {
      console.log(`Waiting for server to start... (attempt ${attempt}/${maxAttempts})`);
      setTimeout(() => waitForServer(maxAttempts, attempt + 1), 2000);
    } else {
      console.error('❌ Server failed to start within expected time');
      process.exit(1);
    }
  });

  req.setTimeout(2000, () => {
    req.destroy();
  });
}

// Start the heartbeat service
console.log('🚀 Starting heartbeat service...');
waitForServer();

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('Heartbeat service shutting down...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('Heartbeat service shutting down...');
  process.exit(0);
});
