<script lang="ts">
  export let size: 'small' | 'normal' = 'normal';
</script>

<label class="factorio-label {size === 'small' ? 'factorio-label-small' : ''}">
  <slot></slot>
</label>

<style>
  .factorio-label {
    color: #fff;
    display: block;
    font-size: 17px;
    font-weight: 500;
    margin-bottom: 8px;
  }

  .factorio-label-small {
    color: #fff;
    font-size: 17px;
    margin-right: 10px;
    align-self: center;
    margin-bottom: 0;
    font-weight: 200;
    -webkit-text-stroke: 0.05px white; /* Make font rendering difference to Factorio smaller */

  }
</style>
