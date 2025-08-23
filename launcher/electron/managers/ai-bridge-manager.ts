// AI Bridge management module
import { AIBridge } from "../services/ai-bridge";
import { AIProvider } from "./config-manager";

export interface AIBridgeResult {
  success: boolean;
  message: string;
}

export class AIBridgeManager {
  private aiBridge: AIBridge | null = null;

  public startBridge(apiKey: string, provider: AIProvider, model: string): AIBridgeResult {
    try {
      if (this.aiBridge) {
        this.stopBridge();
      }
      
      if (!apiKey) {
        console.error("Cannot start AI Bridge: API key not set");
        return { success: false, message: "API key not set" };
      }
      
      this.aiBridge = new AIBridge(apiKey, provider, model);
      this.aiBridge.start();
      
      return { success: true, message: "AI Bridge started successfully" };
    } catch (error) {
      console.error("Failed to start AI Bridge:", error);
      return { success: false, message: `Failed to start AI Bridge: ${error.message}` };
    }
  }

  public stopBridge(): AIBridgeResult {
    try {
      if (this.aiBridge) {
        this.aiBridge.stop();
        this.aiBridge = null;
        return { success: true, message: "AI Bridge stopped successfully" };
      }
      return { success: false, message: "AI Bridge is not running" };
    } catch (error) {
      console.error("Failed to stop AI Bridge:", error);
      return { success: false, message: `Failed to stop AI Bridge: ${error.message}` };
    }
  }

  public toggleBridge(apiKey: string, provider: AIProvider, model: string): AIBridgeResult {
    if (this.isActive()) {
      return this.stopBridge();
    } else {
      return this.startBridge(apiKey, provider, model);
    }
  }

  public isActive(): boolean {
    return this.aiBridge && this.aiBridge.isActive();
  }

  public updateModel(model: string): boolean {
    if (this.aiBridge) {
      this.aiBridge.updateModel(model);
      return true;
    }
    return false;
  }

  public updateApiKey(apiKey: string): boolean {
    if (this.aiBridge) {
      this.aiBridge.updateApiKey(apiKey);
      return true;
    }
    return false;
  }
}
