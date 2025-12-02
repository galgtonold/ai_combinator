import type { CONTEXT_BRIDGE } from "../../electron/preload";

declare global {
  interface Window {
    bridge: typeof CONTEXT_BRIDGE;
  }
}

// Re-export shared types for use in the renderer
export type { AIProvider, Config, FactorioStatus } from "@shared";

const ipc = window.bridge;
export default ipc;
