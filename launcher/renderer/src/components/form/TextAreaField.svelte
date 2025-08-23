<script lang="ts">
  import '../../styles/factorio-input-9slice.css';
  
  export let value: string;
  export let placeholder: string = '';
  export let onChange: () => void = () => {};
  export let fullWidth: boolean = true;
  export let disabled: boolean = false;
  export let rows: number = 4;
</script>

<textarea 
  class="factorio-input-9slice factorio-textarea-9slice {fullWidth ? 'full-width' : ''}"
  {placeholder}
  bind:value
  on:change={onChange}
  {disabled}
  {rows}
></textarea>

<style>
  .full-width {
    width: 100%;
  }
</style>
