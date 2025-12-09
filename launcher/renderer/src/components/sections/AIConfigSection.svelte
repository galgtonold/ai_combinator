<script lang="ts">
  import type { Config } from "../../utils/ipc";
  import {
    aiProviderOptions,
    getModelOptionsForProvider,
  } from "../../config/ai-config";
  import { Button, Dropdown, KeyToggleInput, Label, Row, Section } from "../index.js";

  interface Props {
    config: Config;
    currentApiKeyInput: string;
    onProviderChange: (provider: string) => void;
    onModelChange: (model: string) => void;
    onApiKeyChange: () => Promise<void>;
  }

  let { config, currentApiKeyInput = $bindable(), onProviderChange, onModelChange, onApiKeyChange }: Props = $props();
  
  // Function to open API key URL in default browser
  async function openApiKeyUrl() {
    const provider = aiProviderOptions.find(p => p.value === config.aiProvider);
    if (provider && provider.apiKeyURL) {
      await window.bridge.openExternal(provider.apiKeyURL);
    }
  }

  // Get current model options based on selected provider
  const currentModelOptions = $derived(getModelOptionsForProvider(config.aiProvider));
</script>

<Section title="AI Configuration">
  <Row justify="space-between">
    <Label size="small">Provider</Label>
    <Dropdown
      value={config.aiProvider}
      options={aiProviderOptions}
      width="350px"
      onChange={onProviderChange}
    />
  </Row>
  <Row justify="space-between">
    <Label size="small">Model</Label>
    {#key config.aiProvider}
      <Dropdown
        value={config.aiModel}
        options={currentModelOptions}
        width="350px"
        onChange={onModelChange}
      />
    {/key}
  </Row>
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
</Section>
