/**
 * Structured logging utility with configurable log levels
 * 
 * Provides consistent logging across the application with automatic
 * timestamps, prefixes, and environment-aware defaults. Replaces raw
 * console.log calls for better debugging and production monitoring.
 * 
 * @module shared/logger
 * @example
 * ```typescript
 * import { createLogger } from './logger';
 * 
 * const log = createLogger('MyModule');
 * log.info('Starting operation');
 * log.debug('Debug details', { data: 'value' });
 * log.error('Operation failed', error);
 * ```
 */

/**
 * Available log levels in order of severity
 */
export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

/**
 * Logger configuration options
 */
interface LoggerConfig {
  /** Minimum log level to output (levels below this are suppressed) */
  minLevel: LogLevel;
  
  /** Optional prefix prepended to all log messages */
  prefix?: string;
}

/**
 * Numeric ordering of log levels for filtering
 */
const LOG_LEVEL_ORDER: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

/**
 * Logger class providing structured logging with configurable behavior
 */
class Logger {
  private config: LoggerConfig;

  /**
   * Create a new Logger instance
   * @param config - Configuration options
   */
  constructor(config: Partial<LoggerConfig> = {}) {
    let minLevel: LogLevel = 'debug';
    
    // Safely check for production environment
    try {
      if (typeof process !== 'undefined' && process.env && process.env['NODE_ENV'] === 'production') {
        minLevel = 'info';
      }
    } catch {
      // Ignore errors accessing process
    }

    this.config = {
      minLevel,
      ...config,
    };
  }

  /**
   * Check if a message at the given level should be logged
   * @param level - Log level to check
   * @returns True if the level should be logged
   */
  private shouldLog(level: LogLevel): boolean {
    return LOG_LEVEL_ORDER[level] >= LOG_LEVEL_ORDER[this.config.minLevel];
  }

  /**
   * Format a log message with timestamp and prefix
   * @param level - Log level
   * @param message - Message to format
   * @returns Formatted message string
   */
  private formatMessage(level: LogLevel, message: string): string {
    const timestamp = new Date().toISOString();
    const prefix = this.config.prefix ? `[${this.config.prefix}] ` : '';
    return `${timestamp} ${level.toUpperCase()} ${prefix}${message}`;
  }

  /**
   * Log a debug message (lowest severity)
   * Only shown in development mode by default
   * @param message - Message to log
   * @param args - Additional arguments to log
   */
  debug(message: string, ...args: unknown[]): void {
    if (this.shouldLog('debug')) {
      console.log(this.formatMessage('debug', message), ...args);
    }
  }

  /**
   * Log an info message (normal severity)
   * @param message - Message to log
   * @param args - Additional arguments to log
   */
  info(message: string, ...args: unknown[]): void {
    if (this.shouldLog('info')) {
      console.log(this.formatMessage('info', message), ...args);
    }
  }

  /**
   * Log a warning message (elevated severity)
   * @param message - Message to log
   * @param args - Additional arguments to log
   */
  warn(message: string, ...args: unknown[]): void {
    if (this.shouldLog('warn')) {
      console.warn(this.formatMessage('warn', message), ...args);
    }
  }

  /**
   * Log an error message (highest severity)
   * @param message - Message to log
   * @param args - Additional arguments to log
   */
  error(message: string, ...args: unknown[]): void {
    if (this.shouldLog('error')) {
      console.error(this.formatMessage('error', message), ...args);
    }
  }

  /**
   * Create a child logger with an additional prefix
   * 
   * Useful for creating module-specific loggers while maintaining
   * the parent's configuration
   * 
   * @param prefix - Additional prefix for the child logger
   * @returns New Logger instance with combined prefix
   * @example
   * ```typescript
   * const parentLog = createLogger('Parent');
   * const childLog = parentLog.child('Child');
   * childLog.info('test'); // Logs: "[Parent:Child] test"
   * ```
   */
  child(prefix: string): Logger {
    return new Logger({
      ...this.config,
      prefix: this.config.prefix ? `${this.config.prefix}:${prefix}` : prefix,
    });
  }

  /**
   * Change the minimum log level dynamically
   * 
   * @param level - New minimum log level
   * @example
   * ```typescript
   * logger.setLevel('error'); // Only show errors
   * ```
   */
  setLevel(level: LogLevel): void {
    this.config.minLevel = level;
  }
}

/**
 * Default logger instance used throughout the application
 */
export const logger = new Logger();

/**
 * Create a logger for a specific module with a prefix
 * 
 * This is the recommended way to create loggers in the application.
 * Each module should create its own logger with a descriptive prefix.
 * 
 * @param prefix - Module or component name
 * @returns Logger instance configured for the module
 * @example
 * ```typescript
 * const log = createLogger('ConfigManager');
 * log.info('Config loaded successfully');
 * ```
 */
export function createLogger(prefix: string): Logger {
  return logger.child(prefix);
}

/**
 * Extract a safe error message from an unknown error type
 * 
 * TypeScript catch blocks use `unknown` type, so this helper safely
 * converts any caught error to a string message.
 * 
 * @param error - Error of unknown type from catch block
 * @returns String error message
 * @example
 * ```typescript
 * try {
 *   riskyOperation();
 * } catch (error) {
 *   log.error('Operation failed:', getErrorMessage(error));
 * }
 * ```
 */
export function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  if (typeof error === 'string') {
    return error;
  }
  return 'Unknown error';
}
