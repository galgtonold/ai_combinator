<script lang="ts">
  import '../../styles/factorio-input-9slice.css';
  import textboxImage from '/graphics/textbox.png';
  import textboxActiveImage from '/graphics/textbox_active.png';
  import textboxDisabledImage from '/graphics/textbox_disabled.png';
  
  export let value: string;
  export let placeholder: string = '';
  export let onChange: () => void = () => {};
  export let disabled: boolean = false;
  export let width: string = '100%';
  
  let showKey: boolean = false;

  function toggleVisibility() {
    showKey = !showKey;
  }
</script>

<div class="key-field" style="width: {width};">
  <div 
    class="input-container" 
    class:disabled
    style="--textbox-image: url({textboxImage}); --textbox-active-image: url({textboxActiveImage}); --textbox-disabled-image: url({textboxDisabledImage});"
  >
    <input 
      type={showKey ? "text" : "password"}
      class="password-input"
      {placeholder}
      bind:value
      on:change={onChange}
      {disabled}
    />
    <button class="key-toggle" on:click={toggleVisibility} disabled={disabled} aria-label={showKey ? "Hide password" : "Show password"}>
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        {#if showKey}
          <!-- Eye with slash (hidden) -->
          <path d="M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          <path d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          <path d="M3 3l18 18" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
        {:else}
          <!-- Eye (visible) -->
          <path d="M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          <path d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
        {/if}
      </svg>
    </button>
  </div>
</div>

<style>
  .key-field {
    position: relative;
    display: inline-block;
  }

  .input-container {
    position: relative;
    background-color: transparent;
    display: flex;
    align-items: center;
    
    /* Apply the 9-slice border to the container instead of the input */
    border: 4px solid transparent;
    border-image-source: var(--textbox-image);
    border-image-slice: 8 8 8 8 fill;
    border-image-width: 5px;
    border-image-repeat: stretch;
    border-image-outset: 0;
    
    min-width: 180px;
    min-height: 28px;
    box-sizing: border-box;
  }

  .input-container:focus-within {
    border-image-source: var(--textbox-active-image);
    border-image-slice: 8 8 8 8 fill;
    transition: all 0.1s ease-in-out;
  }

  .input-container.disabled {
    border-image-source: var(--textbox-disabled-image);
    border-image-slice: 8 8 8 8 fill;
    opacity: 0.9;
  }

  .password-input {
    background: transparent;
    border: none;
    outline: none;
    padding: 4px 8px;
    color: black;
    font-family: 'Titillium Web', sans-serif;
    font-weight: 400;
    font-size: 16px;
    box-sizing: border-box;
    overflow: hidden;
    white-space: nowrap;
    /* Calculate width: container width minus button width and padding */
    width: calc(100% - 40px); /* 32px for button + 8px padding */
  }

  .password-input::placeholder {
    color: rgba(0, 0, 0, 0.5);
    font-style: italic;
  }

  .password-input:disabled {
    color: rgba(0, 0, 0, 0.6);
    cursor: not-allowed;
  }

  .key-toggle {
    position: absolute;
    right: 8px;
    top: 50%;
    transform: translateY(-50%);
    background: none;
    border: none;
    padding: 4px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    color: rgba(0, 0, 0, 0.6);
    transition: color 0.2s ease;
    border-radius: 2px;
    height: 24px;
    width: 24px;
    z-index: 1;
  }
  
  .key-toggle:hover:not(:disabled) {
    color: rgba(0, 0, 0, 0.8);
    background-color: rgba(0, 0, 0, 0.05);
  }
  
  .key-toggle:active:not(:disabled) {
    color: rgba(0, 0, 0, 0.9);
    background-color: rgba(0, 0, 0, 0.1);
  }
  
  .key-toggle:disabled {
    color: rgba(0, 0, 0, 0.3);
    cursor: not-allowed;
    opacity: 0.5;
  }

  .key-toggle svg {
    width: 16px;
    height: 16px;
  }
</style>
