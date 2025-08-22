<script lang="ts">
  export let gap: string = '10px';
  export let marginBottom: string = '5px';
  export let justify: string = 'flex-start';
</script>

<div class="factorio-row" style="gap: {gap}; margin-bottom: {marginBottom}; justify-content: {justify};">
  <slot></slot>
</div>

<style>
  .factorio-row {
    display: flex;
    align-items: center;
  }
</style>
