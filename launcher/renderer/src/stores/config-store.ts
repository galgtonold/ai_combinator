import { writable } from 'svelte/store';
import type { Config } from "../utils/ipc";
import ipc from "../utils/ipc";

// Create reactive config store
const initialConfig: Config = {
  factorioPath: "",
  openAIKey: "", // Deprecated - kept for migration
  aiBridgeEnabled: false,
  aiProvider: "openai",
  aiModel: "gpt-4",
  udpPort: 9001,
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
      console.log("Received config from backend:", loadedConfig);

      // Ensure all properties are present with defaults
      const newConfig: Config = {
        factorioPath: loadedConfig.factorioPath || "",
        openAIKey: loadedConfig.openAIKey || "", // Deprecated
        aiBridgeEnabled: false, // Will be set below based on provider API key
        aiProvider: (loadedConfig as any).aiProvider || "openai",
        aiModel: loadedConfig.aiModel || "gpt-4",
        udpPort: loadedConfig.udpPort || 9001,
        providerApiKeys: (loadedConfig as any).providerApiKeys || {},
      };

      console.log("Frontend config after loading:", newConfig);

      // Migration: Move old openAIKey to provider-specific key if needed
      if (loadedConfig.openAIKey && !newConfig.providerApiKeys.openai) {
        newConfig.providerApiKeys.openai = loadedConfig.openAIKey;
        console.log("Migrated old OpenAI key to providerApiKeys");
      }

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
    console.log("Saving config:", configValue);
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
        openAIKey: configValue.openAIKey, // Keep for backward compatibility
        aiBridgeEnabled: configValue.aiBridgeEnabled,
        aiProvider: configValue.aiProvider,
        aiModel: configValue.aiModel,
        udpPort: configValue.udpPort,
        providerApiKeys: { ...configValue.providerApiKeys }, // Ensure it's a proper object copy
      };

      console.log("Sending config to backend:", configToSave);
      console.log("providerApiKeys being sent:", configToSave.providerApiKeys);
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
    console.log(
      `Setting API key for provider ${configValue.aiProvider}:`,
      apiKey ? "[REDACTED]" : "empty",
    );
    if (!configValue.providerApiKeys) {
      configValue.providerApiKeys = {};
      console.log("Initialized empty providerApiKeys object");
    }
    
    const newConfig = {
      ...configValue,
      providerApiKeys: {
        ...configValue.providerApiKeys,
        [configValue.aiProvider]: apiKey
      }
    };
    
    console.log("Updated providerApiKeys:", Object.keys(newConfig.providerApiKeys));
    return newConfig;
  }
}

// Create and export a singleton instance
export const configService = new ConfigService();
