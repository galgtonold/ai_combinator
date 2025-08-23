// Configuration management module
import { app } from "electron";
import { join } from "path";
import { existsSync, readFileSync, writeFileSync } from "fs";

export type AIProvider = 'openai' | 'anthropic' | 'google' | 'xai' | 'deepseek';

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

export class ConfigManager {
  private configPath: string;
  private config: Config;

  constructor() {
    this.configPath = join(app.getPath("userData"), "config.json");
    this.config = this.getDefaultConfig();
    this.loadConfig();
  }

  private getDefaultConfig(): Config {
    return {
      factorioPath: "",
      openAIKey: "",
      aiBridgeEnabled: false,
      aiProvider: "openai",
      aiModel: "gpt-4",
      udpPort: 9001,
      providerApiKeys: {}
    };
  }

  public loadConfig(): void {
    try {
      if (existsSync(this.configPath)) {
        const loadedConfig = JSON.parse(readFileSync(this.configPath, 'utf8'));
        console.log("Loading config from disk:", JSON.stringify(loadedConfig, null, 2));
        
        // Properly merge config with special handling for nested objects
        this.config = {
          ...this.config,
          ...loadedConfig,
          // Ensure providerApiKeys is properly preserved/merged
          providerApiKeys: {
            ...this.config.providerApiKeys,
            ...(loadedConfig.providerApiKeys || {})
          }
        };
        
        this.migrateConfig();
        console.log("Final loaded config:", JSON.stringify(this.config, null, 2));
        this.saveConfig(); // Save the migrated config
      }
    } catch (error) {
      console.error("Failed to load config:", error);
    }
  }

  private migrateConfig(): void {
    // Migration: Set default provider if not present
    if (!this.config.aiProvider) {
      this.config.aiProvider = "openai" as AIProvider;
    }
    
    // Migration: Move old openAIKey to provider-specific key
    if (this.config.openAIKey && !this.config.providerApiKeys.openai) {
      this.config.providerApiKeys.openai = this.config.openAIKey;
      // Keep the old key for backward compatibility but it will be deprecated
    }
  }

  public saveConfig(): void {
    try {
      const configToSave = JSON.stringify(this.config, null, 2);
      console.log("Writing config to file:", configToSave);
      writeFileSync(this.configPath, configToSave);
      console.log(`Config saved to: ${this.configPath}`);
    } catch (error) {
      console.error("Failed to save config:", error);
    }
  }

  public getConfig(): Config {
    return { ...this.config }; // Return a copy to prevent external mutations
  }

  public updateConfig(newConfig: Partial<Config>): void {
    this.config = {
      ...this.config,
      ...newConfig,
      // Ensure providerApiKeys is properly merged
      providerApiKeys: {
        ...this.config.providerApiKeys,
        ...(newConfig.providerApiKeys || {})
      }
    };
    this.saveConfig();
  }

  public getCurrentProviderApiKey(): string {
    return this.config.providerApiKeys[this.config.aiProvider] || "";
  }

  public setFactorioPath(path: string): void {
    this.config.factorioPath = path;
    this.saveConfig();
  }

  public setAiBridgeEnabled(enabled: boolean): void {
    this.config.aiBridgeEnabled = enabled;
    this.saveConfig();
  }

  public updateAiModel(model: string): void {
    this.config.aiModel = model;
    this.saveConfig();
  }
}
