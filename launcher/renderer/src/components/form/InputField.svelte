<script lang="ts">
  import '../../styles/factorio-input-9slice.css';
  
  interface Props {
    value: string;
    placeholder?: string;
    type?: string;
    onChange?: () => void;
    fullWidth?: boolean;
    disabled?: boolean;
  }

  let { 
    value = $bindable(),
    placeholder = '',
    type = 'text',
    onChange = () => {},
    fullWidth = true,
    disabled = false
  }: Props = $props();
</script>

<input 
  {type}
  class="factorio-input-9slice {fullWidth ? 'full-width' : ''}"
  {placeholder}
  bind:value
  onchange={onChange}
  {disabled}
/>

<style>
  .full-width {
    width: 100%;
  }
</style>
