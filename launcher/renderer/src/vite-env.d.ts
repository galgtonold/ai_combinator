/// <reference types="svelte" />
/// <reference types="vite/client" />

interface Window {
  bridge: {
    getVersion: (opt: "electron" | "node") => Promise<string>;
    getConfig: () => Promise<any>;
    saveConfig: (config: any) => Promise<boolean>;
    browseFactorioPath: () => Promise<string | null>;
    autoDetectFactorio: () => Promise<string | null>;
    launchFactorio: () => Promise<{success: boolean, message: string}>;
    isFactorioRunning: () => Promise<boolean>;
    onFactorioStatusUpdate: (callback: (data: {status: string, error?: boolean}) => void) => () => void;
    toggleAIBridge: () => Promise<{success: boolean, message: string}>;
    isAIBridgeRunning: () => Promise<boolean>;
    startAIBridge: () => Promise<{success: boolean, message: string}>;
    stopAIBridge: () => Promise<{success: boolean, message: string}>;
    updateAIModel: (model: string) => Promise<boolean>;
    minimizeWindow: () => void;
    closeWindow: () => void;
    openExternal: (url: string) => Promise<boolean>;
  }
}