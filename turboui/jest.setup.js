// Add custom Jest matchers for testing DOM elements
require('@testing-library/jest-dom');

// Mock any global objects that might be needed in tests
global.ResizeObserver = jest.fn().mockImplementation(() => ({
  observe: jest.fn(),
  unobserve: jest.fn(),
  disconnect: jest.fn(),
}));
