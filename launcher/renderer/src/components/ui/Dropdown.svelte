
<script lang="ts">
  import NormalButton from '../buttons/NormalButton.svelte';
  import ListboxItemButton from '../buttons/ListboxItemButton.svelte';
  import '../../styles/factorio-dropdown.css';
  export let value: string;
  export let options: { value: string; label: string }[];
  export let onChange: (value: string) => void = () => {};
  export let width: string = '200px';
  let open = false;
  let dropdownRef: HTMLDivElement;

  function selectOption(val: string) {
    value = val;
    onChange(val);
    open = false;
  }

  function handleClickOutside(event: MouseEvent) {
    if (dropdownRef && !dropdownRef.contains(event.target as Node)) {
      open = false;
    }
  }

  $: if (open) {
    window.addEventListener('mousedown', handleClickOutside);
  } else {
    window.removeEventListener('mousedown', handleClickOutside);
  }
</script>

<div class="factorio-dropdown" bind:this={dropdownRef} style="width: {width};">
  <div class="factorio-dropdown-btn" on:click={() => open = !open}>
    <NormalButton clicked={open} size="medium" fullWidth={true}>
      <div style="display: flex; align-items: center; justify-content: space-between; width: 100%;">
        <span style="text-align: left;">{options.find(o => o.value === value)?.label ?? ''}</span>
        <img src="/graphics/dropdown.png" alt="▼" class="factorio-dropdown-arrow" draggable="false" />
      </div>
    </NormalButton>
  </div>
  {#if open}
    <div class="factorio-dropdown-list" style="width: {width};">
      {#each options as option}
        <div class="factorio-dropdown-item" style="padding:0;">
          <ListboxItemButton 
            clicked={option.value === value} 
            fullWidth={true}
            onClick={() => selectOption(option.value)}
          >
            {option.label}
          </ListboxItemButton>
        </div>
      {/each}
    </div>
  {/if}
</div>
