<!--
  Note: This component requires the following images in the /graphics/ folder:
  - frame_button.png
  - frame_button_selected.png
  - frame_button_clicked.png
-->
<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import FrameButton from '../buttons/FrameButton.svelte';
  import ipc from '../../utils/ipc';
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

  async function openWebsite() {
    await ipc.openExternal('https://github.com/galgtonold/ai_combinator');
  }

  async function openDiscord() {
    await ipc.openExternal('https://discord.gg/HYVuqC8kdP');
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
          onClick={openWebsite} 
          title="Open GitHub Repository"
        >
          <svg class="icon github-icon" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg">
            <path fill="currentColor" d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"/>
          </svg>
        </FrameButton>
        <FrameButton 
          onClick={openDiscord} 
          title="Join Discord Community"
        >
          <svg class="icon discord-icon" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg">
            <path fill="currentColor" d="M13.545 2.907a13.227 13.227 0 0 0-3.257-1.011.05.05 0 0 0-.052.025c-.141.25-.297.577-.406.833a12.19 12.19 0 0 0-3.658 0 8.258 8.258 0 0 0-.412-.833.051.051 0 0 0-.052-.025c-1.125.194-2.22.534-3.257 1.011a.041.041 0 0 0-.021.018C.356 6.024-.213 9.047.066 12.032c.001.014.01.028.021.037a13.276 13.276 0 0 0 3.995 2.02.05.05 0 0 0 .056-.019c.308-.42.582-.863.818-1.329a.05.05 0 0 0-.01-.059.051.051 0 0 0-.018-.011 8.875 8.875 0 0 1-1.248-.595.05.05 0 0 1-.02-.066.051.051 0 0 1 .015-.019c.084-.063.168-.129.248-.195a.05.05 0 0 1 .051-.007c2.619 1.196 5.454 1.196 8.041 0a.052.052 0 0 1 .053.007c.08.066.164.132.248.195a.051.051 0 0 1-.004.085 8.254 8.254 0 0 1-1.249.594.05.05 0 0 0-.03.03.052.052 0 0 0 .003.041c.24.465.515.909.817 1.329a.05.05 0 0 0 .056.019 13.235 13.235 0 0 0 4.001-2.02.049.049 0 0 0 .021-.037c.334-3.451-.559-6.449-2.366-9.106a.034.034 0 0 0-.02-.019Zm-8.198 7.307c-.789 0-1.438-.724-1.438-1.612 0-.889.637-1.613 1.438-1.613.807 0 1.45.73 1.438 1.613 0 .888-.637 1.612-1.438 1.612Zm5.316 0c-.788 0-1.438-.724-1.438-1.612 0-.889.637-1.613 1.438-1.613.807 0 1.451.73 1.438 1.613 0 .888-.631 1.612-1.438 1.612Z"/>
          </svg>
        </FrameButton>
        <div></div>
        <FrameButton 
          onClick={minimizeWindow} 
        >
          <span class="minimize-icon"></span>
        </FrameButton>
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

  .separator {
    width: 12px;
  }

  .icon {
    width: 18px;
    height: 18px;
    color: #ffe6c0;
    transition: color 0.2s ease;
  }

  .github-icon:hover {
    color: #ffffff;
  }

  .discord-icon:hover {
    color: #5865F2;
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
