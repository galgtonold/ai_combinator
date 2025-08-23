<script lang="ts">
  import { factorioService } from "../../stores";
  import { Button, InputField, Row, Section } from "../index.js";

  interface Props {
    factorioPath: string;
    onPathChange: () => Promise<void>;
  }

  let { factorioPath, onPathChange }: Props = $props();
</script>

<Section title="Factorio Executable">
  <Row>
    <InputField
      value={factorioPath}
      placeholder="Path to factorio.exe"
      onChange={onPathChange}
    />
    <Button onClick={() => factorioService.browseFactorioPath()}>Browse</Button>
    <Button onClick={() => factorioService.autoDetectFactorio()}>Auto</Button>
  </Row>
</Section>
