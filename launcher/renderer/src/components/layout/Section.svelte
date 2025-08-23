<script lang="ts">
  export let title: string;
</script>

<div class="factorio-section">
  <div class="section-header">{title}</div>
  <slot></slot>
</div>

<style>
  .factorio-section {
    margin-bottom: 0px;
  }

  .section-header {
    color: rgb(255, 230, 192);
    font-size: 17px;
    font-weight: 600;
    letter-spacing: 0.01em;
    margin-bottom: 5px;
    padding-bottom: 5px;
  }
</style>
