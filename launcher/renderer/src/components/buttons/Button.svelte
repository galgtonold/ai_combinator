<script lang="ts">
  import NormalButton from './NormalButton.svelte';
  
  export let onClick: () => void = () => {};
  export let disabled: boolean = false;
  export let primary: boolean = false;
  export let fullWidth: boolean = false;
  export let selected: boolean = false;
</script>

<NormalButton
  {onClick}
  {disabled}
  {primary}
  {fullWidth}
  {selected}
>
  <slot></slot>
</NormalButton>

<style>
</style>
