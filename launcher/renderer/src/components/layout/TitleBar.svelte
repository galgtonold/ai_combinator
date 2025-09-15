<!--
  Note: This component requires the following images in the /graphics/ folder:
  - frame_button.png
  - frame_button_selected.png
  - frame_button_clicked.png
-->
<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import FrameButton from '../buttons/FrameButton.svelte';
  import draggableSpaceTop from '/graphics/draggable_space_top.png';
  import draggableSpaceCenter from '/graphics/draggable_space_center.png';
  import draggableSpaceBottom from '/graphics/draggable_space_bottom.png';

  const dispatch = createEventDispatcher();

  function minimizeWindow() {
    dispatch('minimize');
  }
  
  function closeWindow() {
    dispatch('close');
  }
</script>

<div class="title-bar">
  <div class="title-bar-inner">
    <div class="title-bar-text">AI Combinator Launcher</div>
    <div class="title-bar-draggable">
      <div 
        class="title-bar-background"
        style="--draggable-space-top: url({draggableSpaceTop}); --draggable-space-center: url({draggableSpaceCenter}); --draggable-space-bottom: url({draggableSpaceBottom});"
      >
        <div class="title-bar-top"></div>
        <div class="title-bar-center"></div>
        <div class="title-bar-bottom"></div>
      </div>
    </div>
    <div class="title-bar-controls">
      <div class="title-bar-buttons">
        <FrameButton 
          onClick={minimizeWindow} 
        >
          <span class="minimize-icon"></span>
        </FrameButton>
        <div></div>
        <FrameButton 
          onClick={closeWindow} 
        >
          <span class="close-icon"></span>
        </FrameButton>
      </div>
    </div>
  </div>
</div>

<style>
  .title-bar {
    position: relative;
    width: 100%;
    height: 48px; /* Increased height */
    -webkit-app-region: drag;
    box-sizing: border-box;
    padding: 0;
  }
  
  .title-bar-inner {
    display: flex;
    align-items: center;
    justify-content: space-between;
    height: 100%;
    width: 100%;
    padding: 6px 0; /* Add padding to the inner container */
  }
  
  .title-bar-text {
    font-size: 22px; /* Increased font size */
    color: #ffe6c0; /* New heading color */
    font-weight: 600;
    padding: 0 15px 0 15px;
  }
  
  .title-bar-draggable {
    position: relative;
    flex-grow: 1;
    height: calc(100% - 6px); /* Reduced height to add padding top and bottom */
    overflow: visible;
  }
  
  .title-bar-background {
    position: absolute;
    padding-top: 1px;
    padding-bottom: 3px;
    padding-right: 4px;
    width: 100%;
    height: 100%; /* Match the container height */
    display: flex;
    flex-direction: column;
  }
  
  .title-bar-top {
    background-image: var(--draggable-space-top);
    background-repeat: repeat-x;
    background-size: auto 5px; /* Half the original height */
    height: 4px; /* Half the original height */
    margin-top: 0px; /* Add space at the top */
  }
  
  .title-bar-center {
    background-image: var(--draggable-space-center);
    background-repeat: repeat;
    background-size: auto 5px; /* Half the original width and height */
    flex-grow: 1;
  }
  
  .title-bar-bottom {
    background-image: var(--draggable-space-bottom);
    background-repeat: repeat-x;
    background-size: auto 5px; /* Half the original height */
    height: 4px; /* Half the original height */
    margin-bottom: 0px; /* Add space at the bottom */
  }
  
  .title-bar-controls {
    display: flex;
    align-items: center;
    -webkit-app-region: no-drag;
    padding-right: 8px;
  }
  
  .title-bar-buttons {
    display: flex;
    gap: 6px;
    padding-left: 8px;
    padding-right: 8px;
  }
  
  /* Other styles are imported globally from titlebar.css */
  
  /* Styles for the frame buttons in title bar */
  :global(.title-bar-frame-button) {
    width: 36px !important;
    height: 36px !important;
    min-width: 36px !important;
    min-height: 36px !important;
    max-width: 36px !important;
    max-height: 36px !important;
    padding: 0 !important;
    display: flex !important;
    align-items: center !important;
    justify-content: center !important;
    border-radius: 0 !important;
  }
  
  :global(.title-bar-frame-button.close:hover) {
    filter: none !important;
    background-color: var(--factorio-red);
  }
</style>
