<script lang="ts">
  import outerFrameLight from '/graphics/outer_frame_light.png';
  import assemblingMachine from '/graphics/assembling-machine-1.png';
  import innerGlow from '/graphics/inner_glow.png';
  
  // Import all provider logos
  import openaiLogo from '/graphics/providers/openai.svg';
  import anthropicLogo from '/graphics/providers/anthropic.svg';
  import googleLogo from '/graphics/providers/google.svg';
  import deepseekLogo from '/graphics/providers/deepseek.svg';
  import xaiLogo from '/graphics/providers/xai.svg';

  export let aiProvider: string = "openai";
  export let status: "success" | "warning" | "error" = "warning";
  
  // Map provider names to imported logos
  const providerLogos: Record<string, string> = {
    openai: openaiLogo,
    anthropic: anthropicLogo,
    google: googleLogo,
    deepseek: deepseekLogo,
    xai: xaiLogo
  };
  
  $: currentProviderLogo = providerLogos[aiProvider] || openaiLogo;
</script>

<div 
  class="checkerboard-status-section"
  style="--outer-frame-image: url({outerFrameLight}); --assembling-machine-image: url({assemblingMachine}); --inner-glow-image: url({innerGlow});"
>
  <div class="checkerboard-pattern">
    <div class="assembling-machine" class:working={status === 'success'}>
      <div class="provider-logo-overlay" style="background-image: url({currentProviderLogo});"></div>
    </div>
    <div class="inner-glow-overlay"></div>
  </div>
</div>

<style>
  .checkerboard-status-section {
    width: 100%;
    height: 220px;
    margin: 4px 0;
    background-color: #414040;
    overflow: hidden;
    border: 5px solid transparent;
    border-image-source: var(--outer-frame-image);
    border-image-slice: 8 8 8 8 fill;
    border-image-width: 5px;
    border-image-repeat: stretch;
    border-image-outset: 0;
  }

  .checkerboard-pattern {
    width: 100%;
    height: 100%;
    background-image: 
      linear-gradient(to bottom, rgba(0,0,0,0.5) 0%, rgba(255, 255, 255, 0.1) 100%),
      linear-gradient(45deg, #555555 25%, transparent 25%),
      linear-gradient(-45deg, #555555 25%, transparent 25%),
      linear-gradient(45deg, transparent 75%, #555555 75%),
      linear-gradient(-45deg, transparent 75%, #555555 75%);
    background-size: 100% 100%, 80px 80px, 80px 80px, 80px 80px, 80px 80px;
    background-position: 0 0, 20px 30px, 20px 70px, 60px -10px, -20px 30px;
    background-color: #3a3a3a;
    opacity: 0.8;
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .assembling-machine {
    width: 108px;
    height: 114px;
    background-image: var(--assembling-machine-image);
    background-size: 864px 456px; /* 8 columns × 108px, 4 rows × 114px */
    z-index: 1;
    position: relative;
  }

  .assembling-machine.working {
    animation: assembling-machine-animation 1.2s step-start infinite;
  }

  @keyframes assembling-machine-animation {
    0%, 3.124% { background-position: 0 0; }
    3.125%, 6.249% { background-position: -108px 0; }
    6.25%, 9.374% { background-position: -216px 0; }
    9.375%, 12.499% { background-position: -324px 0; }
    12.5%, 15.624% { background-position: -432px 0; }
    15.625%, 18.749% { background-position: -540px 0; }
    18.75%, 21.874% { background-position: -648px 0; }
    21.875%, 24.999% { background-position: -756px 0; }
    25%, 28.124% { background-position: 0 -114px; }
    28.125%, 31.249% { background-position: -108px -114px; }
    31.25%, 34.374% { background-position: -216px -114px; }
    34.375%, 37.499% { background-position: -324px -114px; }
    37.5%, 40.624% { background-position: -432px -114px; }
    40.625%, 43.749% { background-position: -540px -114px; }
    43.75%, 46.874% { background-position: -648px -114px; }
    46.875%, 49.999% { background-position: -756px -114px; }
    50%, 53.124% { background-position: 0 -228px; }
    53.125%, 56.249% { background-position: -108px -228px; }
    56.25%, 59.374% { background-position: -216px -228px; }
    59.375%, 62.499% { background-position: -324px -228px; }
    62.5%, 65.624% { background-position: -432px -228px; }
    65.625%, 68.749% { background-position: -540px -228px; }
    68.75%, 71.874% { background-position: -648px -228px; }
    71.875%, 74.999% { background-position: -756px -228px; }
    75%, 78.124% { background-position: 0 -342px; }
    78.125%, 81.249% { background-position: -108px -342px; }
    81.25%, 84.374% { background-position: -216px -342px; }
    84.375%, 87.499% { background-position: -324px -342px; }
    87.5%, 90.624% { background-position: -432px -342px; }
    90.625%, 93.749% { background-position: -540px -342px; }
    93.75%, 96.874% { background-position: -648px -342px; }
    96.875%, 100% { background-position: -756px -342px; }
  }

  .provider-logo-overlay {
    position: absolute;
    top: calc(50% - 20px);
    left: 50%;
    transform: translate(-50%, -50%);
    width: 40px;
    height: 40px;
    background-size: contain;
    background-repeat: no-repeat;
    background-position: center;
    z-index: 2;
    opacity: 0.9;
    filter: drop-shadow(0px 0px 7px rgba(0, 0, 0, 1));
  }

  .inner-glow-overlay {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    border: 8px solid transparent;
    border-image-source: var(--inner-glow-image);
    border-image-slice: 8 8 8 8 fill;
    border-image-width: 5px;
    border-image-repeat: stretch;
    border-image-outset: 0;
    filter: brightness(0) opacity(1);
    pointer-events: none;
  }
</style>
