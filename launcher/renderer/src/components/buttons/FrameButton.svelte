<script lang="ts">
  import ButtonBase from "./ButtonBase.svelte";

  export let onClick: () => void = () => {};
  export let disabled: boolean = false;
  export let primary: boolean = false;
  export let fullWidth: boolean = false;
  export let selected: boolean = false;
  export let title: string | undefined = undefined;
</script>

<div style="position: relative; display: inline-block; width: 100%; height: 100%;">
  <div class="frame-button-shadow"></div>
  <ButtonBase
    {onClick}
    {disabled}
    {title}
    class="factorio-frame-button {primary ? 'primary' : ''} {fullWidth
      ? 'full-width'
      : ''} {selected ? 'selected' : ''}"
  >
    <slot></slot>
  </ButtonBase>
</div>
