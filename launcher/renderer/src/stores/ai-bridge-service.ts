import ipc from "../utils/ipc";
import { config, configService } from "./config-store";
import { statusService } from "./status-store";
import { get } from 'svelte/store';
import { AI_BRIDGE_RESTART_DELAY, getErrorMessage } from "@shared";

/**
 * AI Bridge management service
 */
export class AIBridgeService {
  /**
   * Check if the current provider requires an API key
   */
  private requiresApiKey(provider: string): boolean {
    return provider !== 'ollama';
  }

  /**
   * Manage AI Bridge based on configuration
   */
  async manageAIBridge(): Promise<void> {
    const currentConfig = get(config);
    const currentApiKey = configService.getCurrentProviderApiKey(currentConfig);
    const needsApiKey = this.requiresApiKey(currentConfig.aiProvider);
    const shouldBeRunning = currentConfig.aiBridgeEnabled && (!needsApiKey || currentApiKey);
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
    const currentConfig = get(config);
    const currentApiKey = configService.getCurrentProviderApiKey(currentConfig);
    const needsApiKey = this.requiresApiKey(currentConfig.aiProvider);
    if (needsApiKey && !currentApiKey) {
      statusService.setStatus("API key is required", "error");
      return;
    }

    try {
      const result = await ipc.startAIBridge();
      if (result.success) {
        statusService.setStatus("AI Bridge started automatically", "success");
      } else {
        statusService.setStatus(result.message, "error");
      }
    } catch (error) {
      statusService.setStatus(`Error starting AI Bridge: ${getErrorMessage(error)}`, "error");
    }
  }

  /**
   * Stop the AI Bridge
   */
  async stopAIBridge(): Promise<void> {
    try {
      const result = await ipc.stopAIBridge();
      if (result.success) {
        statusService.setStatus("AI Bridge stopped", "success");
      } else {
        statusService.setStatus(result.message, "error");
      }
    } catch (error) {
      statusService.setStatus(`Error stopping AI Bridge: ${getErrorMessage(error)}`, "error");
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
    }, AI_BRIDGE_RESTART_DELAY);
  }

  /**
   * Update the AI model
   */
  async updateAIModel(): Promise<void> {
    try {
      const currentConfig = get(config);
      await ipc.updateAIModel(currentConfig.aiModel);
      statusService.setStatus("AI model updated successfully", "success");
    } catch (error) {
      statusService.setStatus(`Error updating AI model: ${getErrorMessage(error)}`, "error");
    }
  }
}

// Create and export a singleton instance
export const aiBridgeService = new AIBridgeService();
