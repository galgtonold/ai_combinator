<script lang="ts">
  import '../../styles/factorio-input-9slice.css';
  
  export let value: string;
  export let placeholder: string = '';
  export let type: string = 'text';
  export let onChange: () => void = () => {};
  export let fullWidth: boolean = true;
  export let disabled: boolean = false;
</script>

<input 
  {type}
  class="factorio-input-9slice {fullWidth ? 'full-width' : ''}"
  {placeholder}
  bind:value
  on:change={onChange}
  {disabled}
/>

<style>
  .full-width {
    width: 100%;
  }
</style>
