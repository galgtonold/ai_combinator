<script lang="ts">
  import NormalButton from './NormalButton.svelte';
  
  // Forward all props to NormalButton
  export let onClick: () => void = () => {};
  export let disabled: boolean = false;
  export let primary: boolean = false;
  export let fullWidth: boolean = false;
  export let loading: boolean = false;
  export let selected: boolean = false;
</script>

<!-- Use NormalButton for backward compatibility -->
<NormalButton
  {onClick}
  {disabled}
  {primary}
  {fullWidth}
  {loading}
  {selected}
>
  <slot></slot>
</NormalButton>

<style>
  /* Spinner styles have been moved to ButtonBase.svelte */
</style>
