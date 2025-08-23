<script lang="ts">
  import ButtonBase from './ButtonBase.svelte';
  
  // Re-export props from ButtonBase
  export let onClick: () => void = () => {};
  export let disabled: boolean = false;
  export let selected: boolean = false;
  export let clicked: boolean = false;
  export let fullWidth: boolean = false;
  export let loading: boolean = false;
  
  $: classString = [
    'factorio-listbox-item',
    selected ? 'selected' : '',
    clicked ? 'clicked' : '',
    fullWidth ? 'full-width' : ''
  ].filter(Boolean).join(' ');
</script>

<ButtonBase
  {onClick}
  {disabled}
  {loading}
  class={classString}
>
  <slot></slot>
</ButtonBase>

<style>
  /* Component-specific overrides if needed */
</style>
