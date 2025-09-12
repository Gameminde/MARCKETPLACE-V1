/**
 * Test setup configuration for audit system
 */

import { logger } from '../utils/logger';

// Set test environment
process.env.NODE_ENV = 'test';

// Configure logger for tests (suppress console output)
logger.clearLogs();

// Global test timeout
jest.setTimeout(30000);

// Mock console methods to reduce noise in tests
global.console = {
  ...console,
  log: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
};