// AI Provider and Model Configuration

/** UI representation of an AI provider with display info */
export interface AIProviderOption {
  value: string;
  label: string;
  apiKeyURL: string;
}

export interface AIModel {
  value: string;
  label: string;
}

export interface ModelsByProvider {
  [key: string]: AIModel[];
}

// AI Provider options
export const aiProviderOptions: AIProviderOption[] = [
  { value: "openai", label: "OpenAI", apiKeyURL: "https://platform.openai.com/api-keys" },
  { value: "anthropic", label: "Anthropic", apiKeyURL: "https://console.anthropic.com/settings/keys" },
  { value: "google", label: "Google", apiKeyURL: "https://aistudio.google.com/apikey" },
  { value: "xai", label: "xAI", apiKeyURL: "https://console.x.ai/" },
  { value: "deepseek", label: "DeepSeek", apiKeyURL: "https://deepseek.com/api-keys" },
];

// Model options for each provider
export const modelsByProvider: ModelsByProvider = {
  openai: [
    { value: "gpt-5.1", label: "GPT-5.1" },
    { value: "gpt-5.1-codex", label: "GPT-5.1 Codex" },
    { value: "gpt-5-mini", label: "GPT-5 Mini" },
  ],
  anthropic: [
    { value: "claude-opus-4-5", label: "Claude Opus 4.5" },
    { value: "claude-sonnet-4-5", label: "Claude 4.5 Sonnet" },
    { value: "claude-haiku-4-5", label: "Claude 4.5 Haiku" },
  ],
  google: [
    { value: "gemini-3-pro-preview", label: "Gemini 3 Pro Preview" },
    { value: "gemini-2.5-pro", label: "Gemini 2.5 Pro" },
    { value: "gemini-2.5-flash", label: "Gemini 2.5 Flash" },
  ],
  xai: [
    { value: "grok-4", label: "Grok 4" },
    { value: "grok-3", label: "Grok 3" },
  ],
  deepseek: [
    { value: "deepseek-chat", label: "DeepSeek Chat" },
    { value: "deepseek-reasoner", label: "DeepSeek Reasoner" },
  ],
};

// Helper function to get model options for a provider
export function getModelOptionsForProvider(provider: string): AIModel[] {
  return modelsByProvider[provider] || modelsByProvider.openai;
}

// Helper function to check if a model exists for a provider
export function isModelAvailableForProvider(provider: string, model: string): boolean {
  const options = getModelOptionsForProvider(provider);
  return options.some(option => option.value === model);
}

// Helper function to get the default model for a provider
export function getDefaultModelForProvider(provider: string): string {
  const options = getModelOptionsForProvider(provider);
  return options[0]?.value;
}
