/**
 * Component barrel exports
 * 
 * Central export point for all reusable Svelte components.
 * Import components from this file for cleaner imports:
 * 
 * @example
 * ```typescript
 * import { Button, InputField, Section } from './components';
 * ```
 * 
 * Instead of:
 * ```typescript
 * import Button from './components/buttons/NormalButton.svelte';
 * import InputField from './components/form/InputField.svelte';
 * import Section from './components/layout/Section.svelte';
 * ```
 * 
 * @module components
 */

// ============================================================================
// Button Components
// ============================================================================

/**
 * Standard Factorio-styled button (alias for NormalButton)
 * Use for most actions and interactions
 */
export { default as Button } from './buttons/NormalButton.svelte';

/**
 * Large green button typically used for primary actions
 * Used for the main "Launch Factorio" button
 */
export { default as GreenButton } from './buttons/GreenButton.svelte';

/**
 * Frame-styled button for navigation or secondary actions
 */
export { default as FrameButton } from './buttons/FrameButton.svelte';

/**
 * Listbox item button for dropdown-style selections
 */
export { default as ListboxItemButton } from './buttons/ListboxItemButton.svelte';

// ============================================================================
// Form Components
// ============================================================================

/**
 * Text input field with Factorio styling
 */
export { default as InputField } from './form/InputField.svelte';

/**
 * Password/API key input with show/hide toggle
 */
export { default as KeyToggleInput } from './form/KeyToggleInput.svelte';

/**
 * Number input field with increment/decrement controls
 */
export { default as NumberInputField } from './form/NumberInputField.svelte';

/**
 * Multi-line text area input
 */
export { default as TextAreaField } from './form/TextAreaField.svelte';

// ============================================================================
// UI Components
// ============================================================================

/**
 * Dropdown selector with custom Factorio styling
 */
export { default as Dropdown } from './ui/Dropdown.svelte';

/**
 * Label component for form fields
 */
export { default as Label } from './ui/Label.svelte';

/**
 * Status indicator bar showing application state
 */
export { default as StatusIndicator } from './ui/StatusIndicator.svelte';

/**
 * Visual preview display for AI provider and status
 */
export { default as StatusPreviewDisplay } from './ui/StatusPreviewDisplay.svelte';

// ============================================================================
// Layout Components
// ============================================================================

/**
 * Horizontal divider line
 */
export { default as HorizontalLine } from './layout/HorizontalLine.svelte';

/**
 * Flexbox row container with configurable spacing
 */
export { default as Row } from './layout/Row.svelte';

/**
 * Collapsible section with title
 */
export { default as Section } from './layout/Section.svelte';

/**
 * Custom title bar with window controls
 */
export { default as TitleBar } from './layout/TitleBar.svelte';

// ============================================================================
// Section Components (High-Level Features)
// ============================================================================

/**
 * Factorio path configuration section
 * Includes path input, browse, and auto-detect
 */
export { default as FactorioPathSection } from './sections/FactorioPathSection.svelte';

/**
 * AI provider and model configuration section
 * Includes provider dropdown, model selection, and API key input
 */
export { default as AIConfigSection } from './sections/AIConfigSection.svelte';

/**
 * Launch button section with status awareness
 */
export { default as LaunchSection } from './sections/LaunchSection.svelte';
