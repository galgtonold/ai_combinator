/**
 * Shared constants for the AI Combinator Launcher
 */

// ============================================================================
// Network Configuration
// ============================================================================

/** Port the AI Bridge listens on for incoming requests from Factorio */
export const AI_BRIDGE_LISTEN_PORT = 8889;

/** Port for sending responses back to Factorio */
export const AI_BRIDGE_RESPONSE_PORT = 9001;

/** Default host for AI Bridge responses */
export const AI_BRIDGE_RESPONSE_HOST = 'localhost';

// ============================================================================
// Timing Configuration
// ============================================================================

/** Interval for checking Factorio process status (ms) */
export const FACTORIO_STATUS_CHECK_INTERVAL = 5000;

/** Default timeout for status messages (ms) */
export const STATUS_MESSAGE_TIMEOUT = 5000;

/** Delay after launching Factorio before checking status (ms) */
export const FACTORIO_LAUNCH_STATUS_DELAY = 2000;

/** Minimum time to show launching state (ms) */
export const MIN_LAUNCH_DURATION = 5000;

/** Delay between AI Bridge restart stop and start (ms) */
export const AI_BRIDGE_RESTART_DELAY = 500;

// ============================================================================
// Development Server Configuration
// ============================================================================

/** Vite dev server URL */
export const VITE_DEV_SERVER_URL = 'http://localhost:5173/';

/** Maximum retries for connecting to Vite dev server */
export const VITE_MAX_RETRIES = 30;

/** Retry interval for Vite dev server connection (ms) */
export const VITE_RETRY_INTERVAL = 1000;

// ============================================================================
// Default Configuration Values
// ============================================================================

/** Default AI provider */
export const DEFAULT_AI_PROVIDER = 'openai';

/** Default AI model */
export const DEFAULT_AI_MODEL = 'gpt-5.1';

/** Default UDP port for Factorio communication */
export const DEFAULT_UDP_PORT = 9001;
