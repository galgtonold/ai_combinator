// Configuration management module
import { app } from "electron";
import { join } from "path";
import { existsSync, readFileSync, writeFileSync } from "fs";
import { 
  type Config, 
  DEFAULT_AI_PROVIDER, 
  DEFAULT_AI_MODEL, 
  DEFAULT_UDP_PORT,
  createLogger,
  getErrorMessage
} from "../../shared";

const log = createLogger('ConfigManager');

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
      aiBridgeEnabled: false,
      aiProvider: DEFAULT_AI_PROVIDER,
      aiModel: DEFAULT_AI_MODEL,
      udpPort: DEFAULT_UDP_PORT,
      providerApiKeys: {},
      providerModels: {}
    };
  }

  public loadConfig(): void {
    try {
      if (existsSync(this.configPath)) {
        const loadedConfig = JSON.parse(readFileSync(this.configPath, 'utf8'));
        log.debug("Loading config from disk");
        
        // Properly merge config with special handling for nested objects
        this.config = {
          ...this.config,
          ...loadedConfig,
          // Ensure providerApiKeys is properly preserved/merged
          providerApiKeys: {
            ...this.config.providerApiKeys,
            ...(loadedConfig.providerApiKeys || {})
          },
          // Ensure providerModels is properly preserved/merged
          providerModels: {
            ...this.config.providerModels,
            ...(loadedConfig.providerModels || {})
          }
        };
        
        this.migrateConfig();
        log.debug("Config loaded successfully");
        this.saveConfig(); // Save the migrated config
      }
    } catch (error) {
      log.error("Failed to load config:", getErrorMessage(error));
    }
  }

  private migrateConfig(): void {
    // Migration: Set default provider if not present
    if (!this.config.aiProvider) {
      this.config.aiProvider = DEFAULT_AI_PROVIDER;
    }
  }

  public saveConfig(): void {
    try {
      const configToSave = JSON.stringify(this.config, null, 2);
      writeFileSync(this.configPath, configToSave);
      log.debug(`Config saved to: ${this.configPath}`);
    } catch (error) {
      log.error("Failed to save config:", getErrorMessage(error));
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
