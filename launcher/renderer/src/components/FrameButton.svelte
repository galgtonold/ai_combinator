<script lang="ts">
  import ButtonBase from './ButtonBase.svelte';
  
  // Re-export props from ButtonBase
  export let onClick: () => void = () => {};
  export let disabled: boolean = false;
  export let primary: boolean = false;
  export let fullWidth: boolean = false;
  export let loading: boolean = false;
  export let selected: boolean = false;
  export let size: 'small' | 'medium' | 'large' = 'medium';
  export let use9Slice: boolean = true; // Use the more accurate 9-slice implementation
</script>

{#if use9Slice}
  <div style="position: relative; display: inline-block; width: 100%; height: 100%;">
    <div class="frame-button-shadow-9slice"></div>
    <ButtonBase
      {onClick}
      {disabled}
      {loading}
      class="factorio-frame-button-9slice {primary ? 'primary' : ''} {fullWidth ? 'full-width' : ''} {size} {selected ? 'selected' : ''}"
    >
      <slot></slot>
    </ButtonBase>
  </div>
{:else}
  <ButtonBase
    {onClick}
    {disabled}
    {loading}
    class="factorio-frame-button {primary ? 'primary' : ''} {fullWidth ? 'full-width' : ''} {size} {selected ? 'selected' : ''}"
  >
    <slot></slot>
  </ButtonBase>
{/if}
