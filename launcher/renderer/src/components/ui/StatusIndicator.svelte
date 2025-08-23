<script lang="ts">
  export let status: 'success' | 'warning' | 'error' = 'warning';
  export let text: string;
</script>

<div class="status-indicator">
  <img 
    src="/graphics/status_{status === 'success' ? 'green' : status === 'error' ? 'red' : 'yellow'}.png" 
    alt="{status}" 
    class="status-icon" 
  />
  <span class="status-text">{text}</span>
</div>

<style>
  /* Use completely different class names to avoid conflicts with global CSS */
  .status-indicator {
    display: flex;
    align-items: center;
    /* Reset any potential inherited styles */
    background: none;
    border: none;
    padding: 0;
    border-radius: 0;
  }

  .status-icon {
    width: 20px;
    height: 20px;
    margin-right: 5px;
    /* Reset any potential inherited styles */
    background: none;
    border-radius: 0;
  }
  
  .status-text {
    color: #fff;
    font-size: 17px;
    font-weight: 200;
    background: none;
    margin: 0;
    padding: 0;
    -webkit-text-stroke: 0.05px white;


  }
</style>
