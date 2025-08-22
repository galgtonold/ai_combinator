<!-- 
  GreenButton Example Usage
  
  This file demonstrates how to use the GreenButton component
  with various props and configurations.
-->

<script lang="ts">
  import GreenButton from './GreenButton.svelte';
  
  // Example click handlers
  function handleStandardClick() {
    alert('Standard green button clicked!');
  }
  
  function handlePrimaryClick() {
    alert('Primary green button clicked!');
  }
  
  function handleLoadingClick() {
    alert('Loading green button clicked!');
  }
  
  // State variables for examples
  let isLoading = false;
  let isSelected = false;
  let isDisabled = false;
  
  function toggleLoading() {
    isLoading = !isLoading;
  }
  
  function toggleSelected() {
    isSelected = !isSelected;
  }
  
  function toggleDisabled() {
    isDisabled = !isDisabled;
  }
</script>

<div class="examples-container">
  <h2>GreenButton Examples</h2>
  
  <!-- Basic Examples -->
  <section>
    <h3>Basic Usage</h3>
    <div class="button-row">
      <GreenButton onClick={handleStandardClick}>
        Standard Green
      </GreenButton>
      
      <GreenButton onClick={handlePrimaryClick} primary>
        Primary Green
      </GreenButton>
    </div>
  </section>
  
  <!-- Size Variants -->
  <section>
    <h3>Size Variants</h3>
    <div class="button-row">
      <GreenButton onClick={handleStandardClick} size="small">
        Small
      </GreenButton>
      
      <GreenButton onClick={handleStandardClick} size="medium">
        Medium
      </GreenButton>
      
      <GreenButton onClick={handleStandardClick} size="large">
        Large
      </GreenButton>
    </div>
  </section>
  
  <!-- State Examples -->
  <section>
    <h3>States</h3>
    <div class="button-row">
      <GreenButton onClick={toggleLoading} loading={isLoading}>
        {isLoading ? 'Loading...' : 'Toggle Loading'}
      </GreenButton>
      
      <GreenButton onClick={toggleSelected} selected={isSelected}>
        {isSelected ? 'Selected' : 'Toggle Selected'}
      </GreenButton>
      
      <GreenButton onClick={toggleDisabled} disabled={isDisabled}>
        {isDisabled ? 'Disabled' : 'Toggle Disabled'}
      </GreenButton>
    </div>
  </section>
  
  <!-- Full Width Example -->
  <section>
    <h3>Full Width</h3>
    <GreenButton onClick={handleStandardClick} fullWidth>
      Full Width Green Button
    </GreenButton>
  </section>
  
  <!-- Implementation Toggle -->
  <section>
    <h3>9-Slice vs Sprite Implementation</h3>
    <div class="button-row">
      <GreenButton onClick={handleStandardClick} use9Slice={true}>
        9-Slice (Default)
      </GreenButton>
      
      <GreenButton onClick={handleStandardClick} use9Slice={false}>
        Sprite-based
      </GreenButton>
    </div>
  </section>
</div>

<style>
  .examples-container {
    padding: 20px;
    max-width: 800px;
    margin: 0 auto;
  }
  
  .button-row {
    display: flex;
    gap: 10px;
    margin: 10px 0;
    flex-wrap: wrap;
  }
  
  section {
    margin: 20px 0;
    padding: 10px;
    border: 1px solid #ccc;
    border-radius: 4px;
  }
  
  h2, h3 {
    color: #333;
    margin-bottom: 15px;
  }
</style>
