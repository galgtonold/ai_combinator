import { writable } from 'svelte/store';
import type { Config } from "../utils/ipc";
import ipc from "../utils/ipc";
import { DEFAULT_AI_PROVIDER, DEFAULT_AI_MODEL, DEFAULT_UDP_PORT } from "@shared";

// Create reactive config store
const initialConfig: Config = {
  factorioPath: "",
  aiBridgeEnabled: false,
  aiProvider: DEFAULT_AI_PROVIDER,
  aiModel: DEFAULT_AI_MODEL,
  udpPort: DEFAULT_UDP_PORT,
  providerApiKeys: {},
};

export const config = writable<Config>(initialConfig);

/**
 * Configuration service for managing app settings
 */
export class ConfigService {
  /**
   * Load configuration from the backend
   */
  async loadConfig(): Promise<void> {
    try {
      const loadedConfig = await ipc.getConfig();

      // Ensure all properties are present with defaults
      const newConfig: Config = {
        factorioPath: loadedConfig.factorioPath || "",
        aiBridgeEnabled: false, // Will be set below based on provider API key
        aiProvider: loadedConfig.aiProvider || DEFAULT_AI_PROVIDER,
        aiModel: loadedConfig.aiModel || DEFAULT_AI_MODEL,
        udpPort: loadedConfig.udpPort || DEFAULT_UDP_PORT,
        providerApiKeys: loadedConfig.providerApiKeys || {},
      };

      // Update AI bridge enabled status based on current provider's API key
      newConfig.aiBridgeEnabled = !!this.getCurrentProviderApiKey(newConfig);

      config.set(newConfig);
    } catch (error) {
      console.error("Failed to load config:", error);
      throw error;
    }
  }

  /**
   * Save configuration to the backend
   */
  async saveConfig(configValue: Config): Promise<void> {
    try {
      // Auto-enable AI bridge if current provider has API key
      configValue.aiBridgeEnabled = !!this.getCurrentProviderApiKey(configValue);

      // Ensure providerApiKeys is properly initialized
      if (!configValue.providerApiKeys) {
        configValue.providerApiKeys = {};
      }

      // Create a plain object with all the properties we need to save
      const configToSave = {
        factorioPath: configValue.factorioPath,
        aiBridgeEnabled: configValue.aiBridgeEnabled,
        aiProvider: configValue.aiProvider,
        aiModel: configValue.aiModel,
        udpPort: configValue.udpPort,
        providerApiKeys: { ...configValue.providerApiKeys },
      };

      await ipc.saveConfig(configToSave);
      
      // Update the store with the saved config
      config.set(configValue);
    } catch (error) {
      console.error("Failed to save config:", error);
      throw error;
    }
  }

  /**
   * Update a specific config property
   */
  updateConfig(updates: Partial<Config>): void {
    config.update(current => ({ ...current, ...updates }));
  }

  /**
   * Get the API key for the current provider
   */
  getCurrentProviderApiKey(configValue: Config): string {
    if (!configValue.providerApiKeys) {
      configValue.providerApiKeys = {};
    }
    return configValue.providerApiKeys[configValue.aiProvider] || "";
  }

  /**
   * Set the API key for the current provider
   */
  setCurrentProviderApiKey(configValue: Config, apiKey: string): Config {
    if (!configValue.providerApiKeys) {
      configValue.providerApiKeys = {};
    }
    
    return {
      ...configValue,
      providerApiKeys: {
        ...configValue.providerApiKeys,
        [configValue.aiProvider]: apiKey
      }
    };
  }
}

// Create and export a singleton instance
export const configService = new ConfigService();
