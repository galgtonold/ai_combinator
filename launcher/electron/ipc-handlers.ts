// IPC handlers module - separates business logic from IPC communication
import { ipcMain, dialog, BrowserWindow, app } from "electron";
import { ConfigManager, Config } from "./config-manager";
import { FactorioManager } from "./factorio-manager";
import { AIBridgeManager } from "./ai-bridge-manager";

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
      console.log("Frontend requesting config:", JSON.stringify(config, null, 2));
      return config;
    });

    ipcMain.handle("save-config", (_, newConfig: Config) => {
      console.log("Saving config from frontend:", JSON.stringify(newConfig, null, 2));
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
      
      if (!result.canceled && result.filePaths.length > 0) {
        this.configManager.setFactorioPath(result.filePaths[0]);
        return result.filePaths[0];
      }
      
      return null;
    });

    ipcMain.handle("auto-detect-factorio", async () => {
      const foundPaths = await this.factorioManager.findFactorioExecutable();
      if (foundPaths.length > 0) {
        this.configManager.setFactorioPath(foundPaths[0]);
        return foundPaths[0];
      }
      return null;
    });

    // Factorio process management
    ipcMain.handle("launch-factorio", async () => {
      const config = this.configManager.getConfig();
      return await this.factorioManager.launchFactorio(config.factorioPath, config.udpPort);
    });

    ipcMain.handle("is-factorio-running", async () => {
      return await this.factorioManager.isFactorioRunning();
    });

    // AI Bridge management handlers
    ipcMain.handle("toggle-ai-bridge", async () => {
      const config = this.configManager.getConfig();
      const result = this.aiBridgeManager.toggleBridge(
        this.configManager.getCurrentProviderApiKey(),
        config.aiProvider,
        config.aiModel
      );
      
      this.configManager.setAiBridgeEnabled(result.success && this.aiBridgeManager.isActive());
      return result;
    });

    ipcMain.handle("is-ai-bridge-running", () => {
      return this.aiBridgeManager.isActive();
    });

    ipcMain.handle("start-ai-bridge", async () => {
      const config = this.configManager.getConfig();
      const result = this.aiBridgeManager.startBridge(
        this.configManager.getCurrentProviderApiKey(),
        config.aiProvider,
        config.aiModel
      );
      
      this.configManager.setAiBridgeEnabled(result.success);
      return result;
    });

    ipcMain.handle("stop-ai-bridge", async () => {
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
    ipcMain.handle("get-version", (_, key: "electron" | "node") => {
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
  }
}
