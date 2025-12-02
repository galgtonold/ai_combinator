<script lang="ts">
  import type { Snippet } from 'svelte';
  import ButtonBase from './ButtonBase.svelte';
  
  interface Props {
    onClick?: () => void;
    disabled?: boolean;
    selected?: boolean;
    clicked?: boolean;
    fullWidth?: boolean;
    children?: Snippet;
  }

  let { 
    onClick = () => {}, 
    disabled = false, 
    selected = false, 
    clicked = false, 
    fullWidth = false,
    children
  }: Props = $props();
  
  const classString = $derived([
    'factorio-listbox-item',
    selected ? 'selected' : '',
    clicked ? 'clicked' : '',
    fullWidth ? 'full-width' : ''
  ].filter(Boolean).join(' '));
</script>

<ButtonBase
  {onClick}
  {disabled}
  class={classString}
>
  {@render children?.()}
</ButtonBase>

<style>
  /* Component-specific overrides if needed */
</style>
