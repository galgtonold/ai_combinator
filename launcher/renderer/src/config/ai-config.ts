// AI Provider and Model Configuration

export interface AIProvider {
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
export const aiProviderOptions: AIProvider[] = [
  { value: "openai", label: "OpenAI", apiKeyURL: "https://platform.openai.com/api-keys" },
  { value: "anthropic", label: "Anthropic", apiKeyURL: "https://console.anthropic.com/settings/keys" },
  { value: "google", label: "Google", apiKeyURL: "https://aistudio.google.com/apikey" },
  { value: "xai", label: "xAI", apiKeyURL: "https://console.x.ai/" },
  { value: "deepseek", label: "DeepSeek", apiKeyURL: "https://deepseek.com/api-keys" },
];

// Model options for each provider
export const modelsByProvider: ModelsByProvider = {
  openai: [
    { value: "gpt-5", label: "GPT-5" },
    { value: "gpt-4.1", label: "GPT-4.1" },
    { value: "o1", label: "o1" },
    { value: "o4-mini", label: "o4-mini" },
  ],
  anthropic: [
    { value: "claude-opus-4-20250514", label: "Claude Opus 4" },
    { value: "claude-3-7-sonnet-20250219", label: "Claude 3.7 Sonnet" },
    { value: "claude-3-5-sonnet-20241022", label: "Claude 3.5 Sonnet" },
  ],
  google: [
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
  return options[0]?.value || "gpt-4";
}
