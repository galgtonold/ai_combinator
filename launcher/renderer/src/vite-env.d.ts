/// <reference types="svelte" />
/// <reference types="vite/client" />

import type { Config, AIBridgeResult, LaunchResult } from "@shared";

interface Window {
  bridge: {
    getVersion: (opt: "electron" | "node") => Promise<string>;
    getConfig: () => Promise<Config>;
    saveConfig: (config: Config) => Promise<boolean>;
    browseFactorioPath: () => Promise<string | null>;
    autoDetectFactorio: () => Promise<string | null>;
    launchFactorio: () => Promise<LaunchResult>;
    isFactorioRunning: () => Promise<boolean>;
    onFactorioStatusUpdate: (callback: (data: {status: string, error?: boolean}) => void) => () => void;
    toggleAIBridge: () => Promise<AIBridgeResult>;
    isAIBridgeRunning: () => Promise<boolean>;
    startAIBridge: () => Promise<AIBridgeResult>;
    stopAIBridge: () => Promise<AIBridgeResult>;
    updateAIModel: (model: string) => Promise<boolean>;
    minimizeWindow: () => void;
    closeWindow: () => void;
    openExternal: (url: string) => Promise<boolean>;
  }
}