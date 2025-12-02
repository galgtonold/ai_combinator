<script lang="ts">
  import NormalButton from '../buttons/NormalButton.svelte';
  import ListboxItemButton from '../buttons/ListboxItemButton.svelte';
  import '../../styles/factorio-dropdown.css';
  import dropdownArrow from '/graphics/dropdown.png';
  
  interface Option {
    value: string;
    label: string;
  }

  interface Props {
    value: string;
    options: Option[];
    onChange?: (value: string) => void;
    width?: string;
  }

  let { 
    value, 
    options, 
    onChange = () => {}, 
    width = '200px' 
  }: Props = $props();

  let open = $state(false);
  let dropdownRef: HTMLDivElement | undefined = $state();

  function selectOption(val: string): void {
    value = val;
    onChange(val);
    open = false;
  }

  function handleClickOutside(event: MouseEvent): void {
    if (dropdownRef && !dropdownRef.contains(event.target as Node)) {
      open = false;
    }
  }

  function toggleDropdown(): void {
    open = !open;
  }

  $effect(() => {
    if (open) {
      window.addEventListener('mousedown', handleClickOutside);
    } else {
      window.removeEventListener('mousedown', handleClickOutside);
    }
    return () => {
      window.removeEventListener('mousedown', handleClickOutside);
    };
  });

  const selectedLabel = $derived(options.find(o => o.value === value)?.label ?? '');
</script>

<div class="factorio-dropdown" bind:this={dropdownRef} style="width: {width};">
  <!-- svelte-ignore a11y_click_events_have_key_events -->
  <!-- svelte-ignore a11y_no_static_element_interactions -->
  <div class="factorio-dropdown-btn" onclick={toggleDropdown}>
    <NormalButton clicked={open} size="medium" fullWidth={true}>
      <div style="display: flex; align-items: center; justify-content: space-between; width: 100%;">
        <span style="text-align: left;">{selectedLabel}</span>
        <img src={dropdownArrow} alt="▼" class="factorio-dropdown-arrow" draggable="false" />
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
