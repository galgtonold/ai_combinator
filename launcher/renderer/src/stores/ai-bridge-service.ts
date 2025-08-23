import ipc from "../utils/ipc";
import { configStore } from "./config-store";
import { statusStore } from "./status-store";

/**
 * AI Bridge management service
 */
export class AIBridgeService {
  /**
   * Manage AI Bridge based on configuration
   */
  async manageAIBridge(): Promise<void> {
    const currentApiKey = configStore.getCurrentProviderApiKey();
    const shouldBeRunning = currentApiKey && configStore.config.aiBridgeEnabled;
    const isCurrentlyRunning = await ipc.isAIBridgeRunning();

    if (shouldBeRunning && !isCurrentlyRunning) {
      await this.startAIBridge();
    } else if (!shouldBeRunning && isCurrentlyRunning) {
      await this.stopAIBridge();
    }
  }

  /**
   * Start the AI Bridge
   */
  async startAIBridge(): Promise<void> {
    const currentApiKey = configStore.getCurrentProviderApiKey();
    if (!currentApiKey) {
      statusStore.setStatus("API key is required", "error");
      return;
    }

    try {
      const result = await ipc.startAIBridge();
      if (result.success) {
        statusStore.setStatus("AI Bridge started automatically", "success");
      } else {
        statusStore.setStatus(result.message, "error");
      }
    } catch (error) {
      statusStore.setStatus(`Error starting AI Bridge: ${error}`, "error");
    }
  }

  /**
   * Stop the AI Bridge
   */
  async stopAIBridge(): Promise<void> {
    try {
      const result = await ipc.stopAIBridge();
      if (result.success) {
        statusStore.setStatus("AI Bridge stopped", "success");
      } else {
        statusStore.setStatus(result.message, "error");
      }
    } catch (error) {
      statusStore.setStatus(`Error stopping AI Bridge: ${error}`, "error");
    }
  }

  /**
   * Restart the AI Bridge
   */
  async restartAIBridge(): Promise<void> {
    await this.stopAIBridge();
    // Small delay to ensure clean shutdown
    setTimeout(async () => {
      await this.startAIBridge();
    }, 500);
  }

  /**
   * Update the AI model
   */
  async updateAIModel(): Promise<void> {
    try {
      await ipc.updateAIModel(configStore.config.aiModel);
      statusStore.setStatus("AI model updated successfully", "success");
    } catch (error) {
      statusStore.setStatus(`Error updating AI model: ${error}`, "error");
    }
  }
}

// Create and export a singleton instance
export const aiBridgeService = new AIBridgeService();
