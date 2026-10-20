/**
 * Shared message log for operations dashboard
 * Captures all system messages (info, error, debug) for display on /ops
 */

const messages = [];
const MAX_MESSAGES = 100;

/**
 * Add a message to the log
 * @param {string} level - 'info', 'error', 'debug', 'warn'
 * @param {string} source - Component/module name
 * @param {string} message - Message text
 */
function log(level, source, message) {
  messages.push({
    ts: new Date().toISOString(),
    level,
    source,
    message: String(message),
  });

  // Keep only last N messages
  if (messages.length > MAX_MESSAGES) {
    messages.shift();
  }

  // Also log to console with color coding
  const timestamp = new Date().toLocaleTimeString();
  const prefix = `[${timestamp}] [${source}]`;
  
  switch (level) {
    case 'error':
      console.error(`${prefix} ❌`, message);
      break;
    case 'warn':
      console.warn(`${prefix} ⚠️`, message);
      break;
    case 'debug':
      console.debug(`${prefix} 🐛`, message);
      break;
    case 'info':
    default:
      console.log(`${prefix} ℹ️`, message);
      break;
  }
}

/**
 * Get all messages
 * @returns {Array} Array of message objects
 */
function getMessages() {
  return [...messages];
}

/**
 * Clear the message log
 */
function clear() {
  messages.length = 0;
}

/**
 * Convenience methods
 */
const logger = {
  info: (source, message) => log('info', source, message),
  error: (source, message) => log('error', source, message),
  warn: (source, message) => log('warn', source, message),
  debug: (source, message) => log('debug', source, message),
  getMessages,
  clear,
};

module.exports = logger;
