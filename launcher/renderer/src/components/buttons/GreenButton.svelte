<script lang="ts">
  import type { Snippet } from 'svelte';
  import ButtonBase from './ButtonBase.svelte';
  
  interface Props {
    onClick?: () => void;
    disabled?: boolean;
    primary?: boolean;
    fullWidth?: boolean;
    selected?: boolean;
    clicked?: boolean;
    children?: Snippet;
  }

  let { 
    onClick = () => {}, 
    disabled = false, 
    primary = false, 
    fullWidth = false, 
    selected = false, 
    clicked = false,
    children
  }: Props = $props();

  // Build class string
  const classString = $derived([
    'factorio-btn-base',
    'factorio-btn-green',
    primary ? 'primary' : '',
    fullWidth ? 'full-width' : '',
    selected ? 'selected' : '',
    clicked ? 'clicked' : '',
  ].filter(Boolean).join(' '));
</script>

<ButtonBase
  {onClick}
  {disabled}
  class={classString}
>
  {@render children?.()}
</ButtonBase>
