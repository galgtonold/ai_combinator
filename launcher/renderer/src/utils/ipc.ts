import type { CONTEXT_BRIDGE } from "../../electron/preload";

declare global {
  interface Window {
    bridge: typeof CONTEXT_BRIDGE;
  }
}

// Provider type definition
type AIProvider = 'openai' | 'anthropic' | 'google' | 'xai' | 'deepseek';

export interface Config {
  factorioPath: string;
  openAIKey: string; // Deprecated - kept for migration
  aiBridgeEnabled: boolean;
  aiProvider: AIProvider;
  aiModel: string;
  udpPort: number;
  // Provider-specific API keys
  providerApiKeys: {
    [key in AIProvider]?: string;
  };
}

export type FactorioStatus = 'not_found' | 'found' | 'running' | 'stopped';

const ipc = window.bridge;
export default ipc;
