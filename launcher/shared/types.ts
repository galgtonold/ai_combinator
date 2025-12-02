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

/**
 * Context bridge interface exposed to the renderer process via preload
 * This defines the IPC API contract between main and renderer processes
 */
export interface ContextBridge {
  /** Get Electron or Node version */
  getVersion: (opt: "electron" | "node") => Promise<string>;
  /** Get current configuration */
  getConfig: () => Promise<Config>;
  /** Save configuration */
  saveConfig: (config: Config) => Promise<boolean>;
  /** Open file dialog to browse for Factorio executable */
  browseFactorioPath: () => Promise<string | null>;
  /** Auto-detect Factorio installation */
  autoDetectFactorio: () => Promise<string | null>;
  /** Launch Factorio */
  launchFactorio: () => Promise<LaunchResult>;
  /** Check if Factorio is running */
  isFactorioRunning: () => Promise<boolean>;
  /** Subscribe to Factorio status updates, returns unsubscribe function */
  onFactorioStatusUpdate: (callback: (data: FactorioStatusUpdate) => void) => () => void;
  /** Toggle AI Bridge on/off */
  toggleAIBridge: () => Promise<AIBridgeResult>;
  /** Check if AI Bridge is running */
  isAIBridgeRunning: () => Promise<boolean>;
  /** Start AI Bridge */
  startAIBridge: () => Promise<AIBridgeResult>;
  /** Stop AI Bridge */
  stopAIBridge: () => Promise<AIBridgeResult>;
  /** Update AI model */
  updateAIModel: (model: string) => Promise<boolean>;
  /** Minimize the window */
  minimizeWindow: () => void;
  /** Close the window */
  closeWindow: () => void;
  /** Open URL in default browser */
  openExternal: (url: string) => Promise<boolean>;
}
