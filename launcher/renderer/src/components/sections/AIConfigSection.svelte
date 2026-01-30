<script lang="ts">
  import type { Config } from "../../utils/ipc";
  import {
    aiProviderOptions,
    getModelOptionsForProvider,
    isProviderWithFreeformModel,
    isProviderWithNoModelSelection,
    isProviderRequiringApiKey,
  } from "../../config/ai-config";
  import { Button, Dropdown, InputField, KeyToggleInput, Label, Row, Section } from "../index.js";

  interface Props {
    config: Config;
    currentApiKeyInput: string;
    onProviderChange: (provider: string) => void;
    onModelChange: (model: string) => void;
    onApiKeyChange: () => Promise<void>;
  }

  let { config, currentApiKeyInput = $bindable(), onProviderChange, onModelChange, onApiKeyChange }: Props = $props();
  
  // Local state for free-form model input
  let modelInput = $state(config.aiModel);
  
  // Sync modelInput when config changes (e.g., provider switch)
  $effect(() => {
    modelInput = config.aiModel;
  });
  
  // Function to open API key URL in default browser
  async function openApiKeyUrl() {
    const provider = aiProviderOptions.find(p => p.value === config.aiProvider);
    if (provider && provider.apiKeyURL) {
      await window.bridge.openExternal(provider.apiKeyURL);
    }
  }
  
  // Handle free-form model input change
  function handleModelInputChange() {
    onModelChange(modelInput);
  }

  // Get current model options based on selected provider
  const currentModelOptions = $derived(getModelOptionsForProvider(config.aiProvider));
  
  // Check if current provider uses free-form model input
  const usesFreeformModel = $derived(isProviderWithFreeformModel(config.aiProvider));
  
  // Check if current provider has no model selection (model is configured externally)
  const hasNoModelSelection = $derived(isProviderWithNoModelSelection(config.aiProvider));
  
  // Check if current provider requires an API key
  const requiresApiKey = $derived(isProviderRequiringApiKey(config.aiProvider));
</script>

<Section title="AI Configuration">
  <Row justify="space-between">
    <Label size="small">Provider</Label>
    <Dropdown
      value={config.aiProvider}
      options={aiProviderOptions}
      width="350px"
      onChange={onProviderChange}
      openUpward={true}
    />
  </Row>
  {#if !hasNoModelSelection}
    <Row justify="space-between">
      <Label size="small">Model</Label>
      {#if usesFreeformModel}
        <div style="width: 350px;">
          <InputField
            bind:value={modelInput}
            placeholder="Enter model name (e.g., llama3.2, mistral, codellama)"
            onChange={handleModelInputChange}
            fullWidth={true}
          />
        </div>
      {:else}
        {#key config.aiProvider}
          <Dropdown
            value={config.aiModel}
            options={currentModelOptions}
            width="350px"
            onChange={onModelChange}
            openUpward={true}
          />
        {/key}
      {/if}
    </Row>
  {:else}
    <!-- Download button row for Player2 (in Model row position) -->
    <Row justify="space-between">
      <Label size="small"></Label>
      <div style="width: 350px;">
        <Button 
          onClick={openApiKeyUrl}
          primary={true}
          fullWidth={true}
        >
          Download Player2 App
        </Button>
      </div>
    </Row>
  {/if}
  {#if requiresApiKey}
    <Row justify="space-between" marginBottom="30px">
      <Label size="small">API Key</Label>
      <div style="display: flex; gap: 10px;">
        <KeyToggleInput
          bind:value={currentApiKeyInput}
          placeholder={`Enter your ${aiProviderOptions.find((p) => p.value === config.aiProvider)?.label || "API"} key...`}
          onChange={onApiKeyChange}
          width="233px"
        />
        <Button 
          onClick={openApiKeyUrl}
          primary={true}
        >
          Get Key
        </Button>
      </div>
    </Row>
  {:else if hasNoModelSelection}
    <!-- Empty row to maintain consistent spacing after Player2 download button -->
    <Row justify="space-between" marginBottom="30px">
      <Label size="small"></Label>
      <div style="width: 350px; height: 40px;"></div>
    </Row>
  {:else}
    <Row justify="space-between" marginBottom="30px">
      <Label size="small"></Label>
      <div style="width: 350px;">
        <Button 
          onClick={openApiKeyUrl}
          primary={true}
          fullWidth={true}
        >
          Browse Models
        </Button>
      </div>
    </Row>
  {/if}
</Section>
