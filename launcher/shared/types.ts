/**
 * Shared type definitions for the AI Combinator Launcher
 * These types are used across both the Electron main process and the renderer
 */

/**
 * Supported AI providers for code generation
 */
export type AIProvider = 'openai' | 'anthropic' | 'google' | 'xai' | 'deepseek';

/**
 * Application configuration stored in user data
 */
export interface Config {
  /** Path to the Factorio executable */
  factorioPath: string;
  /** Whether the AI bridge should be active */
  aiBridgeEnabled: boolean;
  /** Currently selected AI provider */
  aiProvider: AIProvider;
  /** Currently selected AI model */
  aiModel: string;
  /** UDP port for communication with Factorio */
  udpPort: number;
  /** API keys for each provider */
  providerApiKeys: {
    [key in AIProvider]?: string;
  };
}

/**
 * Factorio process status
 */
export type FactorioStatus = 'not_found' | 'found' | 'running' | 'stopped';

/**
 * Result of AI Bridge operations
 */
export interface AIBridgeResult {
  success: boolean;
  message: string;
}

/**
 * Result of Factorio launch operations
 */
export interface LaunchResult {
  success: boolean;
  message: string;
}

/**
 * Factorio status update from the main process
 */
export interface FactorioStatusUpdate {
  status: 'running' | 'stopped';
  error: boolean;
}
