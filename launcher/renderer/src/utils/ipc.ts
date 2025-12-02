import type { ContextBridge } from "@shared";

// Re-export shared types for use in the renderer
export type { AIProvider, Config, FactorioStatus, ContextBridge } from "@shared";

declare global {
  interface Window {
    bridge: ContextBridge;
  }
}

const ipc = window.bridge;
export default ipc;
