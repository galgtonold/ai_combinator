<script lang="ts">
  import ButtonBase from './ButtonBase.svelte';
  
  // Re-export props from ButtonBase
  export let onClick: () => void = () => {};
  export let disabled: boolean = false;
  export let primary: boolean = false;
  export let fullWidth: boolean = false;
  export let loading: boolean = false;
  export let selected: boolean = false;
  export let clicked: boolean = false;
  export let size: 'small' | 'medium' | 'large' = 'medium';
  export let use9Slice: boolean = true;

  // Build class string
  $: classString = [
    'factorio-btn-base',
    'factorio-btn-normal',
    use9Slice ? 'use-9slice' : '',
    primary ? 'primary' : '',
    fullWidth ? 'full-width' : '',
    selected ? 'selected' : '',
    clicked ? 'clicked' : '',
    size
  ].filter(Boolean).join(' ');
</script>

<ButtonBase
  {onClick}
  {disabled}
  {loading}
  {clicked}
  class={classString}
>
  <slot></slot>
</ButtonBase>
