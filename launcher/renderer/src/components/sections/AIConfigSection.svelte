<script lang="ts">
  import type { Config } from "../../utils/ipc";
  import {
    aiProviderOptions,
    getModelOptionsForProvider,
  } from "../../config/ai-config";
  import { Dropdown, KeyToggleInput, Label, Row, Section } from "../index.js";

  interface Props {
    config: Config;
    currentApiKeyInput: string;
    onProviderChange: (provider: string) => void;
    onModelChange: (model: string) => void;
    onApiKeyChange: () => Promise<void>;
  }

  let { config, currentApiKeyInput, onProviderChange, onModelChange, onApiKeyChange }: Props = $props();

  // Get current model options based on selected provider
  const currentModelOptions = $derived(getModelOptionsForProvider(config.aiProvider));
</script>

<Section title="AI Configuration">
  <Row justify="space-between">
    <Label size="small">Provider</Label>
    <Dropdown
      value={config.aiProvider}
      options={aiProviderOptions}
      width="300px"
      onChange={onProviderChange}
    />
  </Row>
  <Row justify="space-between">
    <Label size="small">Model:</Label>
    {#key config.aiProvider}
      <Dropdown
        value={config.aiModel}
        options={currentModelOptions}
        width="300px"
        onChange={onModelChange}
      />
    {/key}
  </Row>
  <Row justify="space-between" marginBottom="30px">
    <Label size="small">API Key:</Label>
    <KeyToggleInput
      bind:value={currentApiKeyInput}
      placeholder={`Enter your ${aiProviderOptions.find((p) => p.value === config.aiProvider)?.label || "API"} key...`}
      onChange={onApiKeyChange}
      width="400px"
    />
  </Row>
</Section>
