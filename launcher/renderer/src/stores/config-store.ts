import type { Config } from "../utils/ipc";
import ipc from "../utils/ipc";

/**
 * Configuration store for managing app settings
 */
export class ConfigStore {
  private _config: Config = $state({
    factorioPath: "",
    openAIKey: "", // Deprecated - kept for migration
    aiBridgeEnabled: false,
    aiProvider: "openai",
    aiModel: "gpt-4",
    udpPort: 9001,
    providerApiKeys: {},
  });

  get config(): Config {
    return this._config;
  }

  /**
   * Load configuration from the backend
   */
  async loadConfig(): Promise<void> {
    try {
      const loadedConfig = await ipc.getConfig();
      console.log("Received config from backend:", loadedConfig);

      // Ensure all properties are present with defaults
      this._config = {
        factorioPath: loadedConfig.factorioPath || "",
        openAIKey: loadedConfig.openAIKey || "", // Deprecated
        aiBridgeEnabled: false, // Will be set below based on provider API key
        aiProvider: (loadedConfig as any).aiProvider || "openai",
        aiModel: loadedConfig.aiModel || "gpt-4",
        udpPort: loadedConfig.udpPort || 9001,
        providerApiKeys: (loadedConfig as any).providerApiKeys || {},
      };

      console.log("Frontend config after loading:", this._config);

      // Migration: Move old openAIKey to provider-specific key if needed
      if (loadedConfig.openAIKey && !this._config.providerApiKeys.openai) {
        this._config.providerApiKeys.openai = loadedConfig.openAIKey;
        console.log("Migrated old OpenAI key to providerApiKeys");
      }

      // Update AI bridge enabled status based on current provider's API key
      this._config.aiBridgeEnabled = !!this.getCurrentProviderApiKey();
    } catch (error) {
      console.error("Failed to load config:", error);
      throw error;
    }
  }

  /**
   * Save configuration to the backend
   */
  async saveConfig(): Promise<void> {
    console.log("Saving config:", this._config);
    try {
      // Auto-enable AI bridge if current provider has API key
      this._config.aiBridgeEnabled = !!this.getCurrentProviderApiKey();

      // Ensure providerApiKeys is properly initialized
      if (!this._config.providerApiKeys) {
        this._config.providerApiKeys = {};
      }

      // Create a plain object with all the properties we need to save
      const configToSave = {
        factorioPath: this._config.factorioPath,
        openAIKey: this._config.openAIKey, // Keep for backward compatibility
        aiBridgeEnabled: this._config.aiBridgeEnabled,
        aiProvider: this._config.aiProvider,
        aiModel: this._config.aiModel,
        udpPort: this._config.udpPort,
        providerApiKeys: { ...this._config.providerApiKeys }, // Ensure it's a proper object copy
      };

      console.log("Sending config to backend:", configToSave);
      console.log("providerApiKeys being sent:", configToSave.providerApiKeys);
      await ipc.saveConfig(configToSave);
    } catch (error) {
      console.error("Failed to save config:", error);
      throw error;
    }
  }

  /**
   * Update a specific config property
   */
  updateConfig(updates: Partial<Config>): void {
    this._config = { ...this._config, ...updates };
  }

  /**
   * Get the API key for the current provider
   */
  getCurrentProviderApiKey(): string {
    if (!this._config.providerApiKeys) {
      this._config.providerApiKeys = {};
    }
    return this._config.providerApiKeys[this._config.aiProvider] || "";
  }

  /**
   * Set the API key for the current provider
   */
  setCurrentProviderApiKey(apiKey: string): void {
    console.log(
      `Setting API key for provider ${this._config.aiProvider}:`,
      apiKey ? "[REDACTED]" : "empty",
    );
    if (!this._config.providerApiKeys) {
      this._config.providerApiKeys = {};
      console.log("Initialized empty providerApiKeys object");
    }
    this._config.providerApiKeys[this._config.aiProvider] = apiKey;
    console.log("Updated providerApiKeys:", Object.keys(this._config.providerApiKeys));
  }
}

// Create and export a singleton instance
export const configStore = new ConfigStore();
