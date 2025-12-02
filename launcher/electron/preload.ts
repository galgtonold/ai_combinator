import { contextBridge, ipcRenderer } from "electron";

type AIProvider = 'openai' | 'anthropic' | 'google' | 'xai' | 'deepseek';

interface Config {
  factorioPath: string;
  aiBridgeEnabled: boolean;
  aiProvider: AIProvider;
  aiModel: string;
  udpPort: number;
  providerApiKeys: {
    [key in AIProvider]?: string;
  };
}

export type FactorioStatus = 'not_found' | 'found' | 'running' | 'stopped';

export const CONTEXT_BRIDGE = {
  /**
   * Returns the version from process.versions of the supplied target.
   */
  getVersion: async (opt: "electron" | "node"): Promise<string> => {
    return await ipcRenderer.invoke(`get-version`, opt);
  },

  /**
   * Get the current configuration
   */
  getConfig: async (): Promise<Config> => {
    return await ipcRenderer.invoke("get-config");
  },

  /**
   * Save the configuration
   */
  saveConfig: async (config: Config): Promise<boolean> => {
    return await ipcRenderer.invoke("save-config", config);
  },

  /**
   * Browse for Factorio executable
   */
  browseFactorioPath: async (): Promise<string | null> => {
    return await ipcRenderer.invoke("browse-factorio-path");
  },

  /**
   * Auto-detect Factorio executable
   */
  autoDetectFactorio: async (): Promise<string | null> => {
    return await ipcRenderer.invoke("auto-detect-factorio");
  },

  /**
   * Launch Factorio
   */
  launchFactorio: async (): Promise<{success: boolean, message: string}> => {
    return await ipcRenderer.invoke("launch-factorio");
  },
  
  /**
   * Check if Factorio is running
   */
  isFactorioRunning: async (): Promise<boolean> => {
    return await ipcRenderer.invoke("is-factorio-running");
  },
  
  /**
   * Subscribe to Factorio status updates
   */
  onFactorioStatusUpdate: (callback: (data: {status: string, error?: boolean}) => void) => {
    ipcRenderer.on('factorio-status-update', (_, data) => callback(data));
    return () => {
      ipcRenderer.removeAllListeners('factorio-status-update');
    };
  },
  
  /**
   * Toggle AI Bridge on/off
   */
  toggleAIBridge: async (): Promise<{success: boolean, message: string}> => {
    return await ipcRenderer.invoke("toggle-ai-bridge");
  },
  
  /**
   * Check if AI Bridge is running
   */
  isAIBridgeRunning: async (): Promise<boolean> => {
    return await ipcRenderer.invoke("is-ai-bridge-running");
  },
  
  /**
   * Start AI Bridge
   */
  startAIBridge: async (): Promise<{success: boolean, message: string}> => {
    return await ipcRenderer.invoke("start-ai-bridge");
  },
  
  /**
   * Stop AI Bridge
   */
  stopAIBridge: async (): Promise<{success: boolean, message: string}> => {
    return await ipcRenderer.invoke("stop-ai-bridge");
  },
  
  /**
   * Update AI model
   */
  updateAIModel: async (model: string): Promise<boolean> => {
    return await ipcRenderer.invoke("update-ai-model", model);
  },
  
  /**
   * Minimize the window
   */
  minimizeWindow: (): void => {
    ipcRenderer.send("minimize-window");
  },
  
  /**
   * Close the window
   */
  closeWindow: (): void => {
    ipcRenderer.send("close-window");
  },
  
  /**
   * Open a URL in the default browser
   */
  openExternal: async (url: string): Promise<boolean> => {
    return await ipcRenderer.invoke("open-external-url", url);
  }
};

contextBridge.exposeInMainWorld("bridge", CONTEXT_BRIDGE);
