import ipc from "../utils/ipc";
import { config, configService, status, statusService, aiBridgeService, factorioService } from "../stores";
import { isModelAvailableForProvider, getDefaultModelForProvider } from "../config/ai-config";
import { get } from 'svelte/store';

/**
 * Composable for handling application initialization and reactive effects
 */
export function useAppEffects() {
  let unsubscribeStatusUpdate: (() => void) | null = null;
  
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
    setupStatusListener();
    
    // Initialize tracking variables
    const currentConfig = get(config);
    previousApiKey = configService.getCurrentProviderApiKey(currentConfig);
    previousProvider = currentConfig.aiProvider;
    previousModel = currentConfig.aiModel;
  }

  /**
   * Setup status listener for Factorio updates
   */
  function setupStatusListener(): void {
    unsubscribeStatusUpdate = ipc.onFactorioStatusUpdate((data: any) => {
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
  }

  /**
   * Handle provider changes (requires restart)
   */
  function handleProviderChange(): void {
    const currentConfig = get(config);
    if (previousProvider !== null && currentConfig.aiProvider !== previousProvider) {
      console.log(`Provider changed from ${previousProvider} to ${currentConfig.aiProvider}`);

      if (!isModelAvailableForProvider(currentConfig.aiProvider, currentConfig.aiModel)) {
        const defaultModel = getDefaultModelForProvider(currentConfig.aiProvider);
        console.log(
          `Model ${currentConfig.aiModel} not available for ${currentConfig.aiProvider}, switching to ${defaultModel}`,
        );
        configService.updateConfig({ aiModel: defaultModel });
        const updatedConfig = get(config);
        configService.saveConfig(updatedConfig);
      }

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
      console.log(`Model changed from ${previousModel} to ${currentConfig.aiModel}`);
      console.log(`Provider is: ${currentConfig.aiProvider}, previous provider: ${previousProvider}`);
      
      // Only do model update if provider didn't change (provider change handles restart)
      if (currentConfig.aiProvider === previousProvider) {
        console.log("Provider unchanged, using updateAIModel()");
        aiBridgeService.updateAIModel();
      } else {
        console.log("Provider also changed, restart will be handled by provider effect");
      }
    }
    previousModel = currentConfig.aiModel;
  }

  /**
   * Handle API key changes for the current provider
   */
  function handleApiKeyChange(): void {
    const currentConfig = get(config);
    const currentApiKey = configService.getCurrentProviderApiKey(currentConfig);
    if (previousApiKey !== currentApiKey) {
      console.log(`API key changed for provider ${currentConfig.aiProvider}`);
      previousApiKey = currentApiKey;

      // Update AI bridge enabled status
      configService.updateConfig({ aiBridgeEnabled: !!currentApiKey });

      // Manage bridge based on new key status
      aiBridgeService.manageAIBridge();
    }
  }

  /**
   * Cleanup function
   */
  function cleanup(): void {
    if (unsubscribeStatusUpdate) {
      unsubscribeStatusUpdate();
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
