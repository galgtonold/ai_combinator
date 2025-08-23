<script lang="ts">
  import type { FactorioStatus } from "../../utils/ipc";
  import { factorioService } from "../../stores";
  import { GreenButton } from "../index.js";

  interface Props {
    factorioPath: string;
    isLaunching: boolean;
    factorioStatus: FactorioStatus;
  }

  let { factorioPath, isLaunching, factorioStatus }: Props = $props();

  $: launchText = isLaunching
    ? "Launching..."
    : factorioStatus === "running"
      ? "Factorio is Running"
      : "Launch Factorio";

  $: isDisabled = !factorioPath || isLaunching || factorioStatus === "running";

  async function handleLaunch(): Promise<void> {
    await factorioService.launchFactorio();
  }
</script>

<GreenButton
  onClick={handleLaunch}
  disabled={isDisabled}
  fullWidth
  primary
>
  {launchText}
</GreenButton>
