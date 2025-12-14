// AI Bridge management module
import { AIBridge } from "../services/ai-bridge";
import { 
  type AIProvider, 
  type AIBridgeResult,
  createLogger,
  getErrorMessage 
} from "../../shared";

const log = createLogger('AIBridgeManager');

export class AIBridgeManager {
  private aiBridge: AIBridge | null = null;

  public startBridge(apiKey: string, provider: AIProvider, model: string): AIBridgeResult {
    try {
      if (this.aiBridge) {
        this.stopBridge();
      }
      
      // Ollama doesn't require an API key (it's a local service)
      const requiresApiKey = provider !== 'ollama';
      if (requiresApiKey && !apiKey) {
        log.warn("Cannot start AI Bridge: API key not set");
        return { success: false, message: "API key not set" };
      }
      
      this.aiBridge = new AIBridge(apiKey, provider, model);
      this.aiBridge.start();
      
      return { success: true, message: "AI Bridge started successfully" };
    } catch (error) {
      log.error("Failed to start AI Bridge:", getErrorMessage(error));
      return { success: false, message: `Failed to start AI Bridge: ${getErrorMessage(error)}` };
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
      log.error("Failed to stop AI Bridge:", getErrorMessage(error));
      return { success: false, message: `Failed to stop AI Bridge: ${getErrorMessage(error)}` };
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
    return this.aiBridge !== null && this.aiBridge.isActive();
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
