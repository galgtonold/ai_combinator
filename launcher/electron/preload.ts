import { contextBridge, ipcRenderer } from "electron";
import type { ContextBridge, FactorioStatusUpdate, LaunchResult, AIBridgeResult } from "../shared";

/**
 * Context bridge implementation exposing IPC methods to the renderer process
 * This implements the ContextBridge interface defined in shared/types.ts
 */
const bridge: ContextBridge = {
  getVersion: async (opt: "app" | "electron" | "node") => {
    return await ipcRenderer.invoke("get-version", opt);
  },

  getConfig: async () => {
    return await ipcRenderer.invoke("get-config");
  },

  saveConfig: async (config) => {
    return await ipcRenderer.invoke("save-config", config);
  },

  browseFactorioPath: async () => {
    return await ipcRenderer.invoke("browse-factorio-path");
  },

  autoDetectFactorio: async () => {
    return await ipcRenderer.invoke("auto-detect-factorio");
  },

  launchFactorio: async (): Promise<LaunchResult> => {
    return await ipcRenderer.invoke("launch-factorio");
  },
  
  isFactorioRunning: async () => {
    return await ipcRenderer.invoke("is-factorio-running");
  },
  
  onFactorioStatusUpdate: (callback: (data: FactorioStatusUpdate) => void) => {
    ipcRenderer.on('factorio-status-update', (_, data) => callback(data));
    return () => {
      ipcRenderer.removeAllListeners('factorio-status-update');
    };
  },
  
  toggleAIBridge: async (): Promise<AIBridgeResult> => {
    return await ipcRenderer.invoke("toggle-ai-bridge");
  },
  
  isAIBridgeRunning: async () => {
    return await ipcRenderer.invoke("is-ai-bridge-running");
  },
  
  startAIBridge: async (): Promise<AIBridgeResult> => {
    return await ipcRenderer.invoke("start-ai-bridge");
  },
  
  stopAIBridge: async (): Promise<AIBridgeResult> => {
    return await ipcRenderer.invoke("stop-ai-bridge");
  },
  
  updateAIModel: async (model) => {
    return await ipcRenderer.invoke("update-ai-model", model);
  },
  
  minimizeWindow: () => {
    ipcRenderer.send("minimize-window");
  },
  
  closeWindow: () => {
    ipcRenderer.send("close-window");
  },
  
  openExternal: async (url) => {
    return await ipcRenderer.invoke("open-external-url", url);
  }
};

contextBridge.exposeInMainWorld("bridge", bridge);
