<script lang="ts">
  import type { Snippet } from 'svelte';

  interface Props {
    onClick?: () => void;
    disabled?: boolean;
    title?: string;
    class?: string;
    children?: Snippet;
  }

  let { 
    onClick = () => {}, 
    disabled = false, 
    title = undefined,
    class: className = '',
    children
  }: Props = $props();
  
  function handleClick(): void {
    if (disabled) return;
    onClick();
  }
</script>

<!-- Default slot for button content -->
<button 
  class="button-base {className}"
  onclick={handleClick}
  {disabled}
  {title}
>
  {@render children?.()}
</button>

<style>
  /* Base button styles that will be inherited */
  :global(.button-base) {
    position: relative;
    font-family: 'Titillium Web', sans-serif;
    font-weight: 600;
    font-size: 18px;
    cursor: pointer;
    text-align: center;
    vertical-align: middle;
    box-sizing: border-box;
    background-color: transparent;
  }
</style>
