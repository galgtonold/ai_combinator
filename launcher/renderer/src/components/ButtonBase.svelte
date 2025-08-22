<script lang="ts">
  // Common props for all button types
  export let onClick: () => void = () => {};
  export let disabled: boolean = false;
  export let primary: boolean = false;
  export let fullWidth: boolean = false;
  export let loading: boolean = false;
  export let selected: boolean = false;
  export let clicked: boolean = false;
  export let size: 'small' | 'medium' | 'large' = 'medium';
  export let use9Slice: boolean = true; // Use the more accurate 9-slice implementation
  
  function handleClick(event: MouseEvent) {
    if (disabled) return;
    
    // Call the onClick handler
    onClick();
  }
</script>

<!-- Default slot for button content -->
<button 
  class="button-base {$$props.class || ''}"
  on:click={handleClick}
  {disabled}
>
  {#if loading}
    <div class="loading-spinner"></div>
  {:else}
    <slot></slot>
  {/if}
</button>

<style>
  /* Base button styles that will be inherited */
  :global(.button-base) {
    position: relative;
    font-family: 'Titillium Web', sans-serif;
    font-weight: 600;
    font-size: 14px;
    cursor: pointer;
    text-align: center;
    vertical-align: middle;
    box-sizing: border-box;
    background-color: transparent;
  }

  /* Loading spinner - similar to Factorio's loading animation */
  .loading-spinner {
    display: inline-block;
    width: 16px;
    height: 16px;
    border: 2px solid rgba(255, 255, 255, 0.3);
    border-radius: 50%;
    border-top-color: #fff;
    animation: factorio-spin 1s ease-in-out infinite;
    position: relative;
    vertical-align: middle;
  }
  
  @keyframes factorio-spin {
    to { transform: rotate(360deg); }
  }
</style>
