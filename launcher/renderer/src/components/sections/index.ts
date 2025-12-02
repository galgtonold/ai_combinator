/**
 * Section components barrel exports
 * 
 * High-level feature sections that compose multiple smaller components
 * into cohesive functionality blocks.
 * 
 * @module components/sections
 */

/**
 * Factorio executable path configuration
 * 
 * Features:
 * - Path input field
 * - Browse button for manual selection
 * - Auto-detect button for automatic discovery
 */
export { default as FactorioPathSection } from './FactorioPathSection.svelte';

/**
 * AI provider and model configuration
 * 
 * Features:
 * - Provider dropdown (OpenAI, Anthropic, etc.)
 * - Model dropdown (provider-specific models)
 * - API key input with visibility toggle
 * - Link to provider's API key page
 */
export { default as AIConfigSection } from './AIConfigSection.svelte';

/**
 * Factorio launch controls
 * 
 * Features:
 * - Large green launch button
 * - Disabled state when Factorio is running
 * - Launching state feedback
 */
export { default as LaunchSection } from './LaunchSection.svelte';
