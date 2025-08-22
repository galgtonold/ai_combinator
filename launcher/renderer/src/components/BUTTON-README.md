# Factorio-Style Button Components

This directory contains button components styled to match the Factorio UI design language.

## Components

### ButtonBase.svelte
A base component that handles common button functionality like click events and sound effects.

### NormalButton.svelte
Standard button using the regular Factorio button styling.

### GreenButton.svelte
Green button using the green Factorio button styling for success actions or confirmations.

### LaunchButton.svelte
Launch button that uses GreenButton with appropriate sizing for the main launch action.

### FrameButton.svelte
Frame-style button using the frame_button styling.

### Button.svelte
Legacy component that uses NormalButton internally for backward compatibility.

## Usage

```svelte
<script>
  import { NormalButton, GreenButton, LaunchButton } from './components';
  
  function handleClick() {
    console.log('Button clicked!');
  }
</script>

<!-- Standard Button -->
<NormalButton onClick={handleClick} primary>
  Normal Button
</NormalButton>

<!-- Green Button -->
<GreenButton onClick={handleClick} size="large">
  Confirm Action
</GreenButton>

<!-- Launch Button -->
<LaunchButton onClick={handleClick} text="Launch Game" />
```

## Smart Variant System

The button system now uses a smart CSS variant approach with `factorio-button-variants.css` that eliminates code duplication. New button variants can be easily added by:

1. Adding CSS custom properties for the new variant
2. Creating a simple variant class that sets those properties
3. Creating a Svelte component that uses the base classes

## Props

All button components accept the following props:

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| onClick | function | () => {} | Function to call when button is clicked |
| disabled | boolean | false | Disables the button when true |
| primary | boolean | false | Makes the button more prominent |
| fullWidth | boolean | false | Makes the button take up full width of container |
| loading | boolean | false | Shows a loading spinner instead of content |
| selected | boolean | false | Renders the button in a selected state |
| size | 'small' \| 'medium' \| 'large' | 'medium' | Controls the button size |
| use9Slice | boolean | true | Uses 9-slice scaling for better quality |

## Image Requirements

For the buttons to display correctly, the following images are required in the `/graphics/` folder:

### Normal Button
- button.png - Normal state
- button_hovered.png - Hover/selected state
- button_clicked.png - Active/clicked state

### Green Button
- green_button.png - Normal state
- green_button_hovered.png - Hover/selected state
- green_button_clicked.png - Active/clicked state

### Frame Button
- frame_button.png - Normal state
- frame_button_selected.png - Hover/selected state
- frame_button_clicked.png - Active/clicked state

## Notes

- The new variant system is much more maintainable and uses ~75% less CSS code
- All buttons play a click sound when pressed, using the file at `/sounds/gui-click.ogg`
- Adding new button colors/styles is now trivial - just add the CSS variables and variant class
