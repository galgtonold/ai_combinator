import ipc from "../utils/ipc";
import type { FactorioStatusUpdate, Player2StatusUpdate } from "@shared";
import { config, configService, status, statusService, aiBridgeService, factorioService } from "../stores";
import { get } from 'svelte/store';

/**
 * Composable for handling application initialization and reactive effects
 */
export function useAppEffects() {
  let unsubscribeFactorioStatusUpdate: (() => void) | null = null;
  let unsubscribePlayer2StatusUpdate: (() => void) | null = null;
  
  // Track previous values for change detection
  let previousProvider: string | null = null;
  let previousModel: string | null = null;
  let previousApiKey: string = "";

  /**
   * Initialize the application
   */
  async function initialize(): Promise<void> {
    await configService.loadConfig();
    await factorioService.checkFactorioStatus();
    setupStatusListeners();
    
    // Initialize tracking variables
    const currentConfig = get(config);
    previousApiKey = configService.getCurrentProviderApiKey(currentConfig);
    previousProvider = currentConfig.aiProvider;
    previousModel = currentConfig.aiModel;
    
    // Get initial Player2 status if using Player2
    if (currentConfig.aiProvider === 'player2') {
      const player2Status = await ipc.getPlayer2Status();
      statusService.setPlayer2Status(player2Status);
    }
  }

  /**
   * Setup status listeners for Factorio and Player2 updates
   */
  function setupStatusListeners(): void {
    // Factorio status listener
    unsubscribeFactorioStatusUpdate = ipc.onFactorioStatusUpdate((data: FactorioStatusUpdate) => {
      if (data.status === "running") {
        statusService.setFactorioStatus("running");
      } else if (data.status === "stopped") {
        statusService.setFactorioStatus("stopped");

        // Only show closure message if Factorio was previously running
        const currentStatus = get(status);
        if (data.error) {
          statusService.setStatus("Factorio terminated with an error", "error");
        } else if (currentStatus.wasRunning) {
          // Only show "Factorio was closed" if it was actually running before
          statusService.setStatus("Factorio was closed", "success");
        }
        statusService.setWasRunning(false); // Reset the running state
      }
    });
    
    // Player2 status listener
    unsubscribePlayer2StatusUpdate = ipc.onPlayer2StatusUpdate((data: Player2StatusUpdate) => {
      statusService.setPlayer2Status(data.status);
    });
  }

  /**
   * Handle provider changes (requires restart)
   */
  function handleProviderChange(): void {
    const currentConfig = get(config);
    if (previousProvider !== null && currentConfig.aiProvider !== previousProvider) {
      // Provider change always requires restart (new AI SDK client)
      aiBridgeService.restartAIBridge();
    }
    previousProvider = currentConfig.aiProvider;
  }

  /**
   * Handle model changes (can use efficient update if provider hasn't changed)
   */
  function handleModelChange(): void {
    const currentConfig = get(config);
    if (previousModel !== null && currentConfig.aiModel !== previousModel) {
      // Only do model update if provider didn't change (provider change handles restart)
      if (currentConfig.aiProvider === previousProvider) {
        aiBridgeService.updateAIModel();
      }
    }
    previousModel = currentConfig.aiModel;
  }

  /**
   * Handle API key changes for the current provider
   */
  async function handleApiKeyChange(): Promise<void> {
    const currentConfig = get(config);
    const currentApiKey = configService.getCurrentProviderApiKey(currentConfig);
    if (previousApiKey !== currentApiKey) {
      const wasEmpty = !previousApiKey;
      previousApiKey = currentApiKey;

      // Update AI bridge enabled status
      configService.updateConfig({ aiBridgeEnabled: !!currentApiKey });

      // If key changed (not just set for first time), restart to use new key
      if (!wasEmpty && currentApiKey) {
        await aiBridgeService.restartAIBridge();
      } else {
        // Otherwise just manage (start/stop) based on key presence
        await aiBridgeService.manageAIBridge();
      }
    }
  }

  /**
   * Cleanup function
   */
  function cleanup(): void {
    if (unsubscribeFactorioStatusUpdate) {
      unsubscribeFactorioStatusUpdate();
    }
    if (unsubscribePlayer2StatusUpdate) {
      unsubscribePlayer2StatusUpdate();
    }
  }

  return {
    initialize,
    handleProviderChange,
    handleModelChange,
    handleApiKeyChange,
    cleanup,
  };
}
