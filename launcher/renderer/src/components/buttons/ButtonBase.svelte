<script lang="ts">
  // Common props for all button types
  export let onClick: () => void = () => {};
  export let disabled: boolean = false;
  
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
    <slot></slot>
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
