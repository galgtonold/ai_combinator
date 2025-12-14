/**
 * Shared type definitions for the AI Combinator Launcher
 * 
 * This module contains all type definitions used across both the Electron
 * main process and the renderer process. It serves as the single source of
 * truth for the application's type contracts.
 * 
 * @module shared/types
 */

/**
 * Supported AI providers for code generation
 * 
 * Each provider has its own SDK integration and requires a specific API key.
 * The AI Bridge uses these providers to generate Lua code for the Moon Logic combinator.
 * 
 * @example
 * ```typescript
 * const provider: AIProvider = 'openai';
 * ```
 */
export type AIProvider = 'openai' | 'anthropic' | 'google' | 'xai' | 'deepseek' | 'ollama';

/**
 * Application configuration stored in user data directory
 * 
 * This configuration is persisted to disk and loaded on application startup.
 * It contains all user preferences and settings required to run the launcher.
 * 
 * @interface Config
 * @example
 * ```typescript
 * const config: Config = {
 *   factorioPath: 'C:/Program Files/Factorio/bin/x64/factorio.exe',
 *   aiBridgeEnabled: true,
 *   aiProvider: 'openai',
 *   aiModel: 'gpt-4',
 *   udpPort: 9001,
 *   providerApiKeys: {
 *     openai: 'sk-...'
 *   }
 * };
 * ```
 */
export interface Config {
  /** Absolute path to the Factorio executable (factorio.exe on Windows) */
  factorioPath: string;
  
  /** Whether the AI bridge should be automatically started when an API key is available */
  aiBridgeEnabled: boolean;
  
  /** Currently selected AI provider for code generation */
  aiProvider: AIProvider;
  
  /** Model identifier for the selected provider (e.g., 'gpt-4', 'claude-3-opus') */
  aiModel: string;
  
  /** UDP port for bidirectional communication with Factorio's Lua bridge */
  udpPort: number;
  
  /** Map of API keys for each provider. Only the current provider's key is used. */
  providerApiKeys: {
    [key in AIProvider]?: string;
  };
  
  /** Map of selected models for each provider. Persists model selection when switching providers. */
  providerModels: {
    [key in AIProvider]?: string;
  };
}

/**
 * Factorio process status
 * 
 * Represents the current state of the Factorio executable:
 * - `not_found`: Executable path not set or doesn't exist
 * - `found`: Executable exists but is not currently running
 * - `running`: Factorio process is currently active
 * - `stopped`: Factorio was running but has now stopped
 */
export type FactorioStatus = 'not_found' | 'found' | 'running' | 'stopped';

/**
 * Result of AI Bridge operations
 * 
 * Returned by start, stop, and toggle operations on the AI Bridge.
 * 
 * @interface AIBridgeResult
 */
export interface AIBridgeResult {
  /** Whether the operation succeeded */
  success: boolean;
  
  /** Human-readable message describing the result or error */
  message: string;
}

/**
 * Result of Factorio launch operations
 * 
 * Returned when attempting to launch the Factorio process.
 * 
 * @interface LaunchResult
 */
export interface LaunchResult {
  /** Whether the launch was initiated successfully */
  success: boolean;
  
  /** Status message or error description */
  message: string;
}

/**
 * Factorio status update from the main process
 * 
 * Sent via IPC when the Factorio process state changes.
 * The renderer subscribes to these updates to keep the UI in sync.
 * 
 * @interface FactorioStatusUpdate
 */
export interface FactorioStatusUpdate {
  /** Current status of the Factorio process */
  status: 'running' | 'stopped';
  
  /** Whether the process terminated with an error */
  error: boolean;
}

/**
 * Context bridge interface exposed to the renderer process via preload script
 * 
 * This interface defines the complete IPC API contract between the main and
 * renderer processes. All communication between the UI and the backend goes
 * through this interface.
 * 
 * The context bridge is exposed as `window.bridge` in the renderer process
 * and provides type-safe access to all main process functionality.
 * 
 * @interface ContextBridge
 * @see electron/preload.ts for the implementation
 * @see electron/services/ipc-handlers.ts for the handlers
 */
export interface ContextBridge {
  /**
   * Get the version of the app, Electron, or Node.js
   * @param opt - Version type to retrieve: 'app' for launcher version, 'electron' or 'node' for runtime versions
   * @returns Version string (e.g., "0.1.1")
   */
  getVersion: (opt: "app" | "electron" | "node") => Promise<string>;
  
  /**
   * Load the current application configuration
   * @returns Current configuration object
   */
  getConfig: () => Promise<Config>;
  
  /**
   * Persist configuration changes to disk
   * @param config - Updated configuration to save
   * @returns True if successful
   */
  saveConfig: (config: Config) => Promise<boolean>;
  
  /**
   * Open a file dialog to manually select Factorio executable
   * @returns Selected file path or null if cancelled
   */
  browseFactorioPath: () => Promise<string | null>;
  
  /**
   * Automatically detect Factorio installation from registry and Steam
   * @returns Detected executable path or null if not found
   */
  autoDetectFactorio: () => Promise<string | null>;
  
  /**
   * Launch Factorio with AI Bridge configuration
   * @returns Launch result with status and message
   */
  launchFactorio: () => Promise<LaunchResult>;
  
  /**
   * Check if the Factorio process is currently running
   * @returns True if running, false otherwise
   */
  isFactorioRunning: () => Promise<boolean>;
  
  /**
   * Subscribe to real-time Factorio process status updates
   * @param callback - Function called when status changes
   * @returns Unsubscribe function to stop receiving updates
   */
  onFactorioStatusUpdate: (callback: (data: FactorioStatusUpdate) => void) => () => void;
  
  /**
   * Toggle AI Bridge on or off based on current state
   * @returns Result with new status
   */
  toggleAIBridge: () => Promise<AIBridgeResult>;
  
  /**
   * Check if AI Bridge is currently active
   * @returns True if running, false otherwise
   */
  isAIBridgeRunning: () => Promise<boolean>;
  
  /**
   * Start the AI Bridge UDP server
   * @returns Result indicating success or failure
   */
  startAIBridge: () => Promise<AIBridgeResult>;
  
  /**
   * Stop the AI Bridge UDP server
   * @returns Result indicating success or failure
   */
  stopAIBridge: () => Promise<AIBridgeResult>;
  
  /**
   * Update the AI model used by the bridge (hot update without restart)
   * @param model - New model identifier
   * @returns True if successful
   */
  updateAIModel: (model: string) => Promise<boolean>;
  
  /**
   * Minimize the application window
   */
  minimizeWindow: () => void;
  
  /**
   * Close the application window
   */
  closeWindow: () => void;
  
  /**
   * Open a URL in the user's default web browser
   * @param url - URL to open
   * @returns True if successful
   */
  openExternal: (url: string) => Promise<boolean>;
}
