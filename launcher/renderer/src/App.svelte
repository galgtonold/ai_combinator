<script lang="ts">
  import ipc, { type AIProvider } from "./utils/ipc";
  import {
    isModelAvailableForProvider,
    getDefaultModelForProvider,
  } from "./config/ai-config";
  import "./app.css";

  // Components
  import {
    TitleBar,
    StatusIndicator,
    StatusPreviewDisplay,
    HorizontalLine,
    FactorioPathSection,
    AIConfigSection,
    LaunchSection,
  } from "./components";

  // Stores and Services
  import { config, configService, status, aiBridgeService } from "./stores";
  import { useAppEffects } from "./composables";

  // Initialize effects handler
  const appEffects = useAppEffects();

  // Local state for API key input (to handle real-time editing)
  let currentApiKeyInput = $state("");

  // Initialize app on component mount
  $effect(() => {
    appEffects.initialize();

    // Cleanup on component destruction
    return () => {
      appEffects.cleanup();
    };
  });

  // Watch for provider changes to update the input field and handle provider logic
  $effect(() => {
    currentApiKeyInput = configService.getCurrentProviderApiKey($config);
    appEffects.handleProviderChange();
  });

  // Handle model changes
  $effect(() => {
    appEffects.handleModelChange();
  });

  // Handle API key changes
  $effect(() => {
    appEffects.handleApiKeyChange();
  });

  // Event handlers
  async function handleApiKeyChange(): Promise<void> {
    // Update the provider-specific key with the current input value
    const newConfig = configService.setCurrentProviderApiKey($config, currentApiKeyInput);
    config.set(newConfig);
    await configService.saveConfig(newConfig);
  }

  async function handleProviderChange(provider: string): Promise<void> {
    const newConfig = { ...$config, aiProvider: provider as AIProvider };
    
    // Check if model is available for new provider
    if (!isModelAvailableForProvider(newConfig.aiProvider, newConfig.aiModel)) {
      const defaultModel = getDefaultModelForProvider(newConfig.aiProvider);
      newConfig.aiModel = defaultModel;
    }
    
    config.set(newConfig);
    await configService.saveConfig(newConfig);
    await aiBridgeService.updateAIModel();
  }

  async function handleModelChange(model: string): Promise<void> {
    const newConfig = { ...$config, aiModel: model };
    config.set(newConfig);
    await configService.saveConfig(newConfig);
  }

  async function handleFactorioPathChange(): Promise<void> {
    await configService.saveConfig($config);
  }

  // Window control functions
  function handleMinimize(): void {
    ipc.minimizeWindow();
  }

  function handleClose(): void {
    ipc.closeWindow();
  }
</script>

<main>
  <div class="panel">
    <div class="factorio-combinator">
      <!-- Custom Title Bar -->
      <TitleBar on:minimize={handleMinimize} on:close={handleClose} />

      <div class="content-container">
        <StatusIndicator
          status={$status.factorioStatusClass}
          text={$status.statusMessage || `Factorio: ${$status.factorioStatusText}`}
        />

        <!-- Status Preview Display Section -->
        <StatusPreviewDisplay 
          aiProvider={$config.aiProvider} 
          status={$status.factorioStatusClass} 
        />

        <div style="margin-left: 5px; margin-right: 5px;">
          <FactorioPathSection
            factorioPath={$config.factorioPath}
            onPathChange={handleFactorioPathChange}
          />

          <HorizontalLine />

          <AIConfigSection
            config={$config}
            {currentApiKeyInput}
            onProviderChange={handleProviderChange}
            onModelChange={handleModelChange}
            onApiKeyChange={handleApiKeyChange}
          />

          <LaunchSection
            factorioPath={$config.factorioPath}
            isLaunching={$status.isLaunching}
            factorioStatus={$status.factorioStatus}
          />
        </div>
      </div>
    </div>
  </div>
</main>

<style>
  main {
    height: 100vh;
    padding: 0;
    margin: 0;
    box-sizing: border-box;
    display: flex;
    flex-direction: column;
    overflow: hidden;
    background-color: transparent; /* Ensure main doesn't interfere with panel styling */
  }

  .factorio-combinator {
    display: flex;
    flex-direction: column;
    height: 100vh;
    margin: 0;
    max-width: none;
    border-radius: 0;
    background-color: transparent; /* Allow panel style to be visible */
  }

  .content-container {
    padding: 8px;
    flex: 1;
    overflow: hidden;
    display: flex;
    flex-direction: column;
    margin-bottom: 16px;
    margin-left: 16px;
    margin-right: 16px;
    background-color: #414040;
    border: 4px solid #2e2623;
    box-shadow: 0px 0px 3px 0px #201815;
    border-image: url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACEAAAAhCAMAAABgOjJdAAABhWlDQ1BJQ0MgcHJvZmlsZQAAKJF9kTtIw1AUhv+miiIVBzuICEaoThbEF45ahSJUCLVCqw4mN31Bk4YkxcVRcC04+FisOrg46+rgKgiCDxBHJydFFynx3KTQIsYDl/vx3/P/3HsuINRKTLPaxgBNt81kPCamM6tixysCGEQIQ5iSmWXMSVICvvV1T91Ud1Ge5d/3Z3WrWYsBAZF4lhmmTbxBPL1pG5z3icOsIKvE58SjJl2Q+JHrisdvnPMuCzwzbKaS88RhYjHfwkoLs4KpEU8SR1RNp3wh7bHKeYuzVqqwxj35C0NZfWWZ67QGEMciliBBhIIKiijBRpR2nRQLSTqP+fj7Xb9ELoVcRTByLKAMDbLrB/+D37O1chPjXlIoBrS/OM7HMNCxC9SrjvN97Dj1EyD4DFzpTX+5Bsx8kl5tapEjoGcbuLhuasoecLkD9D0Zsim7UpCWkMsB72f0TRmg9xboWvPm1jjH6QOQolklboCDQ2AkT9nrPu/ubJ3bvz2N+f0As9tywbHNoQUAAAAJcEhZcwAALiMAAC4jAXilP3YAAAAHdElNRQfmAgMLNBNXffN5AAAAGXRFWHRDb21tZW50AENyZWF0ZWQgd2l0aCBHSU1QV4EOFwAAAQtQTFRFAAAAAAAAMTAAYQABMQABAAAA/9y6AAAAAAAA/7F+SjAAMRgAMQABGQABAAAA/9nH/9m0MQ8AIQ8AAAAAAAAA/8GqGQsAAAAAAAAAAAAAOxwAMRMAJwkAFAkAMQ8AKQ8AEQABAAAAAAAAAAAA/+/pBwYA//fq//HkAAAAJQsAAAAAIQoABQQA//nwIgkADwQAAAAA//XsAAAAAAAAAAAAHQsA//rzAAAAAAAAAAAACgIAAAAAAAAADAUABgIAAAAAAAAAAAAAGQcADwcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFAcAAAAACgMAAAAAAAAAAAAACgIAAAAAAAAAAwIAAAAAdNLDhQAAAFh0Uk5TAAIFBQUFBwgJCgoKCwsMDg4QEBASFRUVGBkaGhoaHx8gICEiIyQlJiYqLi8vMjQ0NDY2Nzo+P0BBTE5PUVNTVFpcXmNjZG9wcXJzdHh5fYCChIuMl5utu+r6V5gAAAABYktHRFmasvQYAAABUklEQVR4nLXUyU7DMBAG4PHEaewsbWihUg9IIPH+T4QEEodKhZa0Wew0jo2SLlD74BM+WZpP8nj5TcA3yGWCdkXfCsTIFq3WvwIRYGqLA8BoyAg4jx9t8dEIMZBBUJ7P5itbrHf7QqhRIE4XD0tmC7n53B60HgSF+er+jtpCfX+td6CAAPIoW2YpM1pp3RsAEiBSJLIqN2Ur9FVESnbKnAShIaOtLaiQUvdD84gBMsaVLUhTdY3uBhFiHKaxsYWu5EEK3QMEyNmUpWgLVddV0XVHgEkY5mmSUFscK1FUoh1WiXia83RiC1nX+7LqFQAN0myWJOw/hL8P/1785+E/U/+9+O/W/z7cKF0F0CzOg7UDnt9WfdGUahRJ9v7iCKpen8r6JKKFigNHGNI3dNuqMVEkUtwRxAjaGn1KZUJg4nYKRzD1n2Q79egcbeJULgPP38MP9ZBIMci5WIsAAAAASUVORK5CYII=")
      16/8px repeat;
    border-image-outset: 4px;
  }
</style>
