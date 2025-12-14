// IPC handlers module - separates business logic from IPC communication
import { app, ipcMain, dialog, BrowserWindow, shell } from "electron";
import { ConfigManager } from "../managers/config-manager";
import { FactorioManager } from "../managers/factorio-manager";
import { AIBridgeManager } from "../managers/ai-bridge-manager";
import { type Config, createLogger, getErrorMessage } from "../../shared";

const log = createLogger('IPCHandlers');

export class IPCHandlers {
  private configManager: ConfigManager;
  private factorioManager: FactorioManager;
  private aiBridgeManager: AIBridgeManager;
  private mainWindow: BrowserWindow;

  constructor(
    configManager: ConfigManager,
    factorioManager: FactorioManager,
    aiBridgeManager: AIBridgeManager,
    mainWindow: BrowserWindow
  ) {
    this.configManager = configManager;
    this.factorioManager = factorioManager;
    this.aiBridgeManager = aiBridgeManager;
    this.mainWindow = mainWindow;
    
    this.registerHandlers();
  }

  private registerHandlers(): void {
    // Config management handlers
    ipcMain.handle("get-config", () => {
      const config = this.configManager.getConfig();
      log.debug("Frontend requesting config");
      return config;
    });

    ipcMain.handle("save-config", (_, newConfig: Config) => {
      log.debug("Saving config from frontend");
      this.configManager.updateConfig(newConfig);
      return true;
    });

    // Factorio path management
    ipcMain.handle("browse-factorio-path", async () => {
      const result = await dialog.showOpenDialog(this.mainWindow, {
        title: "Select Factorio Executable",
        filters: [
          { name: "Executables", extensions: ["exe"] }
        ],
        properties: ["openFile"]
      });
      
      const selectedPath = result.filePaths[0];
      if (!result.canceled && selectedPath) {
        this.configManager.setFactorioPath(selectedPath);
        return selectedPath;
      }
      
      return null;
    });

    ipcMain.handle("auto-detect-factorio", async () => {
      const foundPaths = await this.factorioManager.findFactorioExecutable();
      const firstPath = foundPaths[0];
      if (firstPath) {
        this.configManager.setFactorioPath(firstPath);
        return firstPath;
      }
      return null;
    });

    // Factorio process management
    ipcMain.handle("launch-factorio", async () => {
      const config = this.configManager.getConfig();
      if (!config.factorioPath) {
        return { success: false, message: "Factorio path not configured" };
      }
      return await this.factorioManager.launchFactorio(config.factorioPath, config.udpPort);
    });

    ipcMain.handle("is-factorio-running", async () => {
      return await this.factorioManager.isFactorioRunning();
    });

    // AI Bridge management handlers
    ipcMain.handle("toggle-ai-bridge", () => {
      const config = this.configManager.getConfig();
      const apiKey = this.configManager.getCurrentProviderApiKey();
      
      if (!apiKey) {
        return { success: false, message: "API key not configured" };
      }

      const result = this.aiBridgeManager.toggleBridge(
        apiKey,
        config.aiProvider,
        config.aiModel
      );
      
      this.configManager.setAiBridgeEnabled(result.success && this.aiBridgeManager.isActive());
      return result;
    });

    ipcMain.handle("is-ai-bridge-running", () => {
      return this.aiBridgeManager.isActive();
    });

    ipcMain.handle("start-ai-bridge", () => {
      const config = this.configManager.getConfig();
      const apiKey = this.configManager.getCurrentProviderApiKey();
      
      // Ollama doesn't require an API key (it's a local service)
      const requiresApiKey = config.aiProvider !== 'ollama';
      if (requiresApiKey && !apiKey) {
        return { success: false, message: "API key not configured" };
      }

      const result = this.aiBridgeManager.startBridge(
        apiKey,
        config.aiProvider,
        config.aiModel
      );
      
      this.configManager.setAiBridgeEnabled(result.success);
      return result;
    });

    ipcMain.handle("stop-ai-bridge", () => {
      const result = this.aiBridgeManager.stopBridge();
      this.configManager.setAiBridgeEnabled(false);
      return result;
    });

    ipcMain.handle("update-ai-model", (_, model: string) => {
      this.configManager.updateAiModel(model);
      this.aiBridgeManager.updateModel(model);
      return true;
    });

    // System info handlers
    ipcMain.handle("get-version", (_, key: "electron" | "node" | "app") => {
      if (key === "app") {
        return app.getVersion();
      }
      return String(process.versions[key]);
    });

    // Window control handlers
    ipcMain.on("minimize-window", () => {
      if (this.mainWindow) {
        this.mainWindow.minimize();
      }
    });

    ipcMain.on("close-window", () => {
      if (this.mainWindow) {
        this.mainWindow.close();
      }
    });
    
    // External URL handler
    ipcMain.handle("open-external-url", async (_, url: string) => {
      try {
        await shell.openExternal(url);
        return true;
      } catch (error) {
        log.error("Failed to open external URL:", getErrorMessage(error));
        return false;
      }
    });
  }
}
