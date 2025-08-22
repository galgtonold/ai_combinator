<script lang="ts">
  import GreenButton from './GreenButton.svelte';
  
  export let onClick: () => void = () => {};
  export let disabled: boolean = false;
  export let text: string = "Launch Factorio";
  export const loading: boolean = false;
</script>

<GreenButton 
  {onClick}
  {disabled}
  size="large"
  fullWidth
  primary
>
  {text}
</GreenButton>
