import ipc from "../utils/ipc";
import { configStore, statusStore, aiBridgeService, factorioService } from "../stores";
import { isModelAvailableForProvider, getDefaultModelForProvider } from "../config/ai-config";

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
    await configStore.loadConfig();
    await factorioService.checkFactorioStatus();
    setupStatusListener();
    
    // Initialize tracking variables
    previousApiKey = configStore.getCurrentProviderApiKey();
    previousProvider = configStore.config.aiProvider;
    previousModel = configStore.config.aiModel;
  }

  /**
   * Setup status listener for Factorio updates
   */
  function setupStatusListener(): void {
    unsubscribeStatusUpdate = ipc.onFactorioStatusUpdate((data: any) => {
      if (data.status === "running") {
        statusStore.setFactorioStatus("running");
      } else if (data.status === "stopped") {
        statusStore.setFactorioStatus("stopped");

        // Only show closure message if Factorio was previously running
        if (statusStore.wasRunning) {
          if (data.error) {
            statusStore.setStatus("Factorio terminated with an error", "error");
          } else {
            statusStore.setStatus("Factorio was closed", "success");
          }
          statusStore.setWasRunning(false); // Reset the running state
        }
      }
    });
  }

  /**
   * Handle provider changes (requires restart)
   */
  function handleProviderChange(): void {
    if (previousProvider !== null && configStore.config.aiProvider !== previousProvider) {
      console.log(`Provider changed from ${previousProvider} to ${configStore.config.aiProvider}`);

      if (!isModelAvailableForProvider(configStore.config.aiProvider, configStore.config.aiModel)) {
        const defaultModel = getDefaultModelForProvider(configStore.config.aiProvider);
        console.log(
          `Model ${configStore.config.aiModel} not available for ${configStore.config.aiProvider}, switching to ${defaultModel}`,
        );
        configStore.updateConfig({ aiModel: defaultModel });
        configStore.saveConfig();
      }

      // Provider change always requires restart (new AI SDK client)
      aiBridgeService.restartAIBridge();
    }
    previousProvider = configStore.config.aiProvider;
  }

  /**
   * Handle model changes (can use efficient update if provider hasn't changed)
   */
  function handleModelChange(): void {
    if (previousModel !== null && configStore.config.aiModel !== previousModel) {
      console.log(`Model changed from ${previousModel} to ${configStore.config.aiModel}`);
      console.log(`Provider is: ${configStore.config.aiProvider}, previous provider: ${previousProvider}`);
      
      // Only do model update if provider didn't change (provider change handles restart)
      if (configStore.config.aiProvider === previousProvider) {
        console.log("Provider unchanged, using updateAIModel()");
        aiBridgeService.updateAIModel();
      } else {
        console.log("Provider also changed, restart will be handled by provider effect");
      }
    }
    previousModel = configStore.config.aiModel;
  }

  /**
   * Handle API key changes for the current provider
   */
  function handleApiKeyChange(): void {
    const currentApiKey = configStore.getCurrentProviderApiKey();
    if (previousApiKey !== currentApiKey) {
      console.log(`API key changed for provider ${configStore.config.aiProvider}`);
      previousApiKey = currentApiKey;

      // Update AI bridge enabled status
      configStore.updateConfig({ aiBridgeEnabled: !!currentApiKey });

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
