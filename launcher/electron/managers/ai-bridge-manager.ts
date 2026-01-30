// AI Bridge management module
import { AIBridge, type Player2Status, type Player2StatusCallback } from "../services/ai-bridge";
import { 
  type AIProvider, 
  type AIBridgeResult,
  createLogger,
  getErrorMessage 
} from "../../shared";

const log = createLogger('AIBridgeManager');

export class AIBridgeManager {
  private aiBridge: AIBridge | null = null;
  private player2StatusCallback: Player2StatusCallback | null = null;

  public startBridge(apiKey: string, provider: AIProvider, model: string): AIBridgeResult {
    try {
      if (this.aiBridge) {
        this.stopBridge();
      }
      
      // Ollama and Player2 don't require an API key (they are local services)
      const requiresApiKey = provider !== 'ollama' && provider !== 'player2';
      if (requiresApiKey && !apiKey) {
        log.warn("Cannot start AI Bridge: API key not set");
        return { success: false, message: "API key not set" };
      }
      
      this.aiBridge = new AIBridge(apiKey, provider, model);
      
      // Set up Player2 status callback if one is registered
      if (this.player2StatusCallback) {
        this.aiBridge.setPlayer2StatusCallback(this.player2StatusCallback);
      }
      
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

  /**
   * Set callback for Player2 status changes
   */
  public setPlayer2StatusCallback(callback: Player2StatusCallback | null): void {
    this.player2StatusCallback = callback;
    if (this.aiBridge) {
      this.aiBridge.setPlayer2StatusCallback(callback);
    }
  }

  /**
   * Get current Player2 status
   */
  public getPlayer2Status(): Player2Status {
    if (this.aiBridge) {
      return this.aiBridge.getPlayer2Status();
    }
    return 'disconnected';
  }
}
