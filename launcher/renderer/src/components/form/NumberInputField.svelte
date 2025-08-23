<script lang="ts">
  import '../../styles/factorio-input-9slice.css';
  
  export let value: number;
  export let min: number | undefined = undefined;
  export let max: number | undefined = undefined;
  export let placeholder: string = '';
  export let onChange: () => void = () => {};
  export let fullWidth: boolean = true;
  export let disabled: boolean = false;
</script>

<input 
  type="number"
  class="factorio-input-9slice {fullWidth ? 'full-width' : ''}"
  {placeholder}
  {min}
  {max}
  bind:value
  on:change={onChange}
  {disabled}
/>

<style>
  .full-width {
    width: 100%;
  }
</style>
