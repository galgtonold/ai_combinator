<script lang="ts">
  import type { Snippet } from 'svelte';
  import ButtonBase from './ButtonBase.svelte';
  
  interface Props {
    onClick?: () => void;
    disabled?: boolean;
    primary?: boolean;
    fullWidth?: boolean;
    size?: 'small' | 'medium' | 'large';
    selected?: boolean;
    clicked?: boolean;
    children?: Snippet;
  }

  let { 
    onClick = () => {}, 
    disabled = false, 
    primary = false, 
    fullWidth = false, 
    size = 'medium',
    selected = false, 
    clicked = false,
    children
  }: Props = $props();

  // Build class string
  const classString = $derived([
    'factorio-btn-base',
    'factorio-btn-normal',
    primary ? 'primary' : '',
    fullWidth ? 'full-width' : '',
    selected ? 'selected' : '',
    clicked ? 'clicked' : '',
    size ? `size-${size}` : '',
  ].filter(Boolean).join(' '));
</script>

<ButtonBase
  {onClick}
  {disabled}
  class={classString}
>
  {@render children?.()}
</ButtonBase>
