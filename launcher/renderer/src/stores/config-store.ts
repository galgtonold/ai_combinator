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
  providerModels: {},
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
        providerModels: loadedConfig.providerModels || {},
      };

      // Set the model from providerModels if available for current provider
      const savedModel = newConfig.providerModels[newConfig.aiProvider];
      if (savedModel) {
        newConfig.aiModel = savedModel;
      }

      // Update AI bridge enabled status based on current provider's API key
      // Ollama and Player2 don't require an API key (they are local services)
      const requiresApiKey = newConfig.aiProvider !== 'ollama' && newConfig.aiProvider !== 'player2';
      newConfig.aiBridgeEnabled = !requiresApiKey || !!this.getCurrentProviderApiKey(newConfig);

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
      // Auto-enable AI bridge if current provider has API key (or is Ollama/Player2 which don't need one)
      const requiresApiKey = configValue.aiProvider !== 'ollama' && configValue.aiProvider !== 'player2';
      configValue.aiBridgeEnabled = !requiresApiKey || !!this.getCurrentProviderApiKey(configValue);

      // Ensure providerApiKeys and providerModels are properly initialized
      if (!configValue.providerApiKeys) {
        configValue.providerApiKeys = {};
      }
      if (!configValue.providerModels) {
        configValue.providerModels = {};
      }

      // Save the current model to providerModels for the current provider
      configValue.providerModels[configValue.aiProvider] = configValue.aiModel;

      // Create a plain object with all the properties we need to save
      const configToSave = {
        factorioPath: configValue.factorioPath,
        aiBridgeEnabled: configValue.aiBridgeEnabled,
        aiProvider: configValue.aiProvider,
        aiModel: configValue.aiModel,
        udpPort: configValue.udpPort,
        providerApiKeys: { ...configValue.providerApiKeys },
        providerModels: { ...configValue.providerModels },
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

  /**
   * Get the saved model for a specific provider
   */
  getProviderModel(configValue: Config, provider: string): string | undefined {
    if (!configValue.providerModels) {
      return undefined;
    }
    return configValue.providerModels[provider as keyof typeof configValue.providerModels];
  }

  /**
   * Set the model for a specific provider
   */
  setProviderModel(configValue: Config, provider: string, model: string): Config {
    if (!configValue.providerModels) {
      configValue.providerModels = {};
    }
    
    return {
      ...configValue,
      providerModels: {
        ...configValue.providerModels,
        [provider]: model
      }
    };
  }
}

// Create and export a singleton instance
export const configService = new ConfigService();
