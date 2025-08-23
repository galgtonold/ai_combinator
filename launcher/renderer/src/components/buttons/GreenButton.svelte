<script lang="ts">
  import ButtonBase from './ButtonBase.svelte';
  
  // Re-export props from ButtonBase
  export let onClick: () => void = () => {};
  export let disabled: boolean = false;
  export let primary: boolean = false;
  export let fullWidth: boolean = false;
  export let selected: boolean = false;
  export let clicked: boolean = false;

  // Build class string
  $: classString = [
    'factorio-btn-base',
    'factorio-btn-green',
    primary ? 'primary' : '',
    fullWidth ? 'full-width' : '',
    selected ? 'selected' : '',
    clicked ? 'clicked' : '',
  ].filter(Boolean).join(' ');
</script>

<ButtonBase
  {onClick}
  {disabled}
  {clicked}
  class={classString}
>
  <slot></slot>
</ButtonBase>
