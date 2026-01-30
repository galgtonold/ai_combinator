/**
 * Shared constants for the AI Combinator Launcher
 * 
 * This module contains all application-wide constants used across both
 * the main and renderer processes. Constants are organized by category.
 * 
 * @module shared/constants
 */

// ============================================================================
// Network Configuration
// ============================================================================

/**
 * UDP port the AI Bridge listens on for incoming requests from Factorio
 * 
 * This port must match the one configured in the Factorio mod's bridge.lua
 * @default 8889
 */
export const AI_BRIDGE_LISTEN_PORT = 8889;

/**
 * UDP port for sending AI-generated responses back to Factorio
 * 
 * Should match DEFAULT_UDP_PORT and the --enable-lua-udp port parameter
 * @default 9001
 */
export const AI_BRIDGE_RESPONSE_PORT = 9001;

/**
 * Default hostname for AI Bridge responses
 * 
 * Uses localhost since Factorio and the bridge run on the same machine
 * @default 'localhost'
 */
export const AI_BRIDGE_RESPONSE_HOST = 'localhost';

// ============================================================================
// Timing Configuration
// ============================================================================

/**
 * Interval for polling Factorio process status (milliseconds)
 * 
 * The launcher checks if Factorio is running at this interval to update UI
 * @default 5000 (5 seconds)
 */
export const FACTORIO_STATUS_CHECK_INTERVAL = 5000;

/**
 * Default timeout for temporary status messages (milliseconds)
 * 
 * Status messages (success/error/warning) auto-clear after this duration
 * @default 5000 (5 seconds)
 */
export const STATUS_MESSAGE_TIMEOUT = 5000;

/**
 * Delay after launching Factorio before checking its running status (milliseconds)
 * 
 * Gives the process time to initialize before we verify it started
 * @default 2000 (2 seconds)
 */
export const FACTORIO_LAUNCH_STATUS_DELAY = 2000;

/**
 * Minimum time to show the "launching" state in the UI (milliseconds)
 * 
 * Prevents UI flickering if Factorio starts very quickly
 * @default 5000 (5 seconds)
 */
export const MIN_LAUNCH_DURATION = 5000;

/**
 * Delay between stopping and starting AI Bridge during restart (milliseconds)
 * 
 * Ensures clean shutdown before attempting to rebind the UDP port
 * @default 500 (0.5 seconds)
 */
export const AI_BRIDGE_RESTART_DELAY = 500;

// ============================================================================
// Development Server Configuration
// ============================================================================

/**
 * Vite development server URL
 * 
 * Used in development mode to connect the Electron window to the hot-reloading server
 * @default 'http://localhost:5173/'
 */
export const VITE_DEV_SERVER_URL = 'http://localhost:5173/';

/**
 * Maximum connection retry attempts for Vite dev server
 * 
 * The app will retry connecting this many times before giving up
 * @default 30
 */
export const VITE_MAX_RETRIES = 30;

/**
 * Delay between Vite dev server connection retries (milliseconds)
 * 
 * @default 1000 (1 second)
 */
export const VITE_RETRY_INTERVAL = 1000;

// ============================================================================
// Default Configuration Values
// ============================================================================

/**
 * Default AI provider selected on first launch
 * 
 * @default 'player2'
 */
export const DEFAULT_AI_PROVIDER = 'player2';

/**
 * Default AI model for the default provider
 * 
 * @default '' (Player2 handles model selection in the app)
 */
export const DEFAULT_AI_MODEL = '';

/**
 * Default UDP port for bidirectional Factorio communication
 * 
 * Must match AI_BRIDGE_RESPONSE_PORT
 * @default 9001
 */
export const DEFAULT_UDP_PORT = 9001;
