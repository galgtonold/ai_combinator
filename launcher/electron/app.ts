import { app, BrowserWindow } from "electron";
import electronReload from "electron-reload";
import { join } from "path";
import { ConfigManager } from "./managers/config-manager";
import { FactorioManager } from "./managers/factorio-manager";
import { AIBridgeManager } from "./managers/ai-bridge-manager";
import { IPCHandlers } from "./services/ipc-handlers";

const { updateElectronApp } = require('update-electron-app')

let mainWindow: BrowserWindow;
let configManager: ConfigManager;
let factorioManager: FactorioManager;
let aiBridgeManager: AIBridgeManager;
let ipcHandlers: IPCHandlers;

updateElectronApp()

app.once("ready", main);

// Clean up resources when the app is about to quit
app.on("will-quit", () => {
  factorioManager?.stopStatusMonitoring();
  
  // Stop AI Bridge if running
  if (aiBridgeManager?.isActive()) {
    aiBridgeManager.stopBridge();
  }
});

async function main() {
  // Initialize managers
  configManager = new ConfigManager();
  
  // Initialize Factorio manager with status change callback
  factorioManager = new FactorioManager((status) => {
    if (mainWindow) {
      mainWindow.webContents.send('factorio-status-update', status);
    }
  });
  
  // Initialize AI Bridge manager
  aiBridgeManager = new AIBridgeManager();
  
  // If Factorio path is not set, try to find it
  const config = configManager.getConfig();
  if (!config.factorioPath) {
    const foundPaths = await factorioManager.findFactorioExecutable();
    if (foundPaths.length > 0) {
      configManager.setFactorioPath(foundPaths[0]);
    }
  }
  
  // Start AI Bridge if enabled
  if (config.aiBridgeEnabled && configManager.getCurrentProviderApiKey()) {
    aiBridgeManager.startBridge(
      configManager.getCurrentProviderApiKey(),
      config.aiProvider,
      config.aiModel
    );
  }

  mainWindow = new BrowserWindow({
    width: 600,
    height: 700,
    resizable: false,
    show: false,
    frame: false, // Remove the default frame
    thickFrame: false,
    transparent: false,
    backgroundColor: "#1e1e1e", // Match Factorio background color
    autoHideMenuBar: true, // Hide the menu bar
    webPreferences: {
      devTools: true || !app.isPackaged,
      preload: join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  // Disable LCD text and font subpixel positioning for more accurate rendering compared to Factorio
  app.commandLine.appendSwitch('disable-lcd-text');
  app.commandLine.appendSwitch('disable-font-subpixel-positioning');
  app.commandLine.appendSwitch('force-prefers-reduced-motion');
  app.commandLine.appendSwitch('disable-features', 'FontSubpixelPositioning');

  // Initialize IPC handlers after all managers are created
  ipcHandlers = new IPCHandlers(configManager, factorioManager, aiBridgeManager, mainWindow);

  mainWindow.once("ready-to-show", () => {
    mainWindow.show();
    // Start monitoring Factorio status after window is shown
    factorioManager.startStatusMonitoring();
  });

  if (app.isPackaged) {
    mainWindow.loadFile(join(__dirname, "../renderer/index.html"));
  } else {
    // Only watch our electron directory for changes, not the entire project
    electronReload(join(__dirname), {
      forceHardReset: false, // Changed to false to avoid hard resets
      hardResetMethod: "quit",
      electron: app.getPath("exe"),
      awaitWriteFinish: true, // Wait for write to finish before reloading
    });

    // Add timeout and retry logic for development server
    await loadDevelopmentURL();
  }
}

// Helper function for loading development URL with retry logic
async function loadDevelopmentURL(): Promise<void> {
  let retries = 0;
  const maxRetries = 30;
  const retryInterval = 1000; // 1 second
  
  const loadURL = async (): Promise<void> => {
    try {
      await mainWindow.loadURL('http://localhost:5173/');
      console.log('Successfully connected to Vite dev server');
    } catch (err) {
      retries++;
      if (retries <= maxRetries) {
        console.log(`Failed to connect to Vite dev server, retrying (${retries}/${maxRetries})...`);
        await new Promise(resolve => setTimeout(resolve, retryInterval));
        await loadURL();
      } else {
        console.error('Failed to connect to Vite dev server after maximum retries');
        throw err;
      }
    }
  };
  
  await loadURL();
}
