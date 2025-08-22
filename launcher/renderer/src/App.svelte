<script lang="ts">
  import ipc, { type Config, type FactorioStatus } from "./ipc";
  import {
    aiProviderOptions,
    modelsByProvider,
    getModelOptionsForProvider,
    isModelAvailableForProvider,
    getDefaultModelForProvider,
  } from "./ai-config";
  import "./app.css";

  // Components
  import {
    TitleBar,
    Button,
    InputField,
    NumberInputField,
    Dropdown,
    StatusIndicator,
    Section,
    LaunchButton,
    KeyToggleInput,
    Row,
    Label,
    HorizontalLine,
    StatusPreviewDisplay,
    GreenButton,
  } from "./components";

  // Config state
  let config: Config = $state({
    factorioPath: "",
    openAIKey: "", // Deprecated - kept for migration
    aiBridgeEnabled: false,
    aiProvider: "openai",
    aiModel: "gpt-4",
    udpPort: 9001,
    providerApiKeys: {},
  });

  // UI state
  let factorioStatus: FactorioStatus = $state("not_found");
  let factorioStatusText: string = $state("Not found");
  let factorioStatusClass: "error" | "warning" | "success" = $state("error");
  let isLaunching: boolean = $state(false);
  let statusMessage: string = $state("");
  let unsubscribeStatusUpdate: (() => void) | null = null;
  let wasRunning: boolean = $state(false); // Track if Factorio was previously running

  // Load config on component initialization
  $effect(() => {
    loadConfig();
    setupStatusListener();

    // Cleanup on component destruction
    return () => {
      if (unsubscribeStatusUpdate) {
        unsubscribeStatusUpdate();
      }
    };
  });

  function setupStatusListener() {
    // Subscribe to status updates from the main process
    unsubscribeStatusUpdate = ipc.onFactorioStatusUpdate((data) => {
      if (data.status === "running") {
        factorioStatus = "running";
        wasRunning = true; // Mark that Factorio is running
        updateFactorioStatusDisplay();
      } else if (data.status === "stopped") {
        factorioStatus = "stopped";
        updateFactorioStatusDisplay();

        // Only show closure message if Factorio was previously running
        if (wasRunning) {
          if (data.error) {
            setStatus("Factorio terminated with an error", "error");
          } else {
            setStatus("Factorio was closed", "success");
          }
          wasRunning = false; // Reset the running state
        }
      }
    });
  }

  async function loadConfig() {
    try {
      const loadedConfig = await ipc.getConfig();
      console.log("Received config from backend:", loadedConfig);

      // Ensure all properties are present with defaults
      config = {
        factorioPath: loadedConfig.factorioPath || "",
        openAIKey: loadedConfig.openAIKey || "", // Deprecated
        aiBridgeEnabled: false, // Will be set below based on provider API key
        aiProvider: (loadedConfig as any).aiProvider || "openai",
        aiModel: loadedConfig.aiModel || "gpt-4",
        udpPort: loadedConfig.udpPort || 9001,
        providerApiKeys: (loadedConfig as any).providerApiKeys || {},
      };

      console.log("Frontend config after loading:", config);

      // Migration: Move old openAIKey to provider-specific key if needed
      if (loadedConfig.openAIKey && !config.providerApiKeys.openai) {
        config.providerApiKeys.openai = loadedConfig.openAIKey;
        console.log("Migrated old OpenAI key to providerApiKeys");
      }

      // Update AI bridge enabled status based on current provider's API key
      config.aiBridgeEnabled = !!getCurrentProviderApiKey();

      // Initialize previous API key tracking
      previousApiKey = getCurrentProviderApiKey();
      currentApiKeyInput = getCurrentProviderApiKey();

      // Check if Factorio is currently running
      const isRunning = await ipc.isFactorioRunning();
      if (isRunning) {
        factorioStatus = "running";
        wasRunning = true; // Set wasRunning to true if Factorio is already running
      } else if (loadedConfig.factorioPath) {
        factorioStatus = "found";
      } else {
        factorioStatus = "not_found";
      }

      updateFactorioStatusDisplay();
    } catch (error) {
      console.error("Failed to load config:", error);
    }
  }

  async function saveConfig() {
    console.log("Saving config:", config);
    try {
      // Auto-enable AI bridge if current provider has API key
      config.aiBridgeEnabled = !!getCurrentProviderApiKey();

      // Ensure providerApiKeys is properly initialized
      if (!config.providerApiKeys) {
        config.providerApiKeys = {};
      }

      // Create a plain object with all the properties we need to save
      const configToSave = {
        factorioPath: config.factorioPath,
        openAIKey: config.openAIKey, // Keep for backward compatibility
        aiBridgeEnabled: config.aiBridgeEnabled,
        aiProvider: config.aiProvider,
        aiModel: config.aiModel,
        udpPort: config.udpPort,
        providerApiKeys: { ...config.providerApiKeys }, // Ensure it's a proper object copy
      };

      console.log("Sending config to backend:", configToSave);
      console.log("providerApiKeys being sent:", configToSave.providerApiKeys);
      await ipc.saveConfig(configToSave);

      // Update Factorio status based on path
      if (config.factorioPath) {
        if (factorioStatus !== "running") {
          factorioStatus = "found";
        }
      } else {
        factorioStatus = "not_found";
      }

      updateFactorioStatusDisplay();
    } catch (error) {
      console.error("Failed to save config:", error);
    }
  }

  function updateFactorioStatusDisplay() {
    // If there's an active status message, don't update the factorioStatusText
    if (statusMessage) return;

    switch (factorioStatus) {
      case "not_found":
        factorioStatusText = "Not found";
        factorioStatusClass = "error";
        break;
      case "found":
        factorioStatusText = "Found";
        factorioStatusClass = "success";
        break;
      case "running":
        factorioStatusText = "Running";
        factorioStatusClass = "success";
        break;
      case "stopped":
        factorioStatusText = "Stopped";
        factorioStatusClass = "warning";
        break;
    }
  }

  async function manageAIBridge() {
    const currentApiKey = getCurrentProviderApiKey();
    const shouldBeRunning = currentApiKey && config.aiBridgeEnabled;
    const isCurrentlyRunning = await ipc.isAIBridgeRunning();

    if (shouldBeRunning && !isCurrentlyRunning) {
      await startAIBridge();
    } else if (!shouldBeRunning && isCurrentlyRunning) {
      await stopAIBridge();
    }
  }

  async function startAIBridge() {
    const currentApiKey = getCurrentProviderApiKey();
    if (!currentApiKey) {
      setStatus("API key is required", "error");
      return;
    }

    try {
      const result = await ipc.startAIBridge();
      if (result.success) {
        setStatus("AI Bridge started automatically", "success");
      } else {
        setStatus(result.message, "error");
      }
    } catch (error) {
      setStatus(`Error starting AI Bridge: ${error}`, "error");
    }
  }

  async function stopAIBridge() {
    try {
      const result = await ipc.stopAIBridge();
      if (result.success) {
        setStatus("AI Bridge stopped", "success");
      } else {
        setStatus(result.message, "error");
      }
    } catch (error) {
      setStatus(`Error stopping AI Bridge: ${error}`, "error");
    }
  }

  async function restartAIBridge() {
    await stopAIBridge();
    // Small delay to ensure clean shutdown
    setTimeout(async () => {
      await startAIBridge();
    }, 500);
  }

  async function updateAIModel() {
    try {
      await ipc.updateAIModel(config.aiModel);
      setStatus("AI model updated successfully", "success");
    } catch (error) {
      setStatus(`Error updating AI model: ${error}`, "error");
    }
  }

  async function browseFactorioPath() {
    const path = await ipc.browseFactorioPath();
    if (path) {
      config = { ...config, factorioPath: path };
      await saveConfig();
      setStatus("Factorio executable selected successfully", "success");
    }
  }

  async function autoDetectFactorio() {
    const path = await ipc.autoDetectFactorio();
    if (path) {
      config = { ...config, factorioPath: path };
      await saveConfig();
      setStatus("Factorio executable detected automatically", "success");
    } else {
      setStatus("Failed to detect Factorio executable", "error");
    }
  }

  async function launchFactorio() {
    // Prevent launching if already running
    if (factorioStatus === "running") {
      setStatus("Factorio is already running", "error");
      return;
    }

    if (!config.factorioPath) {
      setStatus("Factorio executable not found", "error");
      return;
    }

    isLaunching = true;
    setStatus("Launching Factorio...", "success");

    try {
      const result = await ipc.launchFactorio();
      if (result.success) {
        setStatus(result.message, "success");
        wasRunning = true; // Set wasRunning to true when we successfully launch Factorio
      } else {
        setStatus(result.message, "error");
      }
    } catch (error) {
      setStatus(`Error launching Factorio: ${error}`, "error");
    } finally {
      isLaunching = false;
    }
  }

  function setStatus(message: string, type: "success" | "error") {
    statusMessage = message;
    // Temporarily override the status class to show the message type
    factorioStatusClass = type;

    // After 5 seconds, clear the status message and restore the original factorio status display
    setTimeout(() => {
      statusMessage = "";
      updateFactorioStatusDisplay();
    }, 5000);
  }

  // Window control functions
  function handleMinimize() {
    ipc.minimizeWindow();
  }

  function handleClose() {
    ipc.closeWindow();
  }

  // Get current model options based on selected provider
  const currentModelOptions = $derived(getModelOptionsForProvider(config.aiProvider));

  // Helper functions for provider-specific API keys
  function getCurrentProviderApiKey(): string {
    if (!config.providerApiKeys) {
      config.providerApiKeys = {};
    }
    return config.providerApiKeys[config.aiProvider] || "";
  }

  function setCurrentProviderApiKey(apiKey: string) {
    console.log(
      `Setting API key for provider ${config.aiProvider}:`,
      apiKey ? "[REDACTED]" : "empty",
    );
    if (!config.providerApiKeys) {
      config.providerApiKeys = {};
      console.log("Initialized empty providerApiKeys object");
    }
    config.providerApiKeys[config.aiProvider] = apiKey;
    console.log("Updated providerApiKeys:", Object.keys(config.providerApiKeys));

    // Update the input field as well to keep them in sync
    currentApiKeyInput = apiKey;
  }

  // Handle API key input changes
  async function handleApiKeyChange() {
    console.log(
      `handleApiKeyChange called. currentApiKeyInput: ${currentApiKeyInput ? "[REDACTED]" : "empty"}`,
    );
    console.log(`Current provider: ${config.aiProvider}`);
    console.log(`Config providerApiKeys before update:`, Object.keys(config.providerApiKeys || {}));

    // Update the provider-specific key with the current input value
    setCurrentProviderApiKey(currentApiKeyInput);

    console.log(`Config providerApiKeys after update:`, Object.keys(config.providerApiKeys || {}));
    console.log(
      `Value for current provider after update: ${config.providerApiKeys[config.aiProvider] ? "[REDACTED]" : "empty"}`,
    );

    await saveConfig();
  }

  // Reactive variable to track current provider's API key for the input
  let currentApiKeyInput = $state("");

  // Watch for provider changes to update the input field
  $effect(() => {
    currentApiKeyInput = getCurrentProviderApiKey();
  });

  // Track previous values for change detection and API key monitoring
  let previousProvider: string | null = null;
  let previousModel: string | null = null;
  let previousApiKey: string = "";

  // Handle provider changes (requires restart)
  $effect(() => {
    // Only update if provider actually changed
    if (previousProvider !== null && config.aiProvider !== previousProvider) {
      console.log(`Provider changed from ${previousProvider} to ${config.aiProvider}`);

      if (!isModelAvailableForProvider(config.aiProvider, config.aiModel)) {
        const defaultModel = getDefaultModelForProvider(config.aiProvider);
        console.log(
          `Model ${config.aiModel} not available for ${config.aiProvider}, switching to ${defaultModel}`,
        );
        config.aiModel = defaultModel;
        // Save the updated config
        saveConfig();
      }

      // Update the input field with the new provider's API key
      currentApiKeyInput = getCurrentProviderApiKey();

      // Provider change always requires restart (new AI SDK client)
      // Use the restart function which handles checking if running
      restartAIBridge();
    }
    previousProvider = config.aiProvider;
  });

  // Monitor API key changes for the current provider
  $effect(() => {
    const currentApiKey = getCurrentProviderApiKey();
    if (previousApiKey !== currentApiKey) {
      console.log(`API key changed for provider ${config.aiProvider}`);
      previousApiKey = currentApiKey;

      // Update AI bridge enabled status
      config.aiBridgeEnabled = !!currentApiKey;

      // Manage bridge based on new key status
      manageAIBridge();
    }
  });

  // Handle model changes (can use efficient update if provider hasn't changed)
  $effect(() => {
    if (previousModel !== null && config.aiModel !== previousModel) {
      console.log(`Model changed from ${previousModel} to ${config.aiModel}`);
      console.log(`Provider is: ${config.aiProvider}, previous provider: ${previousProvider}`);
      // Only do model update if provider didn't change (provider change handles restart)
      if (config.aiProvider === previousProvider) {
        console.log("Provider unchanged, using updateAIModel()");
        updateAIModel();
      } else {
        console.log("Provider also changed, restart will be handled by provider effect");
      }
    }
    previousModel = config.aiModel;
  });
</script>

<main>
  <div class="panel">
    <div class="factorio-combinator">
      <!-- Custom Title Bar -->
      <TitleBar on:minimize={handleMinimize} on:close={handleClose} />

      <div class="content-container">
        <StatusIndicator
          status={factorioStatusClass}
          text={statusMessage || `Factorio: ${factorioStatusText}`}
        />

        <!-- Status Preview Display Section -->
        <StatusPreviewDisplay aiProvider={config.aiProvider} />

        <div style="margin-left: 5px; margin-right: 5px;">
          <Section title="Factorio Executable">
            <Row>
              <InputField
                value={config.factorioPath}
                placeholder="Path to factorio.exe"
                onChange={saveConfig}
              />
              <Button onClick={browseFactorioPath}>Browse</Button>
              <Button onClick={autoDetectFactorio}>Auto-Detect</Button>
            </Row>
          </Section>

          <HorizontalLine />

          <Section title="AI Configuration">
            <Row justify="space-between">
              <Label size="small">Provider</Label>
              <Dropdown
                value={config.aiProvider}
                options={aiProviderOptions}
                width="300px"
                onChange={(value) => {
                  config = { ...config, aiProvider: value };
                  saveConfig();
                  updateAIModel();
                }}
              />
            </Row>
            <Row justify="space-between">
              <Label size="small">Model:</Label>
              {#key config.aiProvider}
                <Dropdown
                  value={config.aiModel}
                  options={currentModelOptions}
                  width="300px"
                  onChange={(value) => {
                    config = { ...config, aiModel: value };
                    saveConfig();
                  }}
                />
              {/key}
            </Row>
            <Row justify="space-between" marginBottom="30px">
              <Label size="small">API Key:</Label>
              <KeyToggleInput
                bind:value={currentApiKeyInput}
                placeholder={`Enter your ${aiProviderOptions.find((p) => p.value === config.aiProvider)?.label || "API"} key...`}
                onChange={handleApiKeyChange}
                width="400px"
              />
            </Row>

            <!--
          <Row>
            <Label size="small">UDP Port:</Label>
            <NumberInputField value={config.udpPort} min={1024} max={65535} onChange={saveConfig} />
          </Row>
          -->
          </Section>

          <LaunchButton
            onClick={launchFactorio}
            disabled={!config.factorioPath || isLaunching || factorioStatus === "running"}
            text={isLaunching
              ? "Launching..."
              : factorioStatus === "running"
                ? "Factorio is Running"
                : "Launch Factorio"}
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
