<script lang="ts">
  import type { Snippet } from 'svelte';
  import NormalButton from './NormalButton.svelte';
  
  interface Props {
    onClick?: () => void;
    disabled?: boolean;
    primary?: boolean;
    fullWidth?: boolean;
    selected?: boolean;
    children?: Snippet;
  }

  let { 
    onClick = () => {}, 
    disabled = false, 
    primary = false, 
    fullWidth = false, 
    selected = false,
    children
  }: Props = $props();
</script>

<!-- Simple wrapper around NormalButton for backward compatibility -->
<NormalButton
  {onClick}
  {disabled}
  {primary}
  {fullWidth}
  {selected}
>
  {@render children?.()}
</NormalButton>
